# Stages the IMS web app into the "public/" folder that is served on Vercel.
#
# Keeps public/ in sync with the single source of truth (stock-management-system.html)
# and writes the hosted config with ONLY the public anon key (never the service role key).
#
# The anon key is public (already served from the cloud), so public/config.local.js is
# safe to commit; the service key lives only in the gitignored config.local.js at the root.
#
# Usage:
#   $env:SUPABASE_ANON_KEY='<publishable/anon key>'
#   powershell -ExecutionPolicy Bypass -File scripts/stage_vercel.ps1
$ErrorActionPreference = 'Stop'
$anon = $env:SUPABASE_ANON_KEY
if (-not $anon) {
    throw 'SUPABASE_ANON_KEY environment variable is required (public anon key only).'
}

$root = Split-Path -Parent $PSScriptRoot
$html = Join-Path $root 'stock-management-system.html'
$public = Join-Path $root 'public'
New-Item -ItemType Directory -Path $public -Force | Out-Null

Copy-Item -LiteralPath $html -Destination (Join-Path $public 'index.html') -Force

$config = @"
// Vercel deployment config - PUBLIC anon key only.
// Never put the service-role key here; it must stay in the gitignored
// config.local.js at the repo root (local dev / password reset only).
window.IMS_CONFIG = {
  anonKey: "$anon"
};
"@
Set-Content -LiteralPath (Join-Path $public 'config.local.js') -Value $config -Encoding ASCII

Write-Host 'Staged public/ for Vercel:'
Write-Host "  public\index.html ($([math]::Round((Get-Item (Join-Path $public 'index.html')).Length / 1kb)) KB)"
Write-Host '  public\config.local.js (anon key only - safe to commit)'