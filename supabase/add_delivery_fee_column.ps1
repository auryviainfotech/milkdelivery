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
        if ($_.Exception.Response) {
             $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
             $reader.ReadToEnd()
        }
    }
}

Write-Host "Adding delivery_fee column to subscriptions table..." -ForegroundColor Yellow
Invoke-SQL "ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10, 2) DEFAULT 0.00;"

Write-Host "Verifying schema..."
Invoke-SQL "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'subscriptions' AND column_name = 'delivery_fee';"
