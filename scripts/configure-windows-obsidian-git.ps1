[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,

    [ValidateSet("EventWatcher", "PluginTimer")]
    [string]$Mode = "EventWatcher"
)

$ErrorActionPreference = "Stop"
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path
$pluginDirectory = Join-Path $VaultPath ".obsidian\plugins\obsidian-git"
$dataPath = Join-Path $pluginDirectory "data.json"
New-Item -ItemType Directory -Path $pluginDirectory -Force | Out-Null

if (Test-Path -LiteralPath $dataPath) {
    $raw = [IO.File]::ReadAllText($dataPath, [Text.Encoding]::UTF8)
    $settings = if ($raw.Trim()) { $raw | ConvertFrom-Json } else { [pscustomobject]@{} }
} else {
    $settings = [pscustomobject]@{}
}

if ($Mode -eq "EventWatcher") {
    $required = [ordered]@{
        autoSaveInterval = 0
        autoPushInterval = 0
        autoPullInterval = 0
        autoPullOnBoot = $true
        autoBackupAfterFileChange = $false
        differentIntervalCommitAndPush = $false
        disablePopups = $true
        showErrorNotices = $true
    }
} else {
    $required = [ordered]@{
        autoSaveInterval = 1
        autoPushInterval = 0
        autoPullInterval = 1
        autoPullOnBoot = $true
        autoBackupAfterFileChange = $true
        differentIntervalCommitAndPush = $false
        disablePopups = $false
        showErrorNotices = $true
    }
}

foreach ($entry in $required.GetEnumerator()) {
    if ($settings.PSObject.Properties.Name -contains $entry.Key) {
        $settings.($entry.Key) = $entry.Value
    } else {
        $settings | Add-Member -NotePropertyName $entry.Key -NotePropertyValue $entry.Value
    }
}

$json = $settings | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($dataPath, $json + "`r`n", [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    vaultPath = $VaultPath
    dataPath = $dataPath
    mode = $Mode
    autoCommitAndSync = ($Mode -eq "PluginTimer")
    autoCommitAndSyncIntervalMinutes = $settings.autoSaveInterval
    autoPull = ($Mode -eq "PluginTimer")
    autoPullIntervalMinutes = $settings.autoPullInterval
    pullOnStartup = $true
    syncAfterStoppingFileEdits = $settings.autoBackupAfterFileChange
    splitTimers = $settings.differentIntervalCommitAndPush
    notifications = -not $settings.disablePopups
    reloadObsidianRequired = $true
} | ConvertTo-Json
