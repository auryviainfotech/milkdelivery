-- =====================================================
-- MIGRATION: Add 'category' column to products table
-- Separates subscription products (daily milk) from one-time products (butter, ghee, etc.)
-- =====================================================

-- Add category column with default 'subscription' for existing products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'subscription' 
CHECK (category IN ('subscription', 'one_time'));

-- Update existing products to be subscription type (milk products)
UPDATE products SET category = 'subscription' WHERE category IS NULL;

-- =====================================================
-- NANDINI SUBSCRIPTION PRODUCTS (Daily Milk Delivery)
-- =====================================================

-- First, deactivate old sample products
UPDATE products SET is_active = false WHERE name IN (
  'Full Cream Milk', 'Toned Milk', 'Buffalo Milk', 'Skimmed Milk', 'Organic Milk'
);

-- Insert Nandini subscription products
INSERT INTO products (name, description, price, unit, emoji, is_active, category) VALUES
  ('Nandini Pasteurised Cow Milk (Green)', 'Fresh pasteurised cow milk from Karnataka Milk Federation', 26.00, '500ml', '🥛', true, 'subscription'),
  ('Nandini Pasteurised Toned Milk (Blue)', 'Low-fat toned milk, 500ml pack', 24.00, '500ml', '🥛', true, 'subscription'),
  ('Nandini Pasteurised Toned Milk (Blue)', 'Low-fat toned milk, 1 litre pack', 46.00, '1000ml', '🥛', true, 'subscription'),
  ('Nandini Shubham Standardised Milk (Orange)', 'Standardised milk with consistent fat content, 500ml', 27.00, '500ml', '🥛', true, 'subscription'),
  ('Nandini Shubham Standardised Milk (Orange)', 'Standardised milk with consistent fat content, 1 litre', 52.00, '1000ml', '🥛', true, 'subscription'),
  ('Nandini Samrudhi Full Cream Milk (Purple)', 'Rich full cream milk, 500ml pack', 28.00, '500ml', '🥛', true, 'subscription'),
  ('Nandini Curd', 'Fresh set curd, 500ml pack', 28.00, '500ml', '🫙', true, 'subscription'),
  ('Nandini Curd', 'Fresh set curd, 200ml pack', 13.00, '200ml', '🫙', true, 'subscription')
ON CONFLICT DO NOTHING;

-- =====================================================
-- ONE-TIME PURCHASE PRODUCTS (Additional Dairy Items)
-- =====================================================

INSERT INTO products (name, description, price, unit, emoji, is_active, category) VALUES
  ('Nandini Butter', 'Fresh unsalted butter, 500g pack', 275.00, '500g', '🧈', true, 'one_time'),
  ('Nandini Ghee', 'Pure cow ghee, 500ml jar', 350.00, '500ml', '🫙', true, 'one_time'),
  ('Nandini Ghee', 'Pure cow ghee, 1 litre jar', 680.00, '1L', '🫙', true, 'one_time'),
  ('Nandini Paneer', 'Fresh cottage cheese, 200g pack', 99.00, '200g', '🧀', true, 'one_time'),
  ('Nandini Paneer', 'Fresh cottage cheese, 500g pack', 225.00, '500g', '🧀', true, 'one_time'),
  ('Nandini Shrikhand', 'Sweet flavored yogurt dessert, 100g cup', 35.00, '100g', '🍨', true, 'one_time'),
  ('Nandini Lassi', 'Sweet buttermilk drink, 200ml', 20.00, '200ml', '🥤', true, 'one_time'),
  ('Nandini Peda', 'Traditional milk sweet, 250g box', 150.00, '250g', '🍬', true, 'one_time'),
  ('Nandini Mysore Pak', 'Traditional gram flour sweet, 250g box', 180.00, '250g', '🍬', true, 'one_time'),
  ('Nandini Cheese Slices', 'Processed cheese slices, 200g pack', 120.00, '200g', '🧀', true, 'one_time'),
  ('Nandini Flavoured Milk - Badam', 'Almond flavored milk drink, 200ml', 25.00, '200ml', '🥛', true, 'one_time'),
  ('Nandini Flavoured Milk - Rose', 'Rose flavored milk drink, 200ml', 25.00, '200ml', '🥛', true, 'one_time')
ON CONFLICT DO NOTHING;

-- =====================================================
-- Create index for faster category-based queries
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category, is_active);
