$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Pulling latest from origin/$branch ..."
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) {
    Write-Error "Pull failed. Fix any conflicts, then run this task again."
    exit 1
}

Write-Host "Now at $(git rev-parse --short HEAD) - $(git log -1 --pretty=%s)"
