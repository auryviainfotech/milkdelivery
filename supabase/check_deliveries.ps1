$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql, $title)
    Write-Host "`n=== $title ===" -ForegroundColor Cyan
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        if ($result -is [array] -and $result.Count -gt 0) {
            $result | Format-Table -AutoSize
        } elseif ($result) {
            $result | ConvertTo-Json -Depth 5
        } else {
            Write-Host "No results" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

# Check delivery persons (role = 'delivery')
Invoke-SQL "SELECT id, full_name, role FROM public.profiles WHERE role = 'delivery';" "Delivery Persons"

# Check today's date
$today = Get-Date -Format "yyyy-MM-dd"
Write-Host "`nToday's date: $today" -ForegroundColor Green

# Check all deliveries
Invoke-SQL "SELECT id, order_id, delivery_person_id, scheduled_date, status FROM public.deliveries ORDER BY scheduled_date DESC LIMIT 20;" "Recent Deliveries (all)"

# Check deliveries for today
Invoke-SQL "SELECT d.id, d.delivery_person_id, d.scheduled_date, d.status, p.full_name as delivery_person_name FROM public.deliveries d LEFT JOIN public.profiles p ON d.delivery_person_id = p.id WHERE d.scheduled_date = '$today';" "Today's Deliveries"

# Check customers with assigned delivery persons
Invoke-SQL "SELECT id, full_name, assigned_delivery_person_id FROM public.profiles WHERE role = 'customer' AND assigned_delivery_person_id IS NOT NULL LIMIT 10;" "Customers with Assignments"

# Check orders for today
Invoke-SQL "SELECT id, user_id, subscription_id, delivery_date, status FROM public.orders WHERE delivery_date = '$today' LIMIT 10;" "Today's Orders"

Write-Host "`n=== DONE ===" -ForegroundColor Green
