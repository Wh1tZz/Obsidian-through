[CmdletBinding()]
param(
    [string]$VaultPath = "",
    [string]$RepositoryUrl = "",
    [string]$RepositoryName = "obsidian-vault",
    [switch]$InstallIfMissing,
    [switch]$OpenRepositoryPage,
    [switch]$Yes,
    [switch]$Interactive,
    [string]$Proxy = "",
    [int]$DebounceSeconds = 15,
    [int]$PullIntervalSeconds = 30
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function Read-WithDefault {
    param(
        [string]$Prompt,
        [string]$Default
    )
    if ($Default) {
        $value = Read-Host "$Prompt [$Default]"
        if (-not $value) { return $Default }
        return $value
    }
    return (Read-Host $Prompt)
}

function Confirm-Continue {
    param([string]$Message)
    if ($Yes -or -not $Interactive) { return }
    $answer = Read-Host "$Message Press Enter to continue, or type N to cancel"
    if ($answer -match '^(n|no)$') { throw "Cancelled by user." }
}

function Invoke-JsonScript {
    param(
        [string]$ScriptName,
        [string[]]$Arguments = @()
    )
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$ScriptName failed with exit code $exitCode. $($output -join ' ')"
    }
    return ($output | ConvertFrom-Json)
}

function Convert-JsonObjectOutput {
    param([object[]]$Output)
    $text = ($Output -join "`n")
    $start = $text.IndexOf("{")
    $end = $text.LastIndexOf("}")
    if ($start -lt 0 -or $end -lt $start) {
        throw "Expected JSON output but received: $text"
    }
    return $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
}

function Invoke-ChildPowerShell {
    param([string[]]$Arguments)
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & powershell.exe @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    return [pscustomobject]@{ output = $output; exitCode = $exitCode }
}

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

function Get-ObsidianVaultCandidates {
    $paths = New-Object System.Collections.Generic.List[string]

    if ((Test-Path -LiteralPath (Join-Path (Get-Location).Path ".obsidian"))) {
        $paths.Add((Get-Location).Path)
    }

    $obsidianConfig = Join-Path $env:APPDATA "obsidian\obsidian.json"
    if (Test-Path -LiteralPath $obsidianConfig) {
        try {
            $config = Get-Content -Raw -LiteralPath $obsidianConfig | ConvertFrom-Json
            if ($config.vaults) {
                foreach ($property in $config.vaults.PSObject.Properties) {
                    $vault = $property.Value
                    if ($vault.path) { $paths.Add([string]$vault.path) }
                }
            }
        } catch {
            Write-Host "Could not read Obsidian vault list: $($_.Exception.Message)"
        }
    }

    $common = @(
        "$env:USERPROFILE\Documents\Obsidian Vault",
        "$env:USERPROFILE\OneDrive\Documents\Obsidian Vault"
    )
    foreach ($path in $common) { $paths.Add($path) }

    $seen = @{}
    foreach ($path in $paths) {
        if (-not $path) { continue }
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $resolved = (Resolve-Path -LiteralPath $path).Path
        if (-not (Test-Path -LiteralPath (Join-Path $resolved ".obsidian"))) { continue }
        $key = $resolved.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $resolved
        }
    }
}

function Select-VaultPath {
    if ($VaultPath) {
        $resolved = (Resolve-Path -LiteralPath $VaultPath).Path
        if (-not (Test-Path -LiteralPath (Join-Path $resolved ".obsidian"))) {
            throw "The selected directory does not look like an Obsidian vault: $resolved"
        }
        return $resolved
    }

    $candidates = @(Get-ObsidianVaultCandidates)
    if ($candidates.Count -eq 1) {
        return $candidates[0]
    }

    if ($candidates.Count -gt 1) {
        if (-not $Interactive) {
            return $candidates[0]
        }
        Write-Host "Found these Obsidian vaults:"
        for ($i = 0; $i -lt $candidates.Count; $i++) { Write-Host "  $($i + 1). $($candidates[$i])" }
        $choice = Read-WithDefault "Choose vault number" "1"
        $index = [int]$choice - 1
        if ($index -lt 0 -or $index -ge $candidates.Count) { throw "Invalid vault selection." }
        return $candidates[$index]
    }

    if (-not $Interactive) { throw "No Obsidian vault was found automatically. Rerun with --vault." }
    $manual = Read-Host "Enter your Obsidian vault path"
    $resolvedManual = (Resolve-Path -LiteralPath $manual).Path
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedManual ".obsidian"))) {
        throw "The selected directory does not look like an Obsidian vault: $resolvedManual"
    }
    return $resolvedManual
}

function Normalize-RepositoryUrl {
    param(
        [string]$Value,
        [string]$Login
    )
    if (-not $Value) {
        return "https://github.com/$Login/$RepositoryName.git"
    }
    $trimmed = $Value.Trim()
    if ($trimmed -match '^https://github\.com/[^/]+/[^/]+\.git/?$') {
        return $trimmed.TrimEnd('/')
    }
    if ($trimmed -match '^https://github\.com/[^/]+/[^/]+/?$') {
        return $trimmed.TrimEnd('/') + ".git"
    }
    if ($trimmed -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        return "https://github.com/$trimmed.git"
    }
    if ($trimmed -match '^[A-Za-z0-9_.-]+$') {
        return "https://github.com/$Login/$trimmed.git"
    }
    throw "Repository must be a GitHub URL, owner/name, or repository name."
}

function Get-OriginRepositoryUrl {
    param(
        [string]$Path,
        [string]$GitExe
    )
    if (-not (Test-Path -LiteralPath (Join-Path $Path ".git"))) { return "" }
    $origin = ((& $GitExe -C $Path remote get-url origin 2>$null) -join "").Trim()
    if ($LASTEXITCODE -ne 0) { return "" }
    if ($origin -match 'github\.com[/:]([^/]+)/([^/]+?)(\.git)?$') {
        return "https://github.com/$($Matches[1])/$($Matches[2] -replace '\.git$', '').git"
    }
    return ""
}

Write-Host "Obsidian-through is setting up this PC."

Write-Step "Checking Git and GitHub CLI"
$tools = Invoke-JsonScript -ScriptName "ensure-git-tools.ps1" -Arguments @("-InstallIfMissing")
Write-Host "Required tools are ready."

$gitExe = (Resolve-Path -LiteralPath $tools.gitPath).Path
$ghExe = (Resolve-Path -LiteralPath $tools.ghPath).Path

Write-Step "Signing in to GitHub"
Write-Host "A GitHub login page will open. Finish login in the browser; do not paste passwords, codes, or tokens into chat."
$loginArgs = @("-GhExe", $ghExe, "-QuietOutput")
if ($Proxy) { $loginArgs += @("-Proxy", $Proxy) }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "github-web-login.ps1") @loginArgs
if ($LASTEXITCODE -ne 0) { throw "GitHub login failed." }
$account = (& $ghExe api user) | ConvertFrom-Json
Write-Host "GitHub login: $($account.login)"

Write-Step "Finding the Obsidian vault"
$selectedVault = Select-VaultPath
Write-Host "Vault: $selectedVault"

Write-Step "Preparing the private GitHub repository"
$originUrl = Get-OriginRepositoryUrl -Path $selectedVault -GitExe $gitExe
$defaultRepo = if ($RepositoryUrl) { $RepositoryUrl } elseif ($originUrl) { $originUrl } else { "https://github.com/$($account.login)/$RepositoryName.git" }
if (-not $Interactive) {
    $targetRepo = Normalize-RepositoryUrl -Value $defaultRepo -Login $account.login
} else {
    Write-Host "If the repository already exists, paste its GitHub URL."
    Write-Host "If it does not exist, press Enter to create/connect the default private repository."
    $repoInput = Read-WithDefault "Repository URL, owner/name, or name" $defaultRepo
    $targetRepo = Normalize-RepositoryUrl -Value $repoInput -Login $account.login
}
Write-Host "Repository: $targetRepo"
Confirm-Continue "This will upload or merge the selected vault with the private GitHub repository."

Write-Step "Publishing or connecting the vault"
$publishArgs = @(
    "-VaultPath", $selectedVault,
    "-RepositoryUrl", $targetRepo,
    "-GitExe", $gitExe,
    "-GhExe", $ghExe,
    "-ConfirmUpload"
)
$publishCommand = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "publish-vault.ps1")) + $publishArgs
$publishRun = Invoke-ChildPowerShell -Arguments $publishCommand
if ($publishRun.exitCode -ne 0) { throw "Publishing or repository connection failed." }
$publishResult = Convert-JsonObjectOutput -Output $publishRun.output
Write-Host "Private repository connected: $($publishResult.repositoryUrl)"

Write-Step "Configuring Obsidian Git plugin settings for Windows watcher mode"
$configureRun = Invoke-ChildPowerShell -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "configure-windows-obsidian-git.ps1"), "-VaultPath", $selectedVault, "-Mode", "EventWatcher")
if ($configureRun.exitCode -ne 0) { throw "Unable to configure Obsidian Git settings." }

Write-Step "Installing hidden Windows event watcher"
$watcherRun = Invoke-ChildPowerShell -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "install-windows-event-sync.ps1"), "-VaultPath", $selectedVault, "-GitExe", $gitExe, "-DebounceSeconds", $DebounceSeconds, "-PullIntervalSeconds", $PullIntervalSeconds)
if ($watcherRun.exitCode -ne 0) { throw "Unable to install the Windows event watcher." }
$watcherResult = Convert-JsonObjectOutput -Output $watcherRun.output
Write-Host "Watcher task: $($watcherResult.taskName)"

Write-Step "Verifying PC sync state"
$verifyRun = Invoke-ChildPowerShell -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "verify-sync.ps1"), "-VaultPath", $selectedVault, "-GitExe", $gitExe)
if ($verifyRun.exitCode -ne 0) { throw "Verification failed. Review the output above." }
$verifyResult = Convert-JsonObjectOutput -Output $verifyRun.output

Write-Host ""
Write-Host "PC sync setup is complete."
Write-Host "GitHub repository: $($publishResult.repositoryUrl)"
Write-Host "Worktree clean: $($verifyResult.worktreeClean)"
Write-Host "Local and remote match: $($verifyResult.hashesMatch)"
Write-Host "Next test: create or edit one note in Windows Obsidian, wait about $DebounceSeconds seconds, then refresh the GitHub repository page."
Write-Host "For phone setup, run:"
Write-Host "  npx obsidian-through mobile-info --vault `"$selectedVault`" --open-token-page"
