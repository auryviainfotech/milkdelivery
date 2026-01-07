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
        Write-Host "SUCCESS: $($sql.Substring(0, [Math]::Min(50, $sql.Length)))..."
        return $true
    } catch {
        Write-Host "ERROR: $_"
        return $false
    }
}

# Profiles table
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    role VARCHAR(20) DEFAULT 'customer' CHECK (role IN ('customer', 'delivery', 'admin')),
    qr_code VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Wallets table
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Wallet transactions
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit')),
    reason VARCHAR(100),
    payment_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Subscription plans
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100),
    duration_days INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);
"@

# Subscriptions
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
    quantity INT DEFAULT 1,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'expired', 'cancelled')),
    skip_dates DATE[],
    created_before_cutoff BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Orders
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    delivery_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'delivered', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Order items
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
"@

# Deliveries
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
    delivery_person_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    scheduled_date DATE NOT NULL,
    delivered_at TIMESTAMP WITH TIME ZONE,
    qr_scanned BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_transit', 'delivered', 'issue')),
    issue_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Delivery routes
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS delivery_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_person_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    route_date DATE NOT NULL,
    order_sequence UUID[],
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Notifications
Invoke-SQL @"
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(200),
    body TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"@

# Indexes
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(delivery_date);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_deliveries_delivery_person_id ON deliveries(delivery_person_id);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_deliveries_scheduled_date ON deliveries(scheduled_date);"
Invoke-SQL "CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);"

# RLS
Invoke-SQL "ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE orders ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;"
Invoke-SQL "ALTER TABLE products ENABLE ROW LEVEL SECURITY;"

# Policies
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can view own subscriptions" ON subscriptions FOR SELECT USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can create subscriptions" ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can update own subscriptions" ON subscriptions FOR UPDATE USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Delivery can view assigned deliveries" ON deliveries FOR SELECT USING (delivery_person_id = auth.uid());'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Delivery can update assigned deliveries" ON deliveries FOR UPDATE USING (delivery_person_id = auth.uid());'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);'
Invoke-SQL 'CREATE POLICY IF NOT EXISTS "Anyone can view products" ON products FOR SELECT TO authenticated USING (true);'

# Seed products
Invoke-SQL @"
INSERT INTO products (name, description, price, unit, is_active) VALUES
    ('Full Cream Milk', 'Fresh full cream milk from local farms', 30.00, '500ml', true),
    ('Toned Milk', 'Low fat toned milk', 50.00, '1L', true),
    ('Buffalo Milk', 'Pure buffalo milk', 35.00, '500ml', true),
    ('Skimmed Milk', 'Fat-free skimmed milk', 45.00, '1L', true),
    ('Organic Milk', 'Certified organic milk', 60.00, '500ml', true)
ON CONFLICT DO NOTHING;
"@

# Subscription plans
Invoke-SQL @"
INSERT INTO subscription_plans (product_id, name, duration_days, price, is_active)
SELECT id, 'Daily', 30, price * 30, true FROM products WHERE is_active = true
ON CONFLICT DO NOTHING;
"@

Invoke-SQL @"
INSERT INTO subscription_plans (product_id, name, duration_days, price, is_active)
SELECT id, 'Weekly', 7, price * 7, true FROM products WHERE is_active = true
ON CONFLICT DO NOTHING;
"@

Write-Host "`n=== Database setup complete! ===" -ForegroundColor Green
