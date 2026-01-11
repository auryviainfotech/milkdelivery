# Fix subscription product_id - Update to valid product
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
        Write-Host "SUCCESS" -ForegroundColor Green
        if ($result) {
            $result | ConvertTo-Json -Depth 10
        }
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "=== Fixing Invalid Product IDs in Subscriptions ===" -ForegroundColor Cyan

# 1. Check existing products
Write-Host "`n1. Checking available products..." -ForegroundColor Yellow
$products = Invoke-SQL "SELECT id, name, price FROM products LIMIT 10;"
Write-Host $products

# 2. Check current subscriptions
Write-Host "`n2. Checking current subscriptions with invalid product_id..." -ForegroundColor Yellow
Invoke-SQL "SELECT id, product_id, user_id FROM subscriptions;"

# 3. Get first valid product ID
Write-Host "`n3. Getting first valid product ID..." -ForegroundColor Yellow
$firstProduct = Invoke-SQL "SELECT id FROM products WHERE is_active = true LIMIT 1;"
Write-Host "First valid product: $firstProduct"

# 4. Update subscriptions with invalid product_id to use a valid one
Write-Host "`n4. Updating subscriptions with invalid product_id..." -ForegroundColor Yellow
Invoke-SQL "
UPDATE subscriptions 
SET product_id = (SELECT id FROM products WHERE is_active = true LIMIT 1)::text
WHERE product_id NOT IN (SELECT id::text FROM products);
"

# 5. Verify fix
Write-Host "`n5. Verifying subscriptions now have valid product_ids..." -ForegroundColor Yellow
Invoke-SQL "SELECT s.id, s.product_id, p.name as product_name FROM subscriptions s LEFT JOIN products p ON s.product_id::uuid = p.id;"

Write-Host "`n=== Done! ===" -ForegroundColor Green
