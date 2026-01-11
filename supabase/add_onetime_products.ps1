# Add Category Column and One-Time Products
# This script adds the category column and inserts one-time products (Butter, Ghee, Paneer, etc.)

$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

# SQL to add category column and one-time products
$sql = @"
-- Add category column if not exists
ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'subscription';

-- Update existing products to subscription category
UPDATE products SET category = 'subscription' WHERE category IS NULL;

-- Insert one-time purchase products
INSERT INTO products (name, price, unit, emoji, is_active, category) VALUES
('Nandini Butter', 55, '100 gm', '🧈', true, 'one_time'),
('Nandini Ghee', 150, '200 ml', '🫙', true, 'one_time'),
('Nandini Paneer', 85, '200 gm', '🧀', true, 'one_time'),
('Nandini Mysore Pak', 120, '250 gm', '🍬', true, 'one_time'),
('Nandini Peda', 100, '250 gm', '🍬', true, 'one_time'),
('Nandini Flavoured Milk - Badam', 25, '200 ml', '🥛', true, 'one_time'),
('Nandini Flavoured Milk - Strawberry', 25, '200 ml', '🥛', true, 'one_time'),
('Nandini Lassi', 20, '200 ml', '🥤', true, 'one_time');

-- Return all products with categories
SELECT id, name, price, unit, category FROM products ORDER BY category, name;
"@

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Adding one-time products..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host ""
    Write-Host "Products with categories:" -ForegroundColor Green
    $result | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
