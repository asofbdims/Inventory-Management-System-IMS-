# Seeds the IMS auth users + profiles into a running local Supabase stack.
# Run AFTER `supabase db reset` (which wipes auth.users) and BEFORE logging into the app.
# Usage:  powershell -ExecutionPolicy Bypass -File scripts/seed_users.ps1
#
# No credentials are hardcoded. Provide them as environment variables:
#   SUPABASE_URL           (default: http://127.0.0.1:54321)
#   SUPABASE_ANON_KEY      (required)
#   SUPABASE_SECRET_KEY    (required - service role key for admin API)
#   SUPERADMIN_PASS        (optional; random password is generated if omitted)
#   ASO_VIEWER_PASS        (optional; random password is generated if omitted)
#   CENTRE_PASS            (optional; random password is generated if omitted)
$ErrorActionPreference = 'Stop'
$base = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'http://127.0.0.1:54321' }
$anon = $env:SUPABASE_ANON_KEY
$secret = $env:SUPABASE_SECRET_KEY
if (-not $anon -or -not $secret) {
    throw 'SUPABASE_ANON_KEY and SUPABASE_SECRET_KEY environment variables are required.'
}

if (-not $env:SUPERADMIN_PASS)  { $env:SUPERADMIN_PASS  = -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object { [char]$_ }) }
if (-not $env:ASO_VIEWER_PASS)  { $env:ASO_VIEWER_PASS  = -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object { [char]$_ }) }
if (-not $env:CENTRE_PASS)      { $env:CENTRE_PASS      = -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object { [char]$_ }) }

# All 18 main-centre logins share this password (env-provided or generated).
$centrePass = $env:CENTRE_PASS

$centres = @(
    @{ id = 1;  name = 'ANKHEER';          username = 'ankheer' },
    @{ id = 2;  name = 'BALLABGARH';       username = 'ballabgarh' },
    @{ id = 3;  name = 'DLF CITY GURGAON'; username = 'dlf_city_gurgaon' },
    @{ id = 4;  name = 'TAORU';            username = 'taoru' },
    @{ id = 5;  name = 'FIROZPUR JHIRKA';  username = 'firozpur_jhirka' },
    @{ id = 6;  name = 'GURGAON';          username = 'gurgaon' },
    @{ id = 7;  name = 'MOHANA';           username = 'mohana' },
    @{ id = 8;  name = 'ZAIBABAD KHERLI';  username = 'zaibabad_kherli' },
    @{ id = 9;  name = 'NANGLA GUJRAN';    username = 'nangla_gujran' },
    @{ id = 10; name = 'NIT - 2';          username = 'nit-2' },
    @{ id = 11; name = 'BAROLI';           username = 'baroli' },
    @{ id = 12; name = 'HODAL';            username = 'hodal' },
    @{ id = 13; name = 'PALWAL';           username = 'palwal' },
    @{ id = 14; name = 'RAJENDRA PARK';    username = 'rajendra_park' },
    @{ id = 15; name = 'SECTOR-15-A';      username = 'sector-15-a' },
    @{ id = 16; name = 'PRITHLA';          username = 'prithla' },
    @{ id = 17; name = 'SURAJ KUND';       username = 'suraj_kund' },
    @{ id = 18; name = 'TIGAON';           username = 'tigaon' }
)

$h = @{ apikey = $secret; Authorization = "Bearer $secret"; 'Content-Type' = 'application/json' }
$all = Invoke-RestMethod -Uri "$base/auth/v1/admin/users" -Headers $h
$emailToId = @{}
foreach ($u in $all.users) { $emailToId[$u.email] = $u.id }

function Get-Or-Create($username, $password) {
    $email = "$username@ims.local"
    if ($emailToId.ContainsKey($email)) {
        Write-Host "exists: $username"
        return $emailToId[$email]
    }
    $body = @{ email = $email; password = $password; email_confirm = $true } | ConvertTo-Json
    $resp = Invoke-RestMethod -Method Post -Uri "$base/auth/v1/admin/users" -Headers $h -Body $body
    Write-Host "created: $username"
    return $resp.id
}

$rows = @()

$superId = Get-Or-Create 'superadmin' $env:SUPERADMIN_PASS
$rows += "('$superId','superadmin','Admin','SUPERADMIN','ASO ADMIN',NULL,'')"

$viewerId = Get-Or-Create 'aso_viewer' $env:ASO_VIEWER_PASS
$rows += "('$viewerId','aso_viewer','ASO Viewer','ASO_VIEWER','ASO VIEWER',NULL,'')"

foreach ($c in $centres) {
    $username = $c.username
    $password = $centrePass
    $uid = Get-Or-Create $username $password
    $rows += "('$uid','$username','$($c.name)','CENTRE','CENTRE',$($c.id),'$($c.name)')"
}

$values = $rows -join ",`n`t"
$sql = 'insert into public.profiles (id, username, name, role, "userType", "centreId", "centreName") values' + "`n`t" + $values + ';'
$sql | & docker exec -i supabase_db_ims-main psql -U postgres -d postgres 2>&1
Write-Host "Inserted $($rows.Count) profiles."

Write-Host "---- profiles ----"
'select username, role, "userType", "centreId", "centreName" from public.profiles order by role desc nulls first, "centreId";' |
    & docker exec -i supabase_db_ims-main psql -U postgres -d postgres 2>&1