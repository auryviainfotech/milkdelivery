$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$uuid = "afb19c4f-e23f-4a0e-8fb4-eeaf8abacc3e"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS: Executed SQL" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "Cleaning up test data for $uuid..." -ForegroundColor Cyan

# 1. Delete Deliveries
Invoke-SQL "
DELETE FROM public.deliveries 
WHERE delivery_person_id = '$uuid' 
   OR order_id IN (SELECT id FROM public.orders WHERE user_id = '$uuid');
"

# 2. Delete Orders
Invoke-SQL "
DELETE FROM public.orders 
WHERE user_id = '$uuid';
"

Write-Host "Cleanup Complete!" -ForegroundColor Green
