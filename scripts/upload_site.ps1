# Uploads the IMS web app (single HTML file) to the public Supabase Storage
# bucket "ims-site" so the app is served from the cloud CDN.
#
# No credentials are hardcoded. Provide them as environment variables:
#   SUPABASE_URL           (cloud project URL, e.g. https://<ref>.supabase.co)
#   SUPABASE_ANON_KEY      (public/publishable key - embedded in the served stub config)
#   SUPABASE_SECRET_KEY    (service role key - used to upload, NEVER written anywhere)
#
# Requires migration 0008_ims_site_bucket.sql to be applied first.
# Usage:
#   $env:SUPABASE_URL='https://<ref>.supabase.co'; $env:SUPABASE_ANON_KEY='...'; $env:SUPABASE_SECRET_KEY='...'
#   powershell -ExecutionPolicy Bypass -File scripts/upload_site.ps1
$ErrorActionPreference = 'Stop'
$base = $env:SUPABASE_URL
$anon = $env:SUPABASE_ANON_KEY
$secret = $env:SUPABASE_SECRET_KEY
if (-not $base -or -not $anon -or -not $secret) {
    throw 'SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SECRET_KEY environment variables are required.'
}

$root = Split-Path -Parent $PSScriptRoot
$html = Join-Path $root 'stock-management-system.html'

# Build a stub config.local.js containing ONLY the public anon key (no service key).
$stub = "window.IMS_CONFIG = {`n  anonKey: `"$anon`"`n};"
$stubPath = Join-Path $env:TEMP 'ims-site-config.local.js'
Set-Content -LiteralPath $stubPath -Value $stub -Encoding UTF8

function Upload-File([string]$Local, [string]$ObjectName, [string]$ContentType) {
    $uri = "$base/storage/v1/object/ims-site/$ObjectName"
    $headers = @{ Authorization = "Bearer $secret" }
    # Delete-then-put so the object's stored Content-Type is always refreshed.
    try { Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers | Out-Null } catch { }
    $headers['Content-Type'] = $ContentType
    $resp = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -InFile $Local
    Write-Host "uploaded: $ObjectName ($ContentType)"
    return $resp
}

$null = Upload-File -Local $html -ObjectName 'stock-management-system.html' -ContentType 'text/html'
$null = Upload-File -Local $stubPath -ObjectName 'config.local.js' -ContentType 'application/javascript'

Write-Host "Site is live at:"
Write-Host "  $base/storage/v1/object/public/ims-site/stock-management-system.html"