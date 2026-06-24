[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [string]$GhExe = "",
    [switch]$OpenTokenPage
)

$ErrorActionPreference = "Stop"
$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path

if (-not $GitExe) {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $command) { throw "Git was not found." }
    $GitExe = $command.Source
}
if (-not $GhExe) {
    $command = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command gh -ErrorAction SilentlyContinue }
    if (-not $command) { throw "GitHub CLI was not found." }
    $GhExe = $command.Source
}
$GitExe = (Resolve-Path -LiteralPath $GitExe).Path
$GhExe = (Resolve-Path -LiteralPath $GhExe).Path

& $GhExe auth status --hostname github.com *> $null
if ($LASTEXITCODE -ne 0) { throw "GitHub CLI is not authenticated." }
$account = & $GhExe api user | ConvertFrom-Json
$remoteUrl = ((& $GitExe -C $VaultPath remote get-url origin) -join "").Trim()
if ($LASTEXITCODE -ne 0 -or $remoteUrl -notmatch 'github\.com[/:]([^/]+)/([^/]+)$') {
    throw "Origin is not a GitHub repository."
}
$owner = $Matches[1]
$repository = $Matches[2] -replace '\.git$', ''
$repoFullName = "$owner/$repository"
$visibility = ((& $GhExe repo view $repoFullName --json visibility --jq .visibility) -join "").Trim()
if ($visibility -ne "PRIVATE") { throw "The repository must be private before mobile setup." }

$tokenUrl = "https://github.com/settings/personal-access-tokens/new"
if ($OpenTokenPage) { Start-Process $tokenUrl }

[pscustomobject]@{
    githubLogin = $account.login
    authorName = if ($account.name) { $account.name } else { $account.login }
    authorEmail = "$($account.id)+$($account.login)@users.noreply.github.com"
    repository = $repoFullName
    repositoryVisibility = $visibility
    repositoryUrl = "https://github.com/$repoFullName"
    cloneUrl = "https://github.com/$repoFullName.git"
    tokenCreationUrl = $tokenUrl
    tokenManagementUrl = "https://github.com/settings/personal-access-tokens"
    githubEmailSettingsUrl = "https://github.com/settings/emails"
    obsidianGitPluginUrl = "https://obsidian.md/plugins?id=obsidian-git"
    obsidianDownloadUrl = "https://obsidian.md/download"
    iphoneAppStoreUrl = "https://apps.apple.com/app/obsidian-connected-notes/id1557175442"
    androidPlayStoreUrl = "https://play.google.com/store/apps/details?id=md.obsidian"
} | ConvertTo-Json
