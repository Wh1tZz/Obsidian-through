[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [int]$DebounceSeconds = 15,
    [int]$PullIntervalSeconds = 30,
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
& $GitExe config --global core.longpaths true *> $null
& $GitExe -C $VaultPath config core.longpaths true *> $null

if (-not $InstallRoot) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "ObsidianGitSync"
}
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
$installedWatcher = Join-Path $InstallRoot "watch-vault.ps1"
$installedWatchdog = Join-Path $InstallRoot "watchdog-task.ps1"
$installedLauncher = Join-Path $InstallRoot "run-hidden.vbs"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "watch-vault.ps1") -Destination $installedWatcher -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "watchdog-task.ps1") -Destination $installedWatchdog -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "run-hidden.vbs") -Destination $installedLauncher -Force

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($VaultPath.ToLowerInvariant()))
$vaultHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
$taskName = "Obsidian Git Event Sync $($vaultHash.Substring(0, 8))"
$watchdogTaskName = "Obsidian Git Sync Watchdog $($vaultHash.Substring(0, 8))"
$logPath = Join-Path $InstallRoot "sync-$($vaultHash.Substring(0, 8)).log"
$watchdogLogPath = Join-Path $InstallRoot "watchdog-$($vaultHash.Substring(0, 8)).log"
$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedWatcher`" -VaultPath `"$VaultPath`" -GitExe `"$GitExe`" -DebounceSeconds $DebounceSeconds -PullIntervalSeconds $PullIntervalSeconds -Remote `"$Remote`" -Branch `"$Branch`" -LogPath `"$logPath`""
$watchdogArguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedWatchdog`" -TaskName `"$taskName`" -WatcherPath `"$installedWatcher`" -VaultPath `"$VaultPath`" -LogPath `"$watchdogLogPath`""

$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$installedLauncher`" `"powershell.exe`" $arguments"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Sync an Obsidian vault after file edit events." -Force | Out-Null

$watchdogAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$installedLauncher`" `"powershell.exe`" $watchdogArguments"
$watchdogLogonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$watchdogIntervalTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 3650)
$watchdogSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $watchdogTaskName -Action $watchdogAction -Trigger @($watchdogLogonTrigger, $watchdogIntervalTrigger) -Settings $watchdogSettings -Description "Keep the Obsidian Git event sync task running." -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Start-ScheduledTask -TaskName $watchdogTaskName
Start-Sleep -Seconds 2

[pscustomobject]@{
    taskName = $taskName
    taskState = (Get-ScheduledTask -TaskName $taskName).State.ToString()
    watchdogTaskName = $watchdogTaskName
    watchdogTaskState = (Get-ScheduledTask -TaskName $watchdogTaskName).State.ToString()
    vaultPath = $VaultPath
    gitExe = $GitExe
    watcherPath = $installedWatcher
    watchdogPath = $installedWatchdog
    launcherPath = $installedLauncher
    logPath = $logPath
    watchdogLogPath = $watchdogLogPath
    debounceSeconds = $DebounceSeconds
    pullIntervalSeconds = $PullIntervalSeconds
} | ConvertTo-Json
