$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"
$bilalId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"

Write-Host "=== TESTING JOIN QUERY ===" -ForegroundColor Cyan

# Test the exact query the app uses
$sql = @"
SELECT 
    d.*,
    o.id as order_id,
    o.user_id,
    o.subscription_id,
    s.delivery_slot,
    s.product_id,
    s.quantity,
    p.name as product_name,
    p.unit,
    prof.full_name as customer_name,
    prof.phone as customer_phone,
    prof.address as customer_address
FROM public.deliveries d
LEFT JOIN public.orders o ON d.order_id = o.id
LEFT JOIN public.subscriptions s ON o.subscription_id = s.id
LEFT JOIN public.products p ON s.product_id = p.id
LEFT JOIN public.profiles prof ON o.user_id = prof.id
WHERE d.delivery_person_id = '$bilalId'
AND d.scheduled_date = '$today';
"@

$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($result) {
    Write-Host "Found delivery with JOIN data:" -ForegroundColor Green
    Write-Host "  Customer:   $($result.customer_name)"
    Write-Host "  Phone:      $($result.customer_phone)"
    Write-Host "  Address:    $($result.customer_address)"
    Write-Host "  Product:    $($result.product_name)"
    Write-Host "  Quantity:   $($result.quantity)"
    Write-Host "  Slot:       $($result.delivery_slot)"
} else {
    Write-Host "No results!" -ForegroundColor Red
}
