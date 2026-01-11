# Delete existing orders for tomorrow to allow regeneration
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql, $desc)
    Write-Host "$desc" -ForegroundColor Yellow
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
Write-Host "=== Resetting Orders for Tomorrow ($tomorrow) ===" -ForegroundColor Cyan

# Delete deliveries first (foreign key constraint)
Invoke-SQL "DELETE FROM deliveries WHERE scheduled_date = '$tomorrow';" "1. Deleting deliveries for $tomorrow..."

# Delete order_items for those orders
Invoke-SQL "DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE delivery_date = '$tomorrow');" "2. Deleting order items..."

# Delete orders for tomorrow
Invoke-SQL "DELETE FROM orders WHERE delivery_date = '$tomorrow';" "3. Deleting orders for $tomorrow..."

Write-Host "`n=== Done! Now try 'Generate Tomorrow's Orders' again ===" -ForegroundColor Green
