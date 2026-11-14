param(
    [string]$RepoPath = (Split-Path -Parent $PSScriptRoot),
    [int]$IntervalSeconds = 60,
    [string]$LogPath = (Join-Path $env:LOCALAPPDATA 'ims-auto-pull\auto-pull.log'),
    [switch]$RunOnce
)

$ErrorActionPreference = 'SilentlyContinue'

$mutex = $null
if (-not $RunOnce) {
    $mutex = New-Object System.Threading.Mutex($false, 'Local\IMSAutoPull')
    if (-not $mutex.WaitOne(0)) { exit 0 }
}

$logDir = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogPath -Value $line
}

function Invoke-SyncCycle {
    Push-Location -LiteralPath $RepoPath
    try {
        $branch = (git rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($branch) -or $branch -eq 'HEAD') { $branch = 'main' }

        git fetch origin $branch --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "fetch failed (offline or GitHub unreachable)"
            return
        }

        $behind = 0
        $countText = (git rev-list --count "HEAD..origin/$branch" 2>$null | Out-String).Trim()
        [int]::TryParse($countText, [ref]$behind) | Out-Null
        if ($behind -le 0) { return }

        Write-Log "found $behind new commit(s) on origin/$branch"

        $dirty = (git status --porcelain 2>$null | Out-String).Trim()
        if ($dirty) {
            Write-Log "local changes present; skipping pull until they are committed or stashed"
            return
        }

        $pullOutput = (git pull --ff-only 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0) {
            $head = (git rev-parse --short HEAD 2>$null | Out-String).Trim()
            Write-Log "pull ok, now at $head"
        } else {
            Write-Log "fast-forward pull failed; manual sync required: $pullOutput"
        }
    } finally {
        Pop-Location
    }
}

if ($RunOnce) {
    Invoke-SyncCycle
    exit 0
}

$pidPath = Join-Path $logDir 'auto-pull.pid'
Set-Content -LiteralPath $pidPath -Value $PID -Encoding ASCII
Write-Log "auto-pull started for $RepoPath (every $IntervalSeconds s, PID $PID)"

try {
    while ($true) {
        Invoke-SyncCycle
        Start-Sleep -Seconds $IntervalSeconds
    }
} finally {
    Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
    if ($mutex) {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
