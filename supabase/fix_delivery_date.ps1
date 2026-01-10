$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$today = Get-Date -Format "yyyy-MM-dd"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "Updating delivery date to TODAY ($today)..." -ForegroundColor Cyan
Invoke-SQL "UPDATE public.deliveries SET scheduled_date = '$today';"
Invoke-SQL "UPDATE public.orders SET delivery_date = '$today';"
Write-Host "Done! Please refresh the Delivery App." -ForegroundColor Green
