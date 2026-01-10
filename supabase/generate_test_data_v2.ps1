$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$email = "mdt01569@gmail.com"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS: Executed SQL chunk" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "Setting up test data for $email..." -ForegroundColor Cyan

# 1. Update Delivery Person Profile (add role and pin codes)
# Note: Keeping role as 'admin' if it is already admin, just ensuring pin/role is set for delivery logic
Invoke-SQL "
UPDATE public.profiles 
SET service_pin_codes = ARRAY['500001', '500002']
WHERE id IN (SELECT id FROM auth.users WHERE email = '$email');
"

# 2. Create Test Customers
Invoke-SQL "
INSERT INTO public.profiles (id, full_name, role, phone, address, created_at)
VALUES 
('d0c2c2e0-0000-0000-0000-000000000001', 'Ravi Kumar', 'customer', '+919876543210', 'Flat 101, Sunshine Apts, MG Road, Hyderabad', now()),
('d0c2c2e0-0000-0000-0000-000000000002', 'Anita Singh', 'customer', '+919988776655', 'House 45, Green Park Colony, Hyderabad', now())
ON CONFLICT (id) DO UPDATE SET 
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    address = EXCLUDED.address;
"

# 3. Create Orders (Standard INSERT)
$today = Get-Date -Format "yyyy-MM-dd"
$deliveryPersonId = "(SELECT id FROM auth.users WHERE email = '$email')"

Invoke-SQL "
INSERT INTO public.orders (user_id, subscription_id, delivery_date, status, quantity, product_name, created_at)
VALUES 
('d0c2c2e0-0000-0000-0000-000000000001', NULL, '$today', 'pending', 1, 'Full Cream Milk', now()),
('d0c2c2e0-0000-0000-0000-000000000002', NULL, '$today', 'pending', 2, 'Toned Milk', now())
ON CONFLICT DO NOTHING;
"

# 4. Create Deliveries link to Orders
# We need the order IDs. Since we can't easily capture RETURNING id in this API wrapper without parsing, 
# we'll select the orders we just created based on user_id and date.

Invoke-SQL "
INSERT INTO public.deliveries (order_id, delivery_person_id, status, scheduled_date, created_at)
SELECT id, $deliveryPersonId, 'pending', '$today', now()
FROM public.orders
WHERE delivery_date = '$today' 
  AND user_id IN ('d0c2c2e0-0000-0000-0000-000000000001', 'd0c2c2e0-0000-0000-0000-000000000002')
  AND id NOT IN (SELECT order_id FROM public.deliveries)
ON CONFLICT DO NOTHING;
"

Write-Host "Done! Please refresh the Delivery App Dashboard." -ForegroundColor Green
