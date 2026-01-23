$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date
$localDate = $today.ToString("yyyy-MM-dd")
$utcDate = $today.ToUniversalTime().ToString("yyyy-MM-dd")

Write-Host "=== DATE MISMATCH CHECK ===" -ForegroundColor Cyan
Write-Host "Local Date (Device): $localDate"
Write-Host "UTC Date (Server?):  $utcDate"

$sql = "SELECT id, scheduled_date, delivery_person_id FROM public.deliveries WHERE scheduled_date = '$localDate';"
$body = @{ query = $sql } | ConvertTo-Json
$localResult = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "`nQuerying with LOCAL date ($localDate):"
if ($localResult) {
    Write-Host "  FOUND $($localResult.Count) deliveries." -ForegroundColor Green
} else {
    Write-Host "  FOUND 0 deliveries." -ForegroundColor Red
}

$sql = "SELECT id, scheduled_date, delivery_person_id FROM public.deliveries WHERE scheduled_date = '$utcDate';"
$body = @{ query = $sql } | ConvertTo-Json
$utcResult = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "`nQuerying with UTC date ($utcDate):"
if ($utcResult) {
    Write-Host "  FOUND $($utcResult.Count) deliveries." -ForegroundColor Green
} else {
    Write-Host "  FOUND 0 deliveries." -ForegroundColor Red
}
