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

$remoteUrl = (Invoke-Git remote get-url $Remote | Select-Object -First 1).Trim()
$branchName = (Invoke-Git branch --show-current | Select-Object -First 1).Trim()
$localHash = (Invoke-Git rev-parse HEAD | Select-Object -First 1).Trim()
$remoteHash = Get-RemoteHash
$status = @(Invoke-Git status --porcelain --untracked-files=all)
$tasks = @(Get-ScheduledTask -TaskName "Obsidian Git Event Sync *" -ErrorAction SilentlyContinue)
$watchdogTasks = @(Get-ScheduledTask -TaskName "Obsidian Git Sync Watchdog *" -ErrorAction SilentlyContinue)

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
        & $GitExe clone --quiet --branch $Branch --single-branch $remoteUrl $probeRoot 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Unable to create the remote pull probe clone." }
        $name = (Invoke-Git config user.name | Select-Object -First 1).Trim()
        $email = (Invoke-Git config user.email | Select-Object -First 1).Trim()
        & $GitExe -C $probeRoot config user.name $name
        & $GitExe -C $probeRoot config user.email $email
        [IO.File]::WriteAllText((Join-Path $probeRoot $probeName), "Remote pull probe $(Get-Date -Format o)`r`n", [Text.UTF8Encoding]::new($false))
        & $GitExe -C $probeRoot add --all
        & $GitExe -C $probeRoot commit --quiet -m "Add remote pull probe" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Unable to commit the remote pull probe." }
        & $GitExe -C $probeRoot push --quiet $Remote $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Unable to push the remote pull probe." }
        $createdHash = ((& $GitExe -C $probeRoot rev-parse HEAD) -join "").Trim()
        [void](Wait-ForLocalHash -ExpectedHash $createdHash)

        Remove-Item -LiteralPath (Join-Path $probeRoot $probeName) -Force
        & $GitExe -C $probeRoot add --all
        & $GitExe -C $probeRoot commit --quiet -m "Remove remote pull probe" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Unable to commit removal of the remote pull probe." }
        & $GitExe -C $probeRoot push --quiet $Remote $Branch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Unable to push removal of the remote pull probe." }
        $deletedHash = ((& $GitExe -C $probeRoot rev-parse HEAD) -join "").Trim()
        [void](Wait-ForLocalHash -ExpectedHash $deletedHash)
        $remotePullProbe = [pscustomobject]@{ createHash = $createdHash; deleteHash = $deletedHash }
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
    eventProbe = $probe
    remotePullProbe = $remotePullProbe
}

$result | ConvertTo-Json -Depth 5
if (-not $result.worktreeClean -or -not $result.hashesMatch -or $branchName -ne $Branch -or $visibility -eq "PUBLIC") {
    exit 1
}
