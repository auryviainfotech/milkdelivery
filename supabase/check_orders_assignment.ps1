# Check Orders and Delivery Assignments
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "=== Checking Orders and Assignments ===" -ForegroundColor Cyan

# 1. List Delivery Persons to find 'Bilal'
Write-Host "`nDelivery Persons:" -ForegroundColor Yellow
$persons = Invoke-SQL "SELECT id, full_name, phone FROM profiles WHERE role = 'delivery';"
$persons | Format-Table

# 2. List Orders for Tomorrow (2026-01-23)
$targetDate = "2026-01-23"
Write-Host "`nOrders for $targetDate :" -ForegroundColor Yellow
$orders = Invoke-SQL "SELECT id, user_id, status FROM orders WHERE delivery_date = '$targetDate';"
if ($orders.Count -eq 0) {
    Write-Host "No orders found for $targetDate." -ForegroundColor Red
} else {
    Write-Host "Found $($orders.Count) orders." -ForegroundColor Green
}

# 3. Check Deliveries linked to those orders
Write-Host "`nDeliveries for $targetDate :" -ForegroundColor Yellow
$deliveries = Invoke-SQL "SELECT d.id, d.delivery_person_id, d.status, p.full_name as delivery_person_name FROM deliveries d LEFT JOIN profiles p ON d.delivery_person_id = p.id WHERE d.scheduled_date = '$targetDate';"

if ($deliveries.Count -eq 0) {
    Write-Host "No deliveries found for $targetDate." -ForegroundColor Red
} else {
    $deliveries | Format-Table
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan
