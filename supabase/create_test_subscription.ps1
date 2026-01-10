$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$uuid = "afb19c4f-e23f-4a0e-8fb4-eeaf8abacc3e" # mdt01569@gmail.com
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

Write-Host "Setting up Test Subscription for PIN 500001..." -ForegroundColor Cyan

# 1. Update Profile Address to have PIN 500001
Invoke-SQL "
UPDATE public.profiles 
SET address = 'Flat 101, Test Appt, Hyderabad 500001',
    full_name = 'Test Customer (Admin)'
WHERE id = '$uuid';
"

# 2. Create Active Subscription
Invoke-SQL "
INSERT INTO public.subscriptions (user_id, product_id, plan_type, quantity, start_date, end_date, formatted_time, total_amount, status)
VALUES 
('$uuid', '1', 'daily', 2, '$today', '$nextMonth', '07:00 AM - 08:00 AM', 3000, 'active');
"

Write-Host "Done! Refresh 'Subscriptions' in Admin Panel to see it." -ForegroundColor Green
