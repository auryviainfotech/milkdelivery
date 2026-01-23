$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== COMPLETE FLOW TRACE ===" -ForegroundColor Cyan
Write-Host "Date: $today" -ForegroundColor Yellow

# 1. Get today's delivery
Write-Host "`n1. Today's Delivery:" -ForegroundColor Yellow
$sql = "SELECT d.id, d.order_id, d.delivery_person_id, d.status FROM public.deliveries d WHERE d.scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$delivery = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($delivery) {
    Write-Host "  Delivery exists: $($delivery.id)"
    Write-Host "  delivery_person_id: $($delivery.delivery_person_id)" -ForegroundColor Green
    $orderId = $delivery.order_id
    $dpId = $delivery.delivery_person_id
} else {
    Write-Host "  NO DELIVERY FOR TODAY!" -ForegroundColor Red
    exit
}

# 2. Get the order to find customer
Write-Host "`n2. Order for this delivery:" -ForegroundColor Yellow
$sql = "SELECT id, user_id, subscription_id FROM public.orders WHERE id = '$orderId';"
$body = @{ query = $sql } | ConvertTo-Json
$order = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($order) {
    Write-Host "  Order ID: $($order.id)"
    Write-Host "  Customer (user_id): $($order.user_id)"
    $customerId = $order.user_id
} else {
    Write-Host "  Order not found!" -ForegroundColor Red
    exit
}

# 3. Check customer's assigned_delivery_person_id
Write-Host "`n3. Customer's Profile (assigned_delivery_person_id):" -ForegroundColor Yellow
$sql = "SELECT id, full_name, assigned_delivery_person_id FROM public.profiles WHERE id = '$customerId';"
$body = @{ query = $sql } | ConvertTo-Json
$customer = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($customer) {
    Write-Host "  Customer: $($customer.full_name)"
    Write-Host "  assigned_delivery_person_id: $($customer.assigned_delivery_person_id)" -ForegroundColor $(if ($customer.assigned_delivery_person_id) { "Green" } else { "Red" })
} else {
    Write-Host "  Customer profile not found!" -ForegroundColor Red
}

# 4. Check delivery person profile
Write-Host "`n4. Delivery Person Profile:" -ForegroundColor Yellow
if ($dpId) {
    $sql = "SELECT id, full_name, phone, role FROM public.profiles WHERE id = '$dpId';"
    $body = @{ query = $sql } | ConvertTo-Json
    $dp = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($dp) {
        Write-Host "  Name: $($dp.full_name)"
        Write-Host "  Phone: $($dp.phone)"
        Write-Host "  Role: $($dp.role)"
        Write-Host "  ID: $($dp.id)" -ForegroundColor Green
    }
} else {
    Write-Host "  delivery_person_id is NULL - Customer not assigned!" -ForegroundColor Red
}

# 5. Check all delivery persons
Write-Host "`n5. ALL Delivery Persons in System:" -ForegroundColor Yellow
$sql = "SELECT id, full_name, phone FROM public.profiles WHERE role = 'delivery';"
$body = @{ query = $sql } | ConvertTo-Json
$allDp = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
$allDp | ForEach-Object {
    Write-Host "  - $($_.full_name) | Phone: $($_.phone) | ID: $($_.id)"
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Magenta
if ($dpId) {
    Write-Host "Delivery is assigned to: $dpId"
    Write-Host "To see this delivery in app, login with phone number of the delivery person above."
} else {
    Write-Host "Delivery has no delivery_person_id - GO TO ADMIN -> ASSIGNMENTS -> ASSIGN CUSTOMER FIRST!"
}
