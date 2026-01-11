# Check if orders already exist for tomorrow - this would cause 0 orders created
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql, $desc)
    Write-Host "`n$desc" -ForegroundColor Yellow
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "Result:" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 5 | Write-Host
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "=== Check Existing Orders ===" -ForegroundColor Cyan

$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
Write-Host "Tomorrow: $tomorrow"

# Check if orders already exist for tomorrow
Invoke-SQL "SELECT * FROM orders WHERE delivery_date = '$tomorrow';" "Orders for tomorrow ($tomorrow):"

# Check all orders
Invoke-SQL "SELECT id, user_id, delivery_date, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5;" "Recent orders:"

# Check subscriptions end_date
Invoke-SQL "SELECT id, end_date FROM subscriptions WHERE status = 'active';" "Active subscription end dates:"

# If orders exist, delete them to allow re-generation
Write-Host "`n=== To reset and regenerate orders, run this: ===" -ForegroundColor Magenta
Write-Host "DELETE FROM orders WHERE delivery_date = '$tomorrow';" -ForegroundColor White
