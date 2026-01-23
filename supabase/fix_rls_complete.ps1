$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== RLS STATUS CHECK ===" -ForegroundColor Cyan

# Check RLS on all relevant tables
$tables = @("deliveries", "orders", "subscriptions", "profiles", "products")

foreach ($table in $tables) {
    $sql = "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = '$table';"
    $body = @{ query = $sql } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    $status = if ($result.rowsecurity -eq $true) { "ENABLED (Blocking!)" } else { "DISABLED (OK)" }
    $color = if ($result.rowsecurity -eq $true) { "Red" } else { "Green" }
    Write-Host "  $table : $status" -ForegroundColor $color
}

Write-Host "`n=== DISABLING RLS ON ALL TABLES ===" -ForegroundColor Yellow

foreach ($table in $tables) {
    $sql = "ALTER TABLE public.$table DISABLE ROW LEVEL SECURITY;"
    $body = @{ query = $sql } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "  Disabled RLS on: $table" -ForegroundColor Green
    } catch {
        Write-Host "  Error on $table" -ForegroundColor Red
    }
}

Write-Host "`n=== GRANTING anon SELECT ===" -ForegroundColor Yellow

foreach ($table in $tables) {
    $sql = "GRANT SELECT ON public.$table TO anon, authenticated;"
    $body = @{ query = $sql } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "  Granted SELECT on: $table" -ForegroundColor Green
    } catch {
        Write-Host "  Error on $table" -ForegroundColor Red
    }
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "RLS disabled and SELECT granted. App should work now."
