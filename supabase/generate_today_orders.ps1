$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"
$bilalId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"

Write-Host "=== GENERATING ORDERS FOR TODAY: $today ===" -ForegroundColor Cyan

# 1. Get Active Subscriptions
Write-Host "1. Fetching active subscriptions..." -ForegroundColor Yellow
$sql = "SELECT s.id, s.user_id, s.product_id, s.quantity, s.delivery_slot, p.assigned_delivery_person_id, p.full_name as customer_name FROM public.subscriptions s JOIN public.profiles p ON s.user_id = p.id WHERE s.status = 'active';"
$body = @{ query = $sql } | ConvertTo-Json
$subs = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if (-not $subs) { 
    Write-Host "No active subscriptions found!" -ForegroundColor Red
    exit 
}

Write-Host "Found $($subs.Count) active subscriptions." -ForegroundColor Green

# 2. Loop and Create Orders/Deliveries
foreach ($sub in $subs) {
    if (-not $sub.product_id) { continue }
    
    $userId = $sub.user_id
    $subId = $sub.id
    $assignedDp = if ($sub.assigned_delivery_person_id) { $sub.assigned_delivery_person_id } else { $bilalId } # Default to Bilal if unassigned
    
    Write-Host "Processing subscription for $($sub.customer_name)..." 
    
    # Check if order already exists
    $checkSql = "SELECT id FROM public.orders WHERE subscription_id = '$subId' AND delivery_date = '$today';"
    $body = @{ query = $checkSql } | ConvertTo-Json
    $exists = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    if ($exists) {
        Write-Host "  Order already exists." -ForegroundColor Gray
        continue
    }

    # Create Order
    $insertOrderSql = "INSERT INTO public.orders (user_id, subscription_id, delivery_date, status) VALUES ('$userId', '$subId', '$today', 'pending') RETURNING id;"
    $body = @{ query = $insertOrderSql } | ConvertTo-Json
    $newOrder = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    $orderId = $newOrder.id
    
    Write-Host "  Created Order: $orderId" -ForegroundColor Green
    
    # Create Delivery
    $insertDelSql = "INSERT INTO public.deliveries (order_id, delivery_person_id, scheduled_date, status) VALUES ('$orderId', '$assignedDp', '$today', 'pending') RETURNING id;"
    $body = @{ query = $insertDelSql } | ConvertTo-Json
    try {
        $newDel = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "  Created Delivery: $($newDel.id) -> Assigned to: $assignedDp" -ForegroundColor Green
    } catch {
        Write-Host "  Error creating delivery: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "Orders generated. Please refresh the Delivery App."
