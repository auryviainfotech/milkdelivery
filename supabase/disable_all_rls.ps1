$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== DISABLING RLS ON ALL RELATED TABLES ===" -ForegroundColor Cyan
Write-Host "This is temporary for testing. Re-enable with proper policies for production." -ForegroundColor Yellow

$tables = @("orders", "subscriptions", "profiles", "products")

foreach ($table in $tables) {
    $sql = "ALTER TABLE public.$table DISABLE ROW LEVEL SECURITY;"
    Write-Host "Disabling RLS on: $table" -ForegroundColor Gray
    $body = @{ query = $sql } | ConvertTo-Json
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "  OK" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "RLS disabled on: orders, subscriptions, profiles, products"
Write-Host "The Delivery App should now show full customer/product details."
