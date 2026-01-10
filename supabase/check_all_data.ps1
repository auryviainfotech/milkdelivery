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
        $result | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "--- 1. Subscriptions ---" -ForegroundColor Cyan
Invoke-SQL "SELECT id, status, plan_type FROM public.subscriptions;"

Write-Host "`n--- 2. Orders (Tomorrow) ---" -ForegroundColor Cyan
Invoke-SQL "SELECT id, status, delivery_date FROM public.orders ORDER BY created_at DESC;"

Write-Host "`n--- 3. Deliveries ---" -ForegroundColor Cyan
Invoke-SQL "SELECT id, status, delivery_person_id, scheduled_date FROM public.deliveries ORDER BY created_at DESC;"
