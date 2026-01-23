$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== GRANTING FULL PERMISSIONS TO anon AND authenticated ===" -ForegroundColor Cyan

$tables = @("deliveries", "orders", "subscriptions", "profiles", "products")

foreach ($table in $tables) {
    Write-Host "Granting on $table..." -ForegroundColor Yellow
    
    # Grant SELECT, INSERT, UPDATE, DELETE to anon and authenticated
    $sql = "GRANT SELECT, INSERT, UPDATE, DELETE ON public.$table TO anon, authenticated;"
    $body = @{ query = $sql } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "  Granted all permissions on: $table" -ForegroundColor Green
    } catch {
        Write-Host "  Error on $table : $_" -ForegroundColor Red
    }
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "Permissions granted. The app should work now!"
