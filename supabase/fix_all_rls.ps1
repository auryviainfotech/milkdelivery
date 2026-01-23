$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== FIXING RLS FOR DELIVERY ROLE ON ALL TABLES ===" -ForegroundColor Cyan

$sql = @"
-- 1. ORDERS: Ensure delivery persons can read all orders (or at least assigned ones)
-- For simplicity, we'll allow delivery role to read ALL orders.
DROP POLICY IF EXISTS orders_delivery_select ON public.orders;
CREATE POLICY orders_delivery_select ON public.orders
    FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'delivery')
        OR
        user_id = auth.uid() -- keep owner access
        OR
        EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
    );

-- 2. SUBSCRIPTIONS: Allow delivery to read subscriptions (needed for slot, quantity)
DROP POLICY IF EXISTS subscriptions_delivery_select ON public.subscriptions;
CREATE POLICY subscriptions_delivery_select ON public.subscriptions
    FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'delivery')
        OR
        user_id = auth.uid()
        OR
        EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
    );

-- 3. PROFILES: Allow delivery to read customer profiles (name, phone, address)
DROP POLICY IF EXISTS profiles_delivery_read_customers ON public.profiles;
CREATE POLICY profiles_delivery_read_customers ON public.profiles
    FOR SELECT TO authenticated
    USING (
        -- Delivery/Admin can read everyone
        EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('delivery', 'admin'))
        OR
        -- Users can read themselves
        id = auth.uid()
    );

-- 4. PRODUCTS: Ensure readable (usually public/authenticated, but just in case)
DROP POLICY IF EXISTS products_delivery_select ON public.products;
CREATE POLICY products_delivery_select ON public.products
    FOR SELECT TO authenticated
    USING (true);

"@

Write-Host "Executing Comprehensive RLS fix..." -ForegroundColor Yellow
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: Updated RLS policies for orders, subscriptions, profiles, products!" -ForegroundColor Green
    if ($result) { $result | ConvertTo-Json -Depth 3 }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
