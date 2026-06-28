[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$RepositoryName = "",
    [string]$RepositoryUrl = "",
    [string]$Owner = "",
    [string]$GitExe = "",
    [string]$GhExe = "",
    [string]$Branch = "main",
    [switch]$ConfirmUpload,
    [switch]$OpenRepositoryPage
)

$ErrorActionPreference = "Stop"
if (-not $ConfirmUpload) {
    throw "Upload is not authorized. Show the exact vault path and private repository destination, then rerun with -ConfirmUpload."
}

$VaultPath = (Resolve-Path -LiteralPath $VaultPath).Path
if (-not (Test-Path -LiteralPath (Join-Path $VaultPath ".obsidian"))) {
    throw "The selected directory does not look like an Obsidian vault: $VaultPath"
}

if (-not $GitExe) {
    $gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $gitCommand) { $gitCommand = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $gitCommand) { throw "Git was not found. Run ensure-git-tools.ps1 first." }
    $GitExe = $gitCommand.Source
}
if (-not $GhExe) {
    $ghCommand = Get-Command gh.exe -ErrorAction SilentlyContinue
    if (-not $ghCommand) { $ghCommand = Get-Command gh -ErrorAction SilentlyContinue }
    if (-not $ghCommand) { throw "GitHub CLI was not found. Run ensure-git-tools.ps1 first." }
    $GhExe = $ghCommand.Source
}
$GitExe = (Resolve-Path -LiteralPath $GitExe).Path
$GhExe = (Resolve-Path -LiteralPath $GhExe).Path

& $GhExe auth status --hostname github.com *> $null
if ($LASTEXITCODE -ne 0) { throw "GitHub CLI is not authenticated. Run github-web-login.ps1 first." }
$account = & $GhExe api user | ConvertFrom-Json

if ($RepositoryUrl) {
    $normalizedRepositoryUrl = $RepositoryUrl.Trim()
    if ($normalizedRepositoryUrl -notmatch 'github\.com[/:]([^/]+)/([^/\s]+)/?$') {
        throw "RepositoryUrl must be a GitHub repository URL, such as https://github.com/owner/repository.git"
    }
    if (-not $Owner) { $Owner = $Matches[1] }
    if (-not $RepositoryName) { $RepositoryName = $Matches[2] -replace '\.git$', '' }
}
if (-not $RepositoryName) {
    throw "RepositoryName or RepositoryUrl is required."
}
if (-not $Owner) { $Owner = $account.login }
$repoFullName = "$Owner/$RepositoryName"
$repoUrl = "https://github.com/$repoFullName.git"
$repoWebUrl = "https://github.com/$repoFullName"
if ($OpenRepositoryPage) { Start-Process $repoWebUrl }

$largeFiles = @(Get-ChildItem -LiteralPath $VaultPath -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.Length -gt 95MB })
if ($largeFiles.Count -gt 0) {
    $paths = $largeFiles | ForEach-Object { "$($_.FullName) ($([math]::Round($_.Length / 1MB, 1)) MB)" }
    throw "Files larger than 95 MB must be removed or handled with Git LFS before push: $($paths -join '; ')"
}

if (-not (Test-Path -LiteralPath (Join-Path $VaultPath ".git"))) {
    & $GitExe -C $VaultPath init -b $Branch
    if ($LASTEXITCODE -ne 0) { throw "Unable to initialize the Git repository." }
}

& $GitExe config --global core.longpaths true *> $null
& $GitExe -C $VaultPath config core.longpaths true *> $null

$ignorePath = Join-Path $VaultPath ".gitignore"
$requiredIgnores = @(
    ".obsidian/workspace.json",
    ".obsidian/workspace-mobile.json",
    ".obsidian/cache/",
    ".obsidian/plugins/obsidian-git/data.json",
    ".trash/",
    ".DS_Store",
    "Thumbs.db",
    "desktop.ini"
)
$existingIgnores = if (Test-Path -LiteralPath $ignorePath) { @([IO.File]::ReadAllLines($ignorePath)) } else { @() }
$missingIgnores = @($requiredIgnores | Where-Object { $_ -notin $existingIgnores })
if ($missingIgnores.Count -gt 0) {
    $prefix = if ((Test-Path -LiteralPath $ignorePath) -and (Get-Item -LiteralPath $ignorePath).Length -gt 0) { "`r`n" } else { "" }
    [IO.File]::AppendAllText($ignorePath, $prefix + ($missingIgnores -join "`r`n") + "`r`n", [Text.UTF8Encoding]::new($false))
}

& $GitExe -C $VaultPath rm --cached --ignore-unmatch ".obsidian/plugins/obsidian-git/data.json" *> $null

$authorName = (& $GitExe -C $VaultPath config user.name) -join ""
if (-not $authorName) { & $GitExe -C $VaultPath config user.name $account.login }
$authorEmail = (& $GitExe -C $VaultPath config user.email) -join ""
if (-not $authorEmail) { & $GitExe -C $VaultPath config user.email "$($account.id)+$($account.login)@users.noreply.github.com" }

$savedErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$repoJson = & $GhExe repo view $repoFullName --json visibility,url 2>$null
$repoViewExitCode = $LASTEXITCODE
$ErrorActionPreference = $savedErrorPreference
$repoExists = ($repoViewExitCode -eq 0)
if ($repoExists) {
    $repo = $repoJson | ConvertFrom-Json
    if ($repo.visibility -ne "PRIVATE") { throw "Existing repository is not private: $repoFullName" }
} else {
    if ($OpenRepositoryPage) {
        Start-Process "https://github.com/new?name=$RepositoryName&visibility=private"
    }
    & $GhExe repo create $repoFullName --private
    if ($LASTEXITCODE -ne 0) { throw "Unable to create the private GitHub repository." }
}

$remotes = @(& $GitExe -C $VaultPath remote)
if ($remotes -contains "origin") {
    $origin = ((& $GitExe -C $VaultPath remote get-url origin) -join "").Trim()
    if ($origin.TrimEnd('/') -ne $repoUrl.TrimEnd('/')) {
        throw "The existing origin points somewhere else: $origin"
    }
} else {
    & $GitExe -C $VaultPath remote add origin $repoUrl
    if ($LASTEXITCODE -ne 0) { throw "Unable to add origin." }
}

& $GitExe -C $VaultPath add --all
& $GitExe -C $VaultPath diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    & $GitExe -C $VaultPath commit -m "Initialize Obsidian vault sync"
    if ($LASTEXITCODE -ne 0) { throw "Unable to create the baseline commit." }
}

$head = (& $GitExe -C $VaultPath rev-parse --verify HEAD 2>$null) -join ""
if (-not $head) { throw "The vault contains no commit to push." }

$savedErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $GitExe -C $VaultPath fetch origin $Branch 2>$null
$fetchExitCode = $LASTEXITCODE
$ErrorActionPreference = $savedErrorPreference
$remoteBranchExists = ($fetchExitCode -eq 0)
if ($remoteBranchExists) {
    $backupBranch = "backup-before-remote-merge-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    & $GitExe -C $VaultPath branch $backupBranch *> $null

    & $GitExe -C $VaultPath merge-base --is-ancestor "origin/$Branch" HEAD
    if ($LASTEXITCODE -ne 0) {
        & $GitExe -C $VaultPath merge-base --is-ancestor HEAD "origin/$Branch"
        if ($LASTEXITCODE -eq 0) {
            & $GitExe -C $VaultPath pull --rebase origin $Branch
            if ($LASTEXITCODE -ne 0) { throw "Unable to rebase onto the existing remote branch." }
        } else {
            & $GitExe -C $VaultPath merge --no-edit --allow-unrelated-histories "origin/$Branch"
            if ($LASTEXITCODE -ne 0) {
                throw "Local and remote histories diverged and the safe merge stopped with conflicts. A local backup branch was created: $backupBranch. Resolve conflicts, commit the merge, then push. Force push is disabled."
            }
        }
    }
}

& $GitExe -C $VaultPath push --set-upstream origin $Branch
if ($LASTEXITCODE -ne 0) { throw "Initial push failed." }

$localHash = ((& $GitExe -C $VaultPath rev-parse HEAD) -join "").Trim()
$remoteLine = ((& $GitExe -C $VaultPath ls-remote origin "refs/heads/$Branch" | Select-Object -First 1) -join "").Trim()
$remoteHash = ($remoteLine -split '\s+')[0]
$visibility = (& $GhExe repo view $repoFullName --json visibility --jq .visibility) -join ""

[pscustomobject]@{
    vaultPath = $VaultPath
    repository = $repoFullName
    repositoryUrl = "https://github.com/$repoFullName"
    visibility = $visibility
    branch = $Branch
    localHash = $localHash
    remoteHash = $remoteHash
    hashesMatch = ($localHash -eq $remoteHash)
} | ConvertTo-Json

if ($visibility -ne "PRIVATE" -or $localHash -ne $remoteHash) { exit 1 }
