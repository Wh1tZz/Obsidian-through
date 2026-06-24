[CmdletBinding()]
param(
    [string]$GhExe = ""
)

$ErrorActionPreference = "Stop"

if (-not $GhExe) {
    $command = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $command) { $command = Get-Command gh -ErrorAction SilentlyContinue }
    if (-not $command) { throw "GitHub CLI was not found. Install it or pass -GhExe." }
    $GhExe = $command.Source
}
$GhExe = (Resolve-Path -LiteralPath $GhExe).Path

& $GhExe auth status --hostname github.com *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Opening GitHub web authorization. Complete login in your browser..."
    & $GhExe auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw "GitHub web login did not complete." }
}

& $GhExe auth setup-git
if ($LASTEXITCODE -ne 0) { throw "Unable to configure Git credentials through GitHub CLI." }

$accountJson = & $GhExe api user --jq '{login: .login, id: .id, name: .name}'
if ($LASTEXITCODE -ne 0) { throw "Unable to verify the authenticated GitHub account." }
$accountJson
