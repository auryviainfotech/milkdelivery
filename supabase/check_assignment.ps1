$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== DELIVERY ASSIGNMENT CHECK ===" -ForegroundColor Cyan
Write-Host "Today: $today"

# Get all deliveries for today
$sql = "SELECT d.id, d.delivery_person_id, d.scheduled_date, p.full_name as assigned_to FROM public.deliveries d LEFT JOIN public.profiles p ON d.delivery_person_id = p.id WHERE d.scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$deliveries = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "Deliveries for today:"
$deliveries | ForEach-Object {
    Write-Host "  Delivery: $($_.id)"
    Write-Host "  Assigned TO: $($_.assigned_to) ($($_.delivery_person_id))"
    Write-Host ""
}

# Get bilal's ID
Write-Host "Bilal's ID in database:"
$sql = "SELECT id, full_name FROM public.profiles WHERE full_name ILIKE '%bilal%';"
$body = @{ query = $sql } | ConvertTo-Json
$bilal = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "  $($bilal.full_name): $($bilal.id)"

# Compare
if ($deliveries -and $bilal) {
    $match = $deliveries.delivery_person_id -eq $bilal.id
    Write-Host ""
    Write-Host "MATCH: $match" -ForegroundColor $(if ($match) { "Green" } else { "Red" })
}
