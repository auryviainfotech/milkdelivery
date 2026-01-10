$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$uuid = "afb19c4f-e23f-4a0e-8fb4-eeaf8abacc3e"
$today = Get-Date -Format "yyyy-MM-dd"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS: SQL executed" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "Creating orders for UUID $uuid..." -ForegroundColor Cyan

# 1. Create SIMPLE Order
Invoke-SQL "
INSERT INTO public.orders (user_id, subscription_id, delivery_date, status, quantity, product_name, created_at)
VALUES 
('$uuid', NULL, '$today', 'pending', 1, 'Full Cream Milk', now()),
('$uuid', NULL, '$today', 'pending', 2, 'Toned Milk', now())
ON CONFLICT DO NOTHING;
"

# 2. Create Deliveries linked to these orders
Invoke-SQL "
INSERT INTO public.deliveries (order_id, delivery_person_id, status, scheduled_date, created_at)
SELECT id, '$uuid', 'pending', '$today', now()
FROM public.orders
WHERE delivery_date = '$today' 
  AND user_id = '$uuid'
  AND id NOT IN (SELECT order_id FROM public.deliveries)
ON CONFLICT DO NOTHING;
"

Write-Host "Done! Data should be there." -ForegroundColor Green
