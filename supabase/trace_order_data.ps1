$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$personId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== DATA TRACE FOR $today ===" -ForegroundColor Cyan

# 1. Get Delivery and Order ID
$sql = "SELECT id, order_id, delivery_person_id FROM public.deliveries WHERE delivery_person_id = '$personId' AND scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$d = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($d -and $d.id) {
    Write-Host "Delivery Found: $($d.id)" -ForegroundColor Green
    Write-Host "  Order ID: $($d.order_id)"
    
    $valOrderId = $d.order_id
    
    # 2. Get Order and Subscription ID
    $sql = "SELECT id, subscription_id, user_id FROM public.orders WHERE id = '$valOrderId';"
    $body = @{ query = $sql } | ConvertTo-Json
    $o = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    if ($o -and $o.id) {
        Write-Host "  Order Found: $($o.id)" -ForegroundColor Green
        Write-Host "    Subscription ID: $($o.subscription_id)"
        Write-Host "    User ID: $($o.user_id)"
        
        $valSubId = $o.subscription_id
        
        if ($valSubId) {
            # 3. Get Subscription and Product ID
            $sql = "SELECT id, product_id FROM public.subscriptions WHERE id = '$valSubId';"
            $body = @{ query = $sql } | ConvertTo-Json
            $s = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
            
            if ($s -and $s.id) {
                Write-Host "    Subscription Found: $($s.id)" -ForegroundColor Green
                Write-Host "      Product ID: $($s.product_id)"
                
                $valProdId = $s.product_id
                
                # 4. Get Product
                $sql = "SELECT id, name FROM public.products WHERE id = '$valProdId';"
                $body = @{ query = $sql } | ConvertTo-Json
                $p = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
                
                if ($p -and $p.id) {
                    Write-Host "      Product Found: $($p.name)" -ForegroundColor Green
                } else {
                    Write-Host "      ERROR: Product NOT found!" -ForegroundColor Red
                }
            } else {
                Write-Host "    ERROR: Subscription NOT found in DB!" -ForegroundColor Red
            }
        } else {
            Write-Host "    ERROR: Order has no subscription_id!" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERROR: Order NOT found in DB!" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: No Delivery Found for bilal today" -ForegroundColor Red
}
