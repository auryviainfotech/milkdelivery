$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$sql = "
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ""Allow all"" ON public.subscriptions;
CREATE POLICY ""Allow all"" ON public.subscriptions FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ""Allow all"" ON public.orders;
CREATE POLICY ""Allow all"" ON public.orders FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ""Allow all"" ON public.deliveries;
CREATE POLICY ""Allow all"" ON public.deliveries FOR ALL USING (true) WITH CHECK (true);
"

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Applying RLS fixes for subscriptions/orders/deliveries..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: Policies Applied" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
