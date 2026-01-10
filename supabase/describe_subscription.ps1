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
        Write-Host "--- Schema: public.subscriptions ---" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Invoke-SQL "
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'subscriptions' AND table_schema = 'public';
"
