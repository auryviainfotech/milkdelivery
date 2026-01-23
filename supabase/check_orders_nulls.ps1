$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== CHECKING FOR NULLS IN ORDERS ===" -ForegroundColor Cyan

$sql = "SELECT id, user_id, delivery_date FROM public.orders WHERE user_id IS NULL OR delivery_date IS NULL OR id IS NULL;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($result) {
    Write-Host "FOUND PROBLEM ROWS:" -ForegroundColor Red
    $result | ConvertTo-Json -Depth 3
} else {
    Write-Host "No rows with null required fields found." -ForegroundColor Green
}

Write-Host "`nSample of first 5 rows:"
$sql = "SELECT id, user_id, delivery_date FROM public.orders LIMIT 5;"
$body = @{ query = $sql } | ConvertTo-Json
$rows = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
$rows | ConvertTo-Json -Depth 3
