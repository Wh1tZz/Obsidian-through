[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    [string]$LogPath = ""
)

$ErrorActionPreference = "Continue"

if (-not $LogPath) {
    $LogPath = Join-Path $env:LOCALAPPDATA "ObsidianGitSync\watchdog.log"
}
$logDirectory = Split-Path -Parent $LogPath
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

function Write-WatchdogLog {
    param([string]$Message)
    if ((Test-Path -LiteralPath $LogPath) -and (Get-Item -LiteralPath $LogPath).Length -gt 1048576) {
        Get-Content -LiteralPath $LogPath -Tail 300 | Set-Content -LiteralPath "$LogPath.tmp" -Encoding UTF8
        Move-Item -LiteralPath "$LogPath.tmp" -Destination $LogPath -Force
    }
    Add-Content -LiteralPath $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -Encoding UTF8
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    Write-WatchdogLog "target task not found: $TaskName"
    exit 1
}

if ($task.State -ne "Running") {
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 2
    $state = (Get-ScheduledTask -TaskName $TaskName).State.ToString()
    Write-WatchdogLog "started target task: $TaskName; state=$state"
}
