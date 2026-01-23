$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

# Delivery person ID (bilal)
$personId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== DEBUG: SIMULATING APP QUERY ===" -ForegroundColor Cyan
Write-Host "Person ID: $personId"
Write-Host "Date: $today"

# 1. Test SIMPLE query (just deliveries)
Write-Host "`n1. Simple Query (deliveries only)..." -ForegroundColor Yellow
$sql = "SELECT id, scheduled_date, status, delivery_person_id FROM public.deliveries WHERE delivery_person_id = '$personId' AND scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($result -and $result.Count -gt 0) {
    Write-Host "  FOUND $($result.Count) deliveries." -ForegroundColor Green
    $result | ForEach-Object { Write-Host "  - ID: $($_.id)" }
} else {
    Write-Host "  NO RESULT from simple query!" -ForegroundColor Red
}

# 2. Test JOIN order (deliveries + orders)
# Simulating: deliveries.select(*, orders!inner(*))
Write-Host "`n2. Join Query (deliveries + orders!inner)..." -ForegroundColor Yellow
$sql = "SELECT d.id, d.status, o.id as order_id, o.user_id FROM public.deliveries d INNER JOIN public.orders o ON d.order_id = o.id WHERE d.delivery_person_id = '$personId' AND d.scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($result -and $result.Count -gt 0) {
        Write-Host "  FOUND $($result.Count) joined rows." -ForegroundColor Green
        $result | ForEach-Object { Write-Host "  - Delivery: $($_.id) -> Order: $($_.order_id)" }
    } else {
        Write-Host "  NO RESULT from join query! (Order join failed)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# 3. Test FULL chain (deliveries + orders + profiles + subscriptions + products)
# Simulating the app's full nested select is hard with raw SQL in this script but we can check the pieces
Write-Host "`n3. Checking Relationships for the found delivery..." -ForegroundColor Yellow

# Get delivery and order ID
$sql = "SELECT id, order_id from public.deliveries WHERE delivery_person_id = '$personId' AND scheduled_date = '$today' LIMIT 1;"
$body = @{ query = $sql } | ConvertTo-Json
$d = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($d) {
    $orderId = $d.order_id
    Write-Host "  Using Order ID: $orderId"
    
    # Check Order -> Profile (Customer)
    $sql = "SELECT o.user_id, p.full_name FROM public.orders o LEFT JOIN public.profiles p ON o.user_id = p.id WHERE o.id = '$orderId';"
    $body = @{ query = $sql } | ConvertTo-Json
    $op = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($op.full_name) {
        Write-Host "    Customer: $($op.full_name) (OK)" -ForegroundColor Green
    } else {
        Write-Host "    Customer: NOT FOUND or JOIN FAILED (User ID: $($op.user_id))" -ForegroundColor Red
    }

    # Check Order -> Subscription -> Product
    $sql = "SELECT o.subscription_id, s.product_id, pr.name FROM public.orders o LEFT JOIN public.subscriptions s ON o.subscription_id = s.id LEFT JOIN public.products pr ON s.product_id = pr.id WHERE o.id = '$orderId';"
    $body = @{ query = $sql } | ConvertTo-Json
    $osp = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($osp.name) {
        Write-Host "    Product: $($osp.name) (OK)" -ForegroundColor Green
    } else {
        Write-Host "    Product: NOT FOUND or JOIN FAILED (Sub ID: $($osp.subscription_id), Prod ID: $($osp.product_id))" -ForegroundColor Red
    }
} else {
    Write-Host "  Cannot check relationships (No delivery found)" -ForegroundColor Red
}

Write-Host "`n=== END ===" -ForegroundColor Cyan
