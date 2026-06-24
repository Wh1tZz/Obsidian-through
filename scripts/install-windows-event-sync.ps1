[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [int]$DebounceSeconds = 60,
    [int]$PullIntervalSeconds = 60,
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [string]$InstallRoot = ""
)

$ErrorActionPreference = "Stop"
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path
if (-not (Test-Path -LiteralPath (Join-Path $VaultPath ".git"))) {
    throw "Vault is not a Git repository: $VaultPath"
}

if (-not $GitExe) {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $command) { throw "Git executable was not found. Pass -GitExe explicitly." }
    $GitExe = $command.Source
}
$GitExe = (Resolve-Path -LiteralPath $GitExe).Path

if (-not $InstallRoot) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "ObsidianGitSync"
}
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
$installedWatcher = Join-Path $InstallRoot "watch-vault.ps1"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "watch-vault.ps1") -Destination $installedWatcher -Force

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($VaultPath.ToLowerInvariant()))
$vaultHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
$taskName = "Obsidian Git Event Sync $($vaultHash.Substring(0, 8))"
$logPath = Join-Path $InstallRoot "sync-$($vaultHash.Substring(0, 8)).log"
$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedWatcher`" -VaultPath `"$VaultPath`" -GitExe `"$GitExe`" -DebounceSeconds $DebounceSeconds -PullIntervalSeconds $PullIntervalSeconds -Remote `"$Remote`" -Branch `"$Branch`" -LogPath `"$logPath`""

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Sync an Obsidian vault after file edit events." -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 2

[pscustomobject]@{
    taskName = $taskName
    taskState = (Get-ScheduledTask -TaskName $taskName).State.ToString()
    vaultPath = $VaultPath
    gitExe = $GitExe
    watcherPath = $installedWatcher
    logPath = $logPath
    debounceSeconds = $DebounceSeconds
    pullIntervalSeconds = $PullIntervalSeconds
} | ConvertTo-Json
