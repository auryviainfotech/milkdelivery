$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$today = Get-Date -Format "yyyy-MM-dd"
Write-Host "=== DELIVERY DEBUG - $today ===" -ForegroundColor Cyan

# Count orders for today
$sql = "SELECT COUNT(*) as order_count FROM public.orders WHERE delivery_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Orders for today: $($result.order_count)" -ForegroundColor Yellow

# Count deliveries for today
$sql = "SELECT COUNT(*) as delivery_count FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Deliveries for today: $($result.delivery_count)" -ForegroundColor Yellow

# Count deliveries with NULL delivery_person_id
$sql = "SELECT COUNT(*) as unassigned FROM public.deliveries WHERE scheduled_date = '$today' AND delivery_person_id IS NULL;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Unassigned deliveries: $($result.unassigned)" -ForegroundColor $(if ($result.unassigned -gt 0) { "Red" } else { "Green" })

# Count deliveries with assigned delivery_person_id
$sql = "SELECT COUNT(*) as assigned FROM public.deliveries WHERE scheduled_date = '$today' AND delivery_person_id IS NOT NULL;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Assigned deliveries: $($result.assigned)" -ForegroundColor $(if ($result.assigned -gt 0) { "Green" } else { "Yellow" })

# Show delivery persons
$sql = "SELECT id, full_name FROM public.profiles WHERE role = 'delivery';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "`nDelivery Persons:" -ForegroundColor Cyan
$result | ForEach-Object { Write-Host "  - $($_.full_name) [$($_.id)]" }

# Show today's deliveries with assignment status
$sql = "SELECT d.id, d.delivery_person_id, d.status, p.full_name FROM public.deliveries d LEFT JOIN public.profiles p ON d.delivery_person_id = p.id WHERE d.scheduled_date = '$today' LIMIT 5;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "`nSample Deliveries for Today:" -ForegroundColor Cyan
if ($result) {
    $result | ForEach-Object { 
        $assignee = if ($_.full_name) { $_.full_name } else { "UNASSIGNED" }
        Write-Host "  - Status: $($_.status), Assigned to: $assignee"
    }
} else {
    Write-Host "  (none)" -ForegroundColor Yellow
}

Write-Host "`n=== END ===" -ForegroundColor Cyan
