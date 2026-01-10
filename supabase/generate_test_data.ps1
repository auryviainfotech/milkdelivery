$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "Please enter the Delivery Person's EMAIL (the one you are logged in with in Delivery App):" -ForegroundColor Yellow
$deliveryEmail = Read-Host

if ([string]::IsNullOrWhiteSpace($deliveryEmail)) {
    Write-Host "Email is required!" -ForegroundColor Red
    exit
}

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "Setting up test data for $deliveryEmail..." -ForegroundColor Cyan

# 1. Ensure Delivery Person Profile Exists & set PIN codes
Invoke-SQL "
UPDATE public.profiles 
SET role = 'delivery_partner',
    service_pin_codes = ARRAY['500001', '500002']
WHERE id IN (SELECT id FROM auth.users WHERE email = '$deliveryEmail');
"

# 2. Create Test Customers
Invoke-SQL "
-- Insert generic user row if needed (a bit tricky with auth.users, so we will use existing profiles or just mock order data linked to a dummy profile if possible, but orders link to profiles).
-- BETTER APPROACH: We'll create a dummy customer profile linked to the SAME user for simplicity, OR rely on an existing customer.
-- Let's create a fake customer profile row with a random UUID if it doesn't exist.
INSERT INTO public.profiles (id, full_name, role, phone, address, service_pin_codes)
VALUES 
('d0c2c2e0-0000-0000-0000-000000000001', 'Ravi Kumar', 'customer', '+919876543210', 'Flat 101, Sunshine Apts, MG Road, Hyderabad', NULL),
('d0c2c2e0-0000-0000-0000-000000000002', 'Anita Singh', 'customer', '+919988776655', 'House 45, Green Park Colony, Hyderabad', NULL)
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
"

# 3. Create Deliveries for Today (linked to the delivery person)
$today = Get-Date -Format "yyyy-MM-dd"
$deliveryPersonIdSubquery = "(SELECT id FROM auth.users WHERE email = '$deliveryEmail')"

Invoke-SQL "
-- Create Mock Order 1
WITH new_order AS (
    INSERT INTO public.orders (user_id, subscription_id, delivery_date, status, quantity, product_name)
    VALUES ('d0c2c2e0-0000-0000-0000-000000000001', NULL, '$today', 'pending', 1, 'Full Cream Milk')
    RETURNING id
)
INSERT INTO public.deliveries (order_id, delivery_person_id, status, scheduled_date)
SELECT id, $deliveryPersonIdSubquery, 'pending', '$today'
FROM new_order;

-- Create Mock Order 2
WITH new_order_2 AS (
    INSERT INTO public.orders (user_id, subscription_id, delivery_date, status, quantity, product_name)
    VALUES ('d0c2c2e0-0000-0000-0000-000000000002', NULL, '$today', 'pending', 2, 'Toned Milk')
    RETURNING id
)
INSERT INTO public.deliveries (order_id, delivery_person_id, status, scheduled_date)
SELECT id, $deliveryPersonIdSubquery, 'pending', '$today'
FROM new_order_2;
"

Write-Host "Done! Please refresh the Delivery App Dashboard." -ForegroundColor Green
