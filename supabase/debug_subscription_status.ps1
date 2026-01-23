$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== SUBSCRIPTION DIAGNOSTIC: $today ===" -ForegroundColor Cyan

# 1. Fetch Subscription Details
$sql = "SELECT s.*, p.full_name FROM public.subscriptions s JOIN public.profiles p ON s.user_id = p.id WHERE p.full_name ILIKE '%hafsiya%';"
$body = @{ query = $sql } | ConvertTo-Json
$sub = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if (-not $sub) {
    Write-Host "ERROR: No subscription found for Hafsiya!" -ForegroundColor Red
    exit
}

Write-Host "Found Subscription for $($sub.full_name):" -ForegroundColor Green
Write-Host "  ID:       $($sub.id)"
Write-Host "  Status:   $($sub.status)"
Write-Host "  Start:    $($sub.start_date)"
Write-Host "  End:      $($sub.end_date)"
Write-Host "  Slot:     $($sub.delivery_slot)"
Write-Host "  User ID:  $($sub.user_id)"

# 2. Check for EXISTING Orders Today
Write-Host "`nChecking for Orders Today ($today):" -ForegroundColor Yellow
$sql = "SELECT * FROM public.orders WHERE subscription_id = '$($sub.id)' AND delivery_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$order = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($order) {
    Write-Host "  [FOUND] Order already exists!" -ForegroundColor Red
    Write-Host "  Order ID: $($order.id)"
    Write-Host "  Status:   $($order.status)"
    Write-Host "  Usage:    Order generation skips if order already exists (Idempotent)." -ForegroundColor Gray
} else {
    Write-Host "  [MISSING] No order found for today." -ForegroundColor Yellow
}

# 3. Check for Deliveries
if ($order) {
    $sql = "SELECT * FROM public.deliveries WHERE order_id = '$($order.id)';"
    $body = @{ query = $sql } | ConvertTo-Json
    $del = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    if ($del) {
        Write-Host "  [FOUND] Delivery exists: $($del.id)" -ForegroundColor Green
        Write-Host "  Person: $($del.delivery_person_id)"
    } else {
        Write-Host "  [MISSING] Order exists but NO DELIVERY created!" -ForegroundColor Red
    }
}
