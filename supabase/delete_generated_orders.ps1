# Delete generated orders for tomorrow (to allow re-generation)
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

$targetDate = "2026-01-23" # Tomorrow
Write-Host "=== Deleting Orders for $targetDate ===" -ForegroundColor Cyan

# 1. Count existing orders
$checkSql = "SELECT count(*) as count FROM orders WHERE delivery_date = '$targetDate';"
$countResult = Invoke-SQL $checkSql
$count = $countResult[0].count

Write-Host "Found $count orders for $targetDate." -ForegroundColor Yellow

if ($count -gt 0) {
    # 2. Delete deliveries first (if no cascade)
    Write-Host "Deleting related deliveries..." -ForegroundColor Gray
    $delDeliveries = "DELETE FROM deliveries WHERE order_id IN (SELECT id FROM orders WHERE delivery_date = '$targetDate');"
    Invoke-SQL $delDeliveries
    
    # 3. Delete order items
    Write-Host "Deleting related order items..." -ForegroundColor Gray
    $delItems = "DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE delivery_date = '$targetDate');"
    Invoke-SQL $delItems

    # 4. Delete orders
    Write-Host "Deleting orders..." -ForegroundColor Yellow
    $delOrders = "DELETE FROM orders WHERE delivery_date = '$targetDate';"
    Invoke-SQL $delOrders
    
    Write-Host "Successfully deleted orders for $targetDate." -ForegroundColor Green
} else {
    Write-Host "No orders found to delete." -ForegroundColor Green
}

# 5. Optional: Clean up wallet transactions for that date
Write-Host "Cleaning up wallet transactions..." -ForegroundColor Gray
$delTrans = "DELETE FROM wallet_transactions WHERE description LIKE '%$targetDate%';"
Invoke-SQL $delTrans

Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
