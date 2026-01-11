# Supabase Product Setup Script
# This script clears existing products and adds the 8 Nandini milk variants

$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

# SQL to delete all existing products and insert new ones
$sql = @"
-- Delete all existing products
DELETE FROM products;

-- Insert 8 Nandini milk variants
INSERT INTO products (name, price, unit, emoji, is_active) VALUES
('Nandini Pasteurised Cow Milk (Green)', 26, '500 ml', '🥛', true),
('Nandini Pasteurised Toned Milk (Blue) - 500ml', 24, '500 ml', '🥛', true),
('Nandini Pasteurised Toned Milk (Blue) - 1L', 46, '1000 ml', '🥛', true),
('Nandini Shubham Standardised Milk (Orange) - 500ml', 27, '500 ml', '🥛', true),
('Nandini Shubham Standardised Milk (Orange) - 1L', 52, '1000 ml', '🥛', true),
('Nandini Samrudhi Full Cream Milk (Purple)', 28, '500 ml', '🥛', true),
('Nandini Curd - 500ml', 28, '500 ml', '🍶', true),
('Nandini Curd - 200ml', 13, '200 ml', '🍶', true);

-- Return inserted products
SELECT id, name, price, unit, emoji FROM products ORDER BY price;
"@

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Setting up Nandini products..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host ""
    Write-Host "Products added successfully:" -ForegroundColor Green
    $result | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
