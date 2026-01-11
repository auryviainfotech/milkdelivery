# Fix orders_status_check constraint to include payment_pending
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

Write-Host "=== Fixing Orders Status Constraint ===" -ForegroundColor Cyan

# Drop the old constraint
Invoke-SQL "ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;" "1. Dropping old constraint..."

# Add new constraint that includes payment_pending
Invoke-SQL "ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ('pending', 'payment_pending', 'assigned', 'in_transit', 'delivered', 'failed', 'cancelled'));" "2. Adding new constraint with more statuses..."

Write-Host "`n=== Done! Now try 'Generate Tomorrow's Orders' again ===" -ForegroundColor Green
