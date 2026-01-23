# Apply RLS Fix V2 (Reliable)
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "Applying RLS fixes..."

# 1. Orders Policy
Write-Host "1. Adding: Delivery can view assigned orders..."
Invoke-SQL "
CREATE POLICY \"Delivery can view assigned orders\" ON orders
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM deliveries d
            WHERE d.order_id = orders.id
            AND d.delivery_person_id = auth.uid()
        )
    );
"

# 2. Subscriptions Policy
Write-Host "2. Adding: Delivery can view assigned subscriptions..."
Invoke-SQL "
CREATE POLICY \"Delivery can view assigned subscriptions\" ON subscriptions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            JOIN deliveries d ON d.order_id = o.id
            WHERE o.subscription_id = subscriptions.id
            AND d.delivery_person_id = auth.uid()
        )
    );
"

# 3. Profiles Policy
Write-Host "3. Adding: Delivery can view assigned customers..."
Invoke-SQL "
CREATE POLICY \"Delivery can view assigned customers\" ON profiles
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            JOIN deliveries d ON d.order_id = o.id
            WHERE o.user_id = profiles.id
            AND d.delivery_person_id = auth.uid()
        )
    );
"

Write-Host "Done!"
