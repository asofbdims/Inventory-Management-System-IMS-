param(
    [string]$Path = (Join-Path $env:USERPROFILE 'Projects\ims'),
    [string]$RepoUrl = 'https://github.com/asofbdims/Inventory-Management-System-IMS-.git'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    Write-Host "Cloning $RepoUrl to $Path ..."
    git clone $RepoUrl $Path
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
} else {
    Write-Host "Using existing folder: $Path"
}

Set-Location -LiteralPath $Path
git config pull.rebase true

$tasksJson = @'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "IMS: Pull latest",
      "type": "shell",
      "command": "powershell",
      "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${workspaceFolder}\\scripts\\sync-pull.ps1"],
      "problemMatcher": [],
      "presentation": { "reveal": "always", "panel": "dedicated" }
    },
    {
      "label": "IMS: Save & Push",
      "type": "shell",
      "command": "powershell",
      "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${workspaceFolder}\\scripts\\sync-push.ps1"],
      "problemMatcher": [],
      "presentation": { "reveal": "always", "panel": "dedicated" }
    }
  ]
}
'@

$vscodeDir = Join-Path $Path '.vscode'
if (-not (Test-Path -LiteralPath $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir | Out-Null
}
$tasksPath = Join-Path $vscodeDir 'tasks.json'
if (-not (Test-Path -LiteralPath $tasksPath)) {
    Set-Content -LiteralPath $tasksPath -Value $tasksJson -Encoding UTF8
    Write-Host "Created $tasksPath"
} else {
    Write-Host "Kept existing $tasksPath"
}

Write-Host ""
Write-Host "Done. Open $Path in VS Code."
Write-Host "Run Task 'IMS: Pull latest' before working and 'IMS: Save & Push' when done."
