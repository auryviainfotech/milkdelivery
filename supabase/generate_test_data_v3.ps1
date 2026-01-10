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

Write-Host "Setting up test data for $email (Self-Delivery)..." -ForegroundColor Cyan

$today = Get-Date -Format "yyyy-MM-dd"
$userIdSubquery = "(SELECT id FROM auth.users WHERE email = '$email')"

# 1. Update Profile (Act as Customer + Delivery Person)
# We set phone and address so they appear in the app
Invoke-SQL "
UPDATE public.profiles 
SET 
    full_name = 'Test User (Self)',
    phone = '+919999999999',
    address = '123 Test Street, Demo Colony, Hyderabad',
    service_pin_codes = ARRAY['500001', '500002']
WHERE id IN (SELECT id FROM auth.users WHERE email = '$email');
"

# 2. Create Orders (User is Customer)
Invoke-SQL "
INSERT INTO public.orders (user_id, subscription_id, delivery_date, status, quantity, product_name, created_at)
VALUES 
($userIdSubquery, NULL, '$today', 'pending', 1, 'Full Cream Milk', now()),
($userIdSubquery, NULL, '$today', 'pending', 2, 'Buffalo Milk', now())
ON CONFLICT DO NOTHING;
"

# 3. Create Deliveries (User is Delivery Person)
# We link the orders we just made to the same user as delivery person
Invoke-SQL "
INSERT INTO public.deliveries (order_id, delivery_person_id, status, scheduled_date, created_at)
SELECT id, $userIdSubquery, 'pending', '$today', now()
FROM public.orders
WHERE delivery_date = '$today' 
  AND user_id = $userIdSubquery
  AND id NOT IN (SELECT order_id FROM public.deliveries)
ON CONFLICT DO NOTHING;
"

Write-Host "Done! Please refresh the Delivery App Dashboard." -ForegroundColor Green
