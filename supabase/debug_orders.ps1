# Debug why orders aren't being generated
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql, $desc)
    Write-Host "`n$desc" -ForegroundColor Yellow
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        if ($result) {
            $result | Format-Table | Out-String | Write-Host
        }
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "=== Debug Order Generation ===" -ForegroundColor Cyan

$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
Write-Host "`nTomorrow's date: $tomorrow" -ForegroundColor Cyan

# 1. Check active subscriptions
Invoke-SQL "SELECT id, user_id, product_id, plan_type, status, start_date, end_date, is_paused FROM subscriptions WHERE status = 'active';" "1. Active subscriptions:"

# 2. Check if end_date >= tomorrow
Invoke-SQL "SELECT id, end_date, '$tomorrow' as tomorrow, (end_date >= '$tomorrow') as is_valid FROM subscriptions WHERE status = 'active';" "2. Checking if end_date >= tomorrow:"

# 3. Check if orders already exist for tomorrow
Invoke-SQL "SELECT id, user_id, delivery_date, status FROM orders WHERE delivery_date = '$tomorrow';" "3. Existing orders for tomorrow:"

# 4. Check customer profiles with assignments
Invoke-SQL "SELECT id, full_name, assigned_delivery_person_id FROM profiles WHERE role = 'customer';" "4. Customer profiles with assignments:"

# 5. Check the subscriptions with profiles join
Invoke-SQL "SELECT s.id, s.user_id, p.full_name, p.assigned_delivery_person_id FROM subscriptions s LEFT JOIN profiles p ON s.user_id = p.id WHERE s.status = 'active';" "5. Subscriptions with profile info:"

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green
