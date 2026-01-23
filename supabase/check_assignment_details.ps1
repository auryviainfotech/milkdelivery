$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== ADMIN DIAGNOSTIC CHECK: $today ===" -ForegroundColor Cyan

# 1. List ALL orders/deliveries for today with details
$sql = "SELECT d.id as delivery_id, d.scheduled_date, d.delivery_person_id, p.full_name as assigned_name, o.id as order_id, sub.user_id, cust.full_name as customer_name FROM public.deliveries d LEFT JOIN public.orders o ON d.order_id = o.id LEFT JOIN public.subscriptions sub ON o.subscription_id = sub.id LEFT JOIN public.profiles cust ON sub.user_id = cust.id LEFT JOIN public.profiles p ON d.delivery_person_id = p.id WHERE d.scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json

try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    if ($result -and $result.Count -gt 0) {
        Write-Host "Found $($result.Count) DELIVERIES for TODAY:" -ForegroundColor Green
        $result | ForEach-Object {
            Write-Host "  --------------------------------------------------"
            Write-Host "  Delivery ID: $($_.delivery_id)"
            Write-Host "  Assigned To: $($_.assigned_name) (ID: $($_.delivery_person_id))"
            Write-Host "  Customer:    $($_.customer_name)"
            
            if (-not $_.delivery_person_id) {
                Write-Host "  WARNING: UNASSIGNED!" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  NO DELIVERIES FOUND FOR TODAY!" -ForegroundColor Red
    }

} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

Write-Host "`n=== END DIAGNOSTIC ===" -ForegroundColor Cyan
