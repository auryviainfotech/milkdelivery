-- =====================================================
-- MILK DELIVERY SYSTEM - SUPABASE DATABASE SCHEMA
-- Run this in the Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================
-- PROFILES TABLE
-- =====================
CREATE TABLE profiles (
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

-- =====================
-- PRODUCTS TABLE
-- =====================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) DEFAULT 'litre',
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- WALLETS TABLE
-- =====================
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- WALLET TRANSACTIONS TABLE
-- =====================
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit')),
    reason VARCHAR(100),
    payment_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- SUBSCRIPTION PLANS TABLE
-- =====================
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100),
    duration_days INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- =====================
-- SUBSCRIPTIONS TABLE
-- =====================
CREATE TABLE subscriptions (
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

-- =====================
-- ORDERS TABLE
-- =====================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    delivery_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'delivered', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- ORDER ITEMS TABLE
-- =====================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- =====================
-- DELIVERIES TABLE
-- =====================
CREATE TABLE deliveries (
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

-- =====================
-- DELIVERY ROUTES TABLE
-- =====================
CREATE TABLE delivery_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_person_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    route_date DATE NOT NULL,
    order_sequence UUID[],
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- NOTIFICATIONS TABLE
-- =====================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(200),
    body TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================
-- INDEXES
-- =====================
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_deliveries_delivery_person_id ON deliveries(delivery_person_id);
CREATE INDEX idx_deliveries_scheduled_date ON deliveries(scheduled_date);
CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);

-- =====================
-- ROW LEVEL SECURITY (RLS)
-- =====================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read/update their own profile
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Wallets: Users can view their own wallet
CREATE POLICY "Users can view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);

-- Wallet Transactions: Users can view their own transactions
CREATE POLICY "Users can view own transactions" ON wallet_transactions 
    FOR SELECT USING (
        wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
    );

-- Subscriptions: Users can view/manage their own subscriptions
CREATE POLICY "Users can view own subscriptions" ON subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create subscriptions" ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subscriptions" ON subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- Orders: Users can view their own orders
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);

-- Deliveries: Delivery personnel can view assigned deliveries
CREATE POLICY "Delivery can view assigned deliveries" ON deliveries 
    FOR SELECT USING (delivery_person_id = auth.uid());
CREATE POLICY "Delivery can update assigned deliveries" ON deliveries 
    FOR UPDATE USING (delivery_person_id = auth.uid());

-- Notifications: Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Products: Everyone can read products
CREATE POLICY "Anyone can view products" ON products FOR SELECT TO authenticated USING (true);

-- =====================
-- FUNCTIONS
-- =====================

-- Function to create wallet when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create profile
    INSERT INTO profiles (id, phone, role)
    VALUES (NEW.id, NEW.phone, 'customer');
    
    -- Create wallet
    INSERT INTO wallets (user_id, balance)
    VALUES (NEW.id, 0.00);
    
    -- Generate QR code
    UPDATE profiles SET qr_code = 'MILK-' || SUBSTRING(NEW.id::text, 1, 8) WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to deduct wallet balance
CREATE OR REPLACE FUNCTION deduct_wallet_balance(
    p_user_id UUID,
    p_amount DECIMAL,
    p_reason VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_wallet_id UUID;
    v_balance DECIMAL;
BEGIN
    -- Get wallet
    SELECT id, balance INTO v_wallet_id, v_balance
    FROM wallets WHERE user_id = p_user_id FOR UPDATE;
    
    -- Check balance
    IF v_balance < p_amount THEN
        RETURN FALSE;
    END IF;
    
    -- Deduct balance
    UPDATE wallets SET balance = balance - p_amount, updated_at = NOW()
    WHERE id = v_wallet_id;
    
    -- Record transaction
    INSERT INTO wallet_transactions (wallet_id, amount, type, reason)
    VALUES (v_wallet_id, p_amount, 'debit', p_reason);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================
-- SEED DATA (Sample Products)
-- =====================
INSERT INTO products (name, description, price, unit, is_active) VALUES
    ('Full Cream Milk', 'Fresh full cream milk from local farms', 30.00, '500ml', true),
    ('Toned Milk', 'Low fat toned milk', 50.00, '1L', true),
    ('Buffalo Milk', 'Pure buffalo milk', 35.00, '500ml', true),
    ('Skimmed Milk', 'Fat-free skimmed milk', 45.00, '1L', true),
    ('Organic Milk', 'Certified organic milk', 60.00, '500ml', true);

-- Create subscription plans for each product
INSERT INTO subscription_plans (product_id, name, duration_days, price, is_active)
SELECT id, 'Daily', 30, price * 30, true FROM products WHERE is_active = true;

INSERT INTO subscription_plans (product_id, name, duration_days, price, is_active)
SELECT id, 'Weekly', 7, price * 7, true FROM products WHERE is_active = true;
