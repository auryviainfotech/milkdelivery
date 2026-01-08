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
        Write-Host "SUCCESS: $($sql.Substring(0, [Math]::Min(50, $sql.Length)))..." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "=== Adding missing columns to subscriptions table ===" -ForegroundColor Cyan

Invoke-SQL "ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS product_id VARCHAR(50);"
Invoke-SQL "ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS plan_type VARCHAR(20);"
Invoke-SQL "ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);"

Write-Host "`n=== Making phone column nullable ===" -ForegroundColor Cyan

Invoke-SQL "ALTER TABLE profiles ALTER COLUMN phone DROP NOT NULL;"

Write-Host "`n=== Done! ===" -ForegroundColor Green
