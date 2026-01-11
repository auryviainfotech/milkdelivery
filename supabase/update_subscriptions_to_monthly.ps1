# Update all daily/weekly subscriptions to monthly
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
        Write-Host "SUCCESS: $sql" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "=== Updating Test Subscriptions to Monthly ===" -ForegroundColor Cyan

# First, let's see what subscriptions exist
Write-Host "`nChecking current subscriptions..." -ForegroundColor Yellow
Invoke-SQL "SELECT id, user_id, plan_type, status FROM public.subscriptions;"

# Update all daily subscriptions to monthly
Write-Host "`nUpdating 'daily' subscriptions to 'monthly'..." -ForegroundColor Yellow
Invoke-SQL "UPDATE public.subscriptions SET plan_type = 'monthly' WHERE plan_type = 'daily';"

# Update all weekly subscriptions to monthly  
Write-Host "`nUpdating 'weekly' subscriptions to 'monthly'..." -ForegroundColor Yellow
Invoke-SQL "UPDATE public.subscriptions SET plan_type = 'monthly' WHERE plan_type = 'weekly';"

# Verify the changes
Write-Host "`nVerifying updated subscriptions..." -ForegroundColor Yellow
Invoke-SQL "SELECT id, user_id, plan_type, status FROM public.subscriptions;"

Write-Host "`n=== Done! All subscriptions are now monthly. ===" -ForegroundColor Green
