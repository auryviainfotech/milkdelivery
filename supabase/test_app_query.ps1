$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$bilalId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== TESTING EXACT QUERY FROM APP ===" -ForegroundColor Cyan
Write-Host "Bilal ID: $bilalId"
Write-Host "Date: $today"

# 1. SIMPLE QUERY - what the app runs first
Write-Host "`n1. SIMPLE QUERY (same as app):" -ForegroundColor Yellow
$sql = "SELECT id, scheduled_date, status, delivery_person_id FROM public.deliveries WHERE delivery_person_id = '$bilalId' AND scheduled_date = '$today';"
Write-Host "SQL: $sql" -ForegroundColor Gray
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($result -and $result.Count -gt 0) {
        Write-Host "SUCCESS! Found $($result.Count) deliveries:" -ForegroundColor Green
        $result | ForEach-Object { Write-Host "  - $($_.id)" }
    } else {
        Write-Host "NO RESULTS from simple query!" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

# 2. Check if delivery_person_id format matches
Write-Host "`n2. Checking UUID format match:" -ForegroundColor Yellow
$sql = "SELECT id, delivery_person_id FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$del = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($del) {
    Write-Host "Delivery exists with delivery_person_id: '$($del.delivery_person_id)'"
    Write-Host "Comparing to bilal ID:                   '$bilalId'"
    if ($del.delivery_person_id -eq $bilalId) {
        Write-Host "MATCH!" -ForegroundColor Green
    } else {
        Write-Host "MISMATCH! IDs don't match!" -ForegroundColor Red
    }
}

Write-Host "`n=== END ===" -ForegroundColor Cyan
