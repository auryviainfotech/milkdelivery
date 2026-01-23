$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== FIXING RLS FOR DELIVERY PERSONS ===" -ForegroundColor Cyan

# Create/replace policy to allow delivery persons to SELECT their assigned deliveries
$sql = @"
-- Drop existing restrictive policy if exists
DROP POLICY IF EXISTS deliveries_delivery_select ON public.deliveries;

-- Create new policy: Delivery persons can read deliveries assigned to them
CREATE POLICY deliveries_delivery_select ON public.deliveries
    FOR SELECT
    TO authenticated
    USING (
        delivery_person_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );
"@

Write-Host "Executing RLS fix..." -ForegroundColor Yellow
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: RLS policy updated!" -ForegroundColor Green
    $result | ConvertTo-Json -Depth 3
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "Now restart the Delivery App and try again!"
