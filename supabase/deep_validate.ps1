# Deep validate a single delivery chain
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
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $null
    }
}

$targetDate = "2026-01-23"

Write-Host "=== DEEP DATA VALIDATION for $targetDate ===" -ForegroundColor Cyan

# 1. Get the Delivery
$delivery = Invoke-SQL "SELECT * FROM deliveries WHERE scheduled_date = '$targetDate' LIMIT 1;"
if (!$delivery) {
    Write-Host "FATAL: No delivery found for $targetDate!" -ForegroundColor Red
    exit
}
Write-Host "1. Delivery Found: $($delivery.id)" -ForegroundColor Green
Write-Host "   - Person ID: $($delivery.delivery_person_id)"
Write-Host "   - Order ID: $($delivery.order_id)"

# 2. Check Order
$order = Invoke-SQL "SELECT * FROM orders WHERE id = '$($delivery.order_id)';"
if (!$order) {
    Write-Host "FATAL: Delivery refers to non-existent Order ID!" -ForegroundColor Red
} else {
    Write-Host "2. Order Found: $($order.id)" -ForegroundColor Green
    Write-Host "   - User ID (Customer): $($order.user_id)"
    Write-Host "   - Subscription ID: $($order.subscription_id)"
}

# 3. Check Subscription
if ($order.subscription_id) {
    $sub = Invoke-SQL "SELECT * FROM subscriptions WHERE id = '$($order.subscription_id)';"
    if (!$sub) {
        Write-Host "FATAL: Order refers to non-existent Subscription!" -ForegroundColor Red
    } else {
        Write-Host "3. Subscription Found: $($sub.id)" -ForegroundColor Green
        Write-Host "   - Product ID: $($sub.product_id)"
    }
}

# 4. Check Product
if ($sub.product_id) {
    $prod = Invoke-SQL "SELECT * FROM products WHERE id = '$($sub.product_id)';"
    if (!$prod) {
        Write-Host "FATAL: Subscription refers to non-existent Product!" -ForegroundColor Red
    } else {
        Write-Host "4. Product Found: $($prod.name)" -ForegroundColor Green
    }
}

# 5. Check Customer Profile (Crucial for Dashboard JOIN)
if ($order.user_id) {
    $profile = Invoke-SQL "SELECT * FROM profiles WHERE id = '$($order.user_id)';"
    if (!$profile) {
        Write-Host "FATAL: Order User ID not found in PROFILES table!" -ForegroundColor Red
        Write-Host "   (This will cause the dashboard JOIN to fail if inner joined, or return null profile)"
    } else {
        Write-Host "5. Customer Profile Found: $($profile.full_name)" -ForegroundColor Green
    }
}

# 6. Check Delivery Person Profile
if ($delivery.delivery_person_id) {
    $dp = Invoke-SQL "SELECT * FROM profiles WHERE id = '$($delivery.delivery_person_id)';"
    if (!$dp) {
        Write-Host "FATAL: Delivery Person ID not found in PROFILES table!" -ForegroundColor Red
    } else {
        Write-Host "6. Delivery Person Profile Found: $($dp.full_name)" -ForegroundColor Green
    }
}

Write-Host "=== VALIDATION COMPLETE ===" -ForegroundColor Cyan
