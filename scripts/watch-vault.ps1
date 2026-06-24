[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [int]$DebounceSeconds = 60,
    [int]$PullIntervalSeconds = 60,
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [string]$LogPath = ""
)

$ErrorActionPreference = "Continue"
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path

if (-not $GitExe) {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $command) { throw "Git executable was not found." }
    $GitExe = $command.Source
}
$GitExe = (Resolve-Path -LiteralPath $GitExe).Path

if (-not (Test-Path -LiteralPath (Join-Path $VaultPath ".git"))) {
    throw "Vault is not a Git repository: $VaultPath"
}

if (-not $LogPath) {
    $LogPath = Join-Path $env:LOCALAPPDATA "ObsidianGitSync\sync.log"
}
$logDirectory = Split-Path -Parent $LogPath
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($VaultPath.ToLowerInvariant()))
$vaultHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Local\ObsidianGitSync-$vaultHash", ([ref]$createdNew))
if (-not $createdNew) { exit 0 }

function Write-SyncLog {
    param([string]$Message)
    if ((Test-Path -LiteralPath $LogPath) -and (Get-Item -LiteralPath $LogPath).Length -gt 2097152) {
        Get-Content -LiteralPath $LogPath -Tail 500 | Set-Content -LiteralPath "$LogPath.tmp" -Encoding UTF8
        Move-Item -LiteralPath "$LogPath.tmp" -Destination $LogPath -Force
    }
    Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -Encoding UTF8
}

function Get-WorktreeStatus {
    return @(& $GitExe -C $VaultPath status --porcelain --untracked-files=all 2>&1)
}

function Invoke-CleanPull {
    $status = Get-WorktreeStatus
    if ($LASTEXITCODE -ne 0 -or $status.Count -gt 0) { return }
    & $GitExe -C $VaultPath fetch $Remote $Branch 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -ne 0) { Write-SyncLog "clean fetch failed"; return }
    & $GitExe -C $VaultPath merge --ff-only "$Remote/$Branch" 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -ne 0) { Write-SyncLog "clean fast-forward failed" }
}

function Invoke-VaultSync {
    $status = Get-WorktreeStatus
    if ($LASTEXITCODE -ne 0) {
        Write-SyncLog "status failed: $($status -join ' ')"
        return
    }
    if ($status.Count -eq 0) { return }

    & $GitExe -C $VaultPath add --all 2>&1 | ForEach-Object { Write-SyncLog $_ }
    & $GitExe -C $VaultPath diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { return }

    $message = "vault backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    & $GitExe -C $VaultPath commit -m $message 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -ne 0) { Write-SyncLog "commit failed"; return }

    & $GitExe -C $VaultPath fetch $Remote $Branch 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -ne 0) { Write-SyncLog "fetch failed; push skipped"; return }
    & $GitExe -C $VaultPath rebase "$Remote/$Branch" 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -ne 0) { Write-SyncLog "rebase failed; push skipped"; return }

    & $GitExe -C $VaultPath push $Remote $Branch 2>&1 | ForEach-Object { Write-SyncLog $_ }
    if ($LASTEXITCODE -eq 0) { Write-SyncLog "sync complete" } else { Write-SyncLog "push failed" }
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $VaultPath
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, DirectoryName, LastWrite, Size'
$watcher.EnableRaisingEvents = $true
$sourcePrefix = "ObsidianGitSync.$vaultHash"
$subscriptions = @(
    Register-ObjectEvent $watcher Changed -SourceIdentifier "$sourcePrefix.Changed"
    Register-ObjectEvent $watcher Created -SourceIdentifier "$sourcePrefix.Created"
    Register-ObjectEvent $watcher Deleted -SourceIdentifier "$sourcePrefix.Deleted"
    Register-ObjectEvent $watcher Renamed -SourceIdentifier "$sourcePrefix.Renamed"
)

Write-SyncLog "watcher started for $VaultPath"
$initialStatus = Get-WorktreeStatus
$pending = ($LASTEXITCODE -eq 0 -and $initialStatus.Count -gt 0)
$lastChange = if ($pending) { [DateTime]::UtcNow } else { [DateTime]::MinValue }
$lastPull = [DateTime]::UtcNow.AddSeconds(-$PullIntervalSeconds)

try {
    while ($true) {
        $firstEvent = Wait-Event -Timeout 1
        $events = @()
        if ($firstEvent) { $events += $firstEvent }
        $events += @(Get-Event | Where-Object { $_.SourceIdentifier -like "$sourcePrefix.*" })
        foreach ($event in ($events | Sort-Object EventIdentifier -Unique)) {
            $fullPath = $event.SourceEventArgs.FullPath
            Remove-Event -EventIdentifier $event.EventIdentifier -ErrorAction SilentlyContinue
            if ($fullPath -and $fullPath -notmatch '[\\/]\.git([\\/]|$)') {
                $pending = $true
                $lastChange = [DateTime]::UtcNow
            }
        }

        if ($pending -and ([DateTime]::UtcNow - $lastChange).TotalSeconds -ge $DebounceSeconds) {
            $pending = $false
            Invoke-VaultSync
        }

        if ($PullIntervalSeconds -gt 0 -and ([DateTime]::UtcNow - $lastPull).TotalSeconds -ge $PullIntervalSeconds) {
            $lastPull = [DateTime]::UtcNow
            Invoke-CleanPull
        }
    }
} finally {
    foreach ($subscription in $subscriptions) {
        Unregister-Event -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
    }
    $watcher.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
