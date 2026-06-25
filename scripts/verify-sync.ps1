[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [int]$TimeoutSeconds = 180,
    [switch]$RunEventProbe,
    [switch]$RunRemotePullProbe
)

$ErrorActionPreference = "Stop"
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path
if (-not $GitExe) {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $command) { throw "Git executable was not found." }
    $GitExe = $command.Source
}
$GitExe = (Resolve-Path -LiteralPath $GitExe).Path

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $output = & $GitExe -C $VaultPath @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join ' ')" }
    return $output
}

function Invoke-GitCommand {
    param(
        [string]$RepositoryPath,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    try {
        $output = & $GitExe -C $RepositoryPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join ' ')" }
    return $output
}

function Get-RemoteHash {
    $output = @(& $GitExe -C $VaultPath ls-remote $Remote "refs/heads/$Branch" 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -or $output.Count -eq 0) {
        throw "Unable to read remote branch hash: $($output -join ' ')"
    }
    return (([string]$output[0]).Trim() -split '\s+')[0]
}

function Wait-ForSync {
    param([string]$PreviousHash)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Seconds 2
        $localHash = (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
        $remoteHash = Get-RemoteHash
        $status = @(Invoke-Git status --porcelain --untracked-files=all)
        if ($localHash -ne $PreviousHash -and $localHash -eq $remoteHash -and $status.Count -eq 0) {
            return $localHash
        }
    } while ((Get-Date) -lt $deadline)
    throw "Synchronization did not complete within $TimeoutSeconds seconds."
}

function Wait-ForLocalHash {
    param([string]$ExpectedHash)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Seconds 2
        $localHash = (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
        $status = @(Invoke-Git status --porcelain --untracked-files=all)
        if ($localHash -eq $ExpectedHash -and $status.Count -eq 0) { return $localHash }
    } while ((Get-Date) -lt $deadline)
    throw "The local vault did not receive remote hash $ExpectedHash within $TimeoutSeconds seconds."
}

function Wait-ForLocalCommit {
    param([string]$ExpectedHash)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Seconds 2
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        try {
            & $GitExe -C $VaultPath merge-base --is-ancestor $ExpectedHash HEAD 2>$null | Out-Null
            $mergeBaseExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($mergeBaseExitCode -eq 0) {
            return (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
        }
    } while ((Get-Date) -lt $deadline)
    throw "The local vault did not receive remote commit $ExpectedHash within $TimeoutSeconds seconds."
}

$remoteUrl = (Invoke-Git remote get-url $Remote | Select-Object -First 1).Trim()
$branchName = (Invoke-Git branch --show-current | Select-Object -First 1).Trim()
$localHash = (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
$remoteHash = Get-RemoteHash
$status = @(Invoke-Git status --porcelain --untracked-files=all)
$tasks = @(Get-ScheduledTask -TaskName "Obsidian Git Event Sync *" -ErrorAction SilentlyContinue)
$watchdogTasks = @(Get-ScheduledTask -TaskName "Obsidian Git Sync Watchdog *" -ErrorAction SilentlyContinue)
$expectedWatcherPath = Join-Path (Join-Path $env:LOCALAPPDATA "ObsidianGitSync") "watch-vault.ps1"
$watcherProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and
    $_.CommandLine -like "*-File*$expectedWatcherPath*" -and
    $_.CommandLine -like "*$VaultPath*"
})

$visibility = "unknown"
$gh = Get-Command gh.exe -ErrorAction SilentlyContinue
if (-not $gh) { $gh = Get-Command gh -ErrorAction SilentlyContinue }
if ($gh -and $remoteUrl -match 'github\.com[/:]([^/]+)/([^/]+)$') {
    $repoName = $Matches[2] -replace '\.git$', ''
    $repo = "$($Matches[1])/$repoName"
    $visibilityResult = & $gh.Source repo view $repo --json visibility --jq .visibility 2>$null
    if ($LASTEXITCODE -eq 0) { $visibility = $visibilityResult.Trim() }
}

$probe = $null
if ($RunEventProbe) {
    if ($status.Count -ne 0) { throw "Worktree must be clean before running an event probe." }
    $probeName = ".obsidian-sync-probe-$([guid]::NewGuid().ToString('N')).md"
    $probePath = Join-Path $VaultPath $probeName
    $beforeCreate = $localHash
    [IO.File]::WriteAllText($probePath, "Obsidian synchronization probe $(Get-Date -Format o)`r`n", [Text.UTF8Encoding]::new($false))
    $createdHash = Wait-ForSync -PreviousHash $beforeCreate
    Remove-Item -LiteralPath $probePath -Force
    $deletedHash = Wait-ForSync -PreviousHash $createdHash
    $probe = [pscustomobject]@{ createHash = $createdHash; deleteHash = $deletedHash }
    $localHash = $deletedHash
    $remoteHash = Get-RemoteHash
    $status = @(Invoke-Git status --porcelain --untracked-files=all)
}

$remotePullProbe = $null
if ($RunRemotePullProbe) {
    if ($status.Count -ne 0) { throw "Worktree must be clean before running a remote pull probe." }
    $probeRoot = Join-Path $env:TEMP "ObsidianSyncRemoteProbe-$([guid]::NewGuid().ToString('N'))"
    $probeName = ".obsidian-remote-probe-$([guid]::NewGuid().ToString('N')).md"
    try {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        try {
            $cloneOutput = & $GitExe clone --quiet --branch $Branch --single-branch $remoteUrl $probeRoot 2>&1
            $cloneExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($cloneExitCode -ne 0) { throw "Unable to create the remote pull probe clone: $($cloneOutput -join ' ')" }
        $name = (Invoke-Git config user.name | Select-Object -First 1).Trim()
        $email = (Invoke-Git config user.email | Select-Object -First 1).Trim()
        Invoke-GitCommand -RepositoryPath $probeRoot config user.name $name | Out-Null
        Invoke-GitCommand -RepositoryPath $probeRoot config user.email $email | Out-Null
        [IO.File]::WriteAllText((Join-Path $probeRoot $probeName), "Remote pull probe $(Get-Date -Format o)`r`n", [Text.UTF8Encoding]::new($false))
        Invoke-GitCommand -RepositoryPath $probeRoot add --all | Out-Null
        Invoke-GitCommand -RepositoryPath $probeRoot commit --quiet -m "Add remote pull probe" | Out-Null
        Invoke-GitCommand -RepositoryPath $probeRoot push --quiet $Remote $Branch | Out-Null
        $createdHash = ((& $GitExe -C $probeRoot rev-parse HEAD) -join "").Trim()
        $receivedHash = Wait-ForLocalCommit -ExpectedHash $createdHash

        $localProbePath = Join-Path $VaultPath $probeName
        if (Test-Path -LiteralPath $localProbePath) {
            Remove-Item -LiteralPath $localProbePath -Force
            Invoke-GitCommand -RepositoryPath $VaultPath add -- $probeName | Out-Null
            & $GitExe -C $VaultPath diff --cached --quiet
            if ($LASTEXITCODE -ne 0) {
                Invoke-GitCommand -RepositoryPath $VaultPath commit --quiet -m "Remove remote pull probe" | Out-Null
            }
        }
        Invoke-GitCommand -RepositoryPath $VaultPath pull --rebase $Remote $Branch | Out-Null
        Invoke-GitCommand -RepositoryPath $VaultPath push --quiet $Remote $Branch | Out-Null
        $deletedHash = (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
        $remotePullProbe = [pscustomobject]@{ createHash = $createdHash; receivedHash = $receivedHash; cleanupHash = $deletedHash }
        $localHash = $deletedHash
        $remoteHash = Get-RemoteHash
        $status = @(Invoke-Git status --porcelain --untracked-files=all)
    } finally {
        if (Test-Path -LiteralPath $probeRoot) { Remove-Item -LiteralPath $probeRoot -Recurse -Force }
    }
}

$result = [pscustomobject]@{
    vaultPath = $VaultPath
    remoteUrl = $remoteUrl
    branch = $branchName
    expectedBranch = $Branch
    visibility = $visibility
    worktreeClean = ($status.Count -eq 0)
    hashesMatch = ($localHash -eq $remoteHash)
    localHash = $localHash
    remoteHash = $remoteHash
    watcherTasks = @($tasks | ForEach-Object { [pscustomobject]@{ name = $_.TaskName; state = $_.State.ToString() } })
    watchdogTasks = @($watchdogTasks | ForEach-Object { [pscustomobject]@{ name = $_.TaskName; state = $_.State.ToString() } })
    watcherProcesses = @($watcherProcesses | ForEach-Object { [pscustomobject]@{ processId = $_.ProcessId; name = $_.Name } })
    eventProbe = $probe
    remotePullProbe = $remotePullProbe
}

$result | ConvertTo-Json -Depth 5
if (-not $result.worktreeClean -or -not $result.hashesMatch -or $branchName -ne $Branch -or $visibility -eq "PUBLIC") {
    exit 1
}
