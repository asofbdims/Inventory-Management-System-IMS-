param(
    [string]$RepoPath = (Split-Path -Parent $PSScriptRoot),
    [int]$IntervalSeconds = 60,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$startupDir = [Environment]::GetFolderPath('Startup')
$vbsPath = Join-Path $startupDir 'IMS Auto Pull.vbs'
$logDir = Join-Path $env:LOCALAPPDATA 'ims-auto-pull'
$pidPath = Join-Path $logDir 'auto-pull.pid'
$autoPull = Join-Path $RepoPath 'scripts\auto-pull.ps1'

if ($Uninstall) {
    if (Test-Path -LiteralPath $pidPath) {
        $procId = 0
        $pidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()
        if ([int]::TryParse($pidText, [ref]$procId)) {
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
    }
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.CommandLine -match '-File\s+"[^"]+[\\/]auto-pull\.ps1"' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $vbsPath -Force -ErrorAction SilentlyContinue
    Write-Host "Auto-pull disabled."
    exit 0
}

if (-not (Test-Path -LiteralPath $autoPull)) { throw "Missing $autoPull" }

$vbs = @"
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$autoPull"" -IntervalSeconds $IntervalSeconds", 0, False
"@
Set-Content -LiteralPath $vbsPath -Value $vbs -Encoding ASCII

Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Where-Object { $_.CommandLine -match '-File\s+"[^"]+[\\/]auto-pull\.ps1"' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
& wscript.exe $vbsPath

for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path -LiteralPath $pidPath) { break }
}

if (Test-Path -LiteralPath $pidPath) {
    $newPid = (Get-Content -LiteralPath $pidPath -Raw).Trim()
    Write-Host "Auto-pull running now (PID $newPid)."
} else {
    Write-Host "Auto-pull enabled; it will start at the next login."
}

Write-Host "Auto-pull is on (checks every $IntervalSeconds s and at every login)."
Write-Host "Startup: $vbsPath"
Write-Host "Log:     $(Join-Path $logDir 'auto-pull.log')"
