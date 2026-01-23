# Check Order Counts and Assignments Simplified
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

$targetDate = "2026-01-23"

Write-Host "--- DEBUG INFO ---"

# 1. Get Bilal's ID
$bilal = Invoke-SQL "SELECT id, full_name FROM profiles WHERE role = 'delivery' AND full_name LIKE '%bilal%' LIMIT 1;"
if ($bilal.Count -gt 0) {
    Write-Host "Bilal ID: $($bilal[0].id)"
} else {
    Write-Host "Bilal NOT FOUND in profiles"
}

# 2. Count Orders
$orders = Invoke-SQL "SELECT count(*) as cnt FROM orders WHERE delivery_date = '$targetDate';"
Write-Host "Total Orders for Tomorrow: $($orders[0].cnt)"

# 3. Group Deliveries by Person
Write-Host "Deliveries by Person ID:"
$grouped = Invoke-SQL "SELECT delivery_person_id, count(*) as cnt FROM deliveries WHERE scheduled_date = '$targetDate' GROUP BY delivery_person_id;"
$grouped | Format-Table

Write-Host "--- END DEBUG ---"
