$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"
$bilalId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"

Write-Host "=== DELIVERY APP QUERY SIMULATION ===" -ForegroundColor Cyan
Write-Host "Today: $today"
Write-Host "Bilal ID: $bilalId"

# Exact query the app runs
Write-Host "`n1. Simulating App Query (bilal + today):" -ForegroundColor Yellow
$sql = "SELECT d.*, o.id as order_id FROM public.deliveries d LEFT JOIN public.orders o ON d.order_id = o.id WHERE d.delivery_person_id = '$bilalId' AND d.scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($result -and $result.Count -gt 0) {
    Write-Host "  SUCCESS! Found $($result.Count) deliveries." -ForegroundColor Green
    $result | ForEach-Object {
        Write-Host "  - Delivery ID: $($_.id)"
        Write-Host "    Order ID: $($_.order_id)"
        Write-Host "    Status: $($_.status)"
        Write-Host "    Scheduled: $($_.scheduled_date)"
    }
} else {
    Write-Host "  FAILURE: No results matching (bilal + today)." -ForegroundColor Red
}

# Check raw deliveries table
Write-Host "`n2. All Deliveries in DB:" -ForegroundColor Yellow
$sql = "SELECT id, order_id, delivery_person_id, scheduled_date, status FROM public.deliveries;"
$body = @{ query = $sql } | ConvertTo-Json
$all = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($all) {
    Write-Host "  Total Rows: $($all.Count)"
    $all | ForEach-Object {
        Write-Host "  -----------------------------------------------"
        Write-Host "  ID:        $($_.id)"
        Write-Host "  Order ID:  $($_.order_id)"
        Write-Host "  Person ID: $($_.delivery_person_id)"
        Write-Host "  Date:      $($_.scheduled_date)"
        Write-Host "  Status:    $($_.status)"
        
        # Compare
        $personMatch = $_.delivery_person_id -eq $bilalId
        $dateMatch = $_.scheduled_date -eq $today
        Write-Host "  [Person Match: $personMatch] [Date Match: $dateMatch]" -ForegroundColor $(if ($personMatch -and $dateMatch) { "Green" } else { "Red" })
    }
} else {
    Write-Host "  No deliveries found at all!" -ForegroundColor Red
}
