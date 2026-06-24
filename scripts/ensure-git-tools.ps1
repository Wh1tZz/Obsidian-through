[CmdletBinding()]
param(
    [switch]$InstallIfMissing
)

$ErrorActionPreference = "Stop"

function Find-Tool {
    param([string[]]$Names, [string[]]$KnownPaths)
    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    foreach ($path in $KnownPaths) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    return $null
}

function Get-ToolState {
    $gitPath = Find-Tool -Names @("git.exe", "git") -KnownPaths @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
    )
    $ghPath = Find-Tool -Names @("gh.exe", "gh") -KnownPaths @(
        "$env:ProgramFiles\GitHub CLI\gh.exe",
        "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe"
    )
    return [pscustomobject]@{
        gitPath = $gitPath
        gitVersion = if ($gitPath) { (& $gitPath --version) -join " " } else { $null }
        ghPath = $ghPath
        ghVersion = if ($ghPath) { ((& $ghPath --version | Select-Object -First 1) -join " ") } else { $null }
    }
}

$state = Get-ToolState
if ((-not $state.gitPath -or -not $state.ghPath) -and $InstallIfMissing) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) { throw "winget was not found. Install Git and GitHub CLI from their official websites." }

    if (-not $state.gitPath) {
        & $winget.Source install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "Git installation failed." }
    }
    if (-not $state.ghPath) {
        & $winget.Source install --id GitHub.cli --exact --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "GitHub CLI installation failed." }
    }
    $state = Get-ToolState
}

$state | ConvertTo-Json
if (-not $state.gitPath -or -not $state.ghPath) { exit 2 }
