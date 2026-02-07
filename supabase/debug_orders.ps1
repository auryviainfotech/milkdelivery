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
        # Check if result is empty or has error
        if ($result -is [System.Management.Automation.PSCustomObject]) {
             # It might return headers/rows depending on API, but usually direct JSON for select? 
             # Actually Supabase SQL API returns CSV or JSON depending on format, 
             # but here we are using the pg_rest-like or just raw query? 
             # Wait, the previous script suggests it works. Let's dump output.
             Write-Host ($result | ConvertTo-Json -Depth 5)
        } else {
             Write-Host $result
        }
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "--- RECENT ORDERS (Last 5) ---" -ForegroundColor Cyan
Invoke-SQL "
SELECT id, user_id, delivery_date, status, order_type, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 5;
"

Write-Host "`n--- RECENT DELIVERIES (Last 5) ---" -ForegroundColor Cyan
Invoke-SQL "
SELECT id, order_id, delivery_person_id, scheduled_date, status 
FROM deliveries 
ORDER BY created_at DESC 
LIMIT 5;
"

Write-Host "`n--- DELIVERY PERSONNEL (Profiles) ---" -ForegroundColor Cyan
Invoke-SQL "
SELECT id, full_name, role 
FROM profiles 
WHERE role = 'delivery';
"
