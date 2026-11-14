$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'HEAD') {
    Write-Error "You are not on a branch."
    exit 1
}

$changes = git status --porcelain
if ($changes) {
    $message = "sync: $env:USERNAME $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git add -A
    git commit -m $message
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Commit failed."
        exit 1
    }
} else {
    Write-Host "No local changes to commit."
}

Write-Host "Syncing with origin/$branch ..."
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) {
    Write-Error "Pull failed. Fix any conflicts, then run this task again."
    exit 1
}

git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed. Make sure you are signed in to GitHub."
    exit 1
}

Write-Host "Pushed $(git rev-parse --short HEAD) to origin/$branch"
