$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$uuid = "afb19c4f-e23f-4a0e-8fb4-eeaf8abacc3e" # Auth User ID
$validProductId = "73150fbb-6753-4b43-889e-f4c97bb5c2ce"
$today = Get-Date -Format "yyyy-MM-dd"
$nextMonth = (Get-Date).AddMonths(1).ToString("yyyy-MM-dd")

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

Write-Host "Creating Test Subscription (Attempt 3)..." -ForegroundColor Cyan

# 1. Cleaning up
Invoke-SQL "DELETE FROM public.subscriptions WHERE user_id = '$uuid';"

# 2. Insert (without formatted_time)
# Also using a fake plan_id if possibly non-nullable? uuid default might handle it.
# Check if plan_id is nullable? Usually yes.
# We skip plan_id in Insert.
Invoke-SQL "
INSERT INTO public.subscriptions (user_id, product_id, plan_type, quantity, start_date, end_date, total_amount, status)
VALUES 
('$uuid', '$validProductId', 'daily', 2, '$today', '$nextMonth', 3000, 'active');
"

Write-Host "Done! PLEASE work." -ForegroundColor Green
