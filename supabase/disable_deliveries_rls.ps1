$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== DISABLING RLS ON DELIVERIES TABLE ===" -ForegroundColor Cyan

# Disable RLS on deliveries table
$sql = "ALTER TABLE public.deliveries DISABLE ROW LEVEL SECURITY;"

Write-Host "Executing: $sql" -ForegroundColor Yellow
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: RLS DISABLED on deliveries table!" -ForegroundColor Green
    Write-Host "The Flutter app should now be able to query deliveries without RLS blocking." -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "Restart the Delivery App and check if deliveries appear."
