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
        Write-Host "--- Query Result ---" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "1. Checking Products..." -ForegroundColor Yellow
Invoke-SQL "SELECT id, name FROM public.products;"

Write-Host "`n2. Checking Subscriptions..." -ForegroundColor Yellow
Invoke-SQL "SELECT * FROM public.subscriptions;"
