[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultPath,
    [string]$GitExe = "",
    [switch]$ListDeleted,
    [int]$MaxCount = 30,
    [string]$NotePath = "",
    [switch]$Commit,
    [switch]$Push
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

$insideWorkTree = ((Invoke-Git rev-parse --is-inside-work-tree) -join "").Trim()
if ($insideWorkTree -ne "true") { throw "VaultPath is not inside a Git worktree." }

if ($ListDeleted) {
    Invoke-Git -c core.quotepath=false log --name-status --diff-filter=D "--max-count=$MaxCount" --date=local "--pretty=format:commit %h%nDate: %ad%nSubject: %s"
    return
}

if (-not $NotePath) {
    throw "Provide -ListDeleted to inspect deleted files, or provide -NotePath to restore one file."
}

$status = @(Invoke-Git status --porcelain --untracked-files=all)
if ($status.Count -ne 0) {
    throw "Worktree is not clean. Resolve or commit current changes before restoring a deleted note."
}

$existing = Join-Path $VaultPath $NotePath
if (Test-Path -LiteralPath $existing) {
    throw "The note already exists at '$NotePath'. Refusing to overwrite it."
}

$deletedCommits = @(Invoke-Git log --diff-filter=D --format=%H -- $NotePath)
if ($deletedCommits.Count -eq 0) {
    throw "No deletion commit was found for '$NotePath'. Check the path with -ListDeleted."
}

$deleteCommit = ([string]$deletedCommits[0]).Trim()
$sourceCommit = "$deleteCommit^"
Invoke-Git restore "--source=$sourceCommit" -- $NotePath | Out-Null

$result = [ordered]@{
    restoredPath = $NotePath
    deletionCommit = $deleteCommit
    sourceCommit = $sourceCommit
    committed = $false
    pushed = $false
}

if ($Commit) {
    Invoke-Git add -- $NotePath | Out-Null
    Invoke-Git commit -m "Restore accidentally deleted note" | Out-Null
    $result.committed = $true
}

if ($Push) {
    if (-not $Commit) { throw "-Push requires -Commit so the restored file is recorded first." }
    Invoke-Git push | Out-Null
    $result.pushed = $true
}

[pscustomobject]$result | ConvertTo-Json
