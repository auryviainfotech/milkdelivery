-- =====================================================
-- ADMIN RLS POLICIES
-- Run this in Supabase SQL Editor after main schema
-- =====================================================

-- Helper function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================
-- PROFILES - Admin Access
-- =====================
CREATE POLICY "Admins can view all profiles" ON profiles
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all profiles" ON profiles
FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert profiles" ON profiles
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- WALLETS - Admin Access
-- =====================
CREATE POLICY "Admins can view all wallets" ON wallets
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all wallets" ON wallets
FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert wallets" ON wallets
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- WALLET TRANSACTIONS - Admin Access
-- =====================
CREATE POLICY "Admins can view all wallet transactions" ON wallet_transactions
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can insert wallet transactions" ON wallet_transactions
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- SUBSCRIPTIONS - Admin Access
-- =====================
CREATE POLICY "Admins can view all subscriptions" ON subscriptions
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all subscriptions" ON subscriptions
FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert subscriptions" ON subscriptions
FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "Admins can delete subscriptions" ON subscriptions
FOR DELETE USING (is_admin());

-- =====================
-- ORDERS - Admin Access
-- =====================
CREATE POLICY "Admins can view all orders" ON orders
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all orders" ON orders
FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert orders" ON orders
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- DELIVERIES - Admin Access
-- =====================
CREATE POLICY "Admins can view all deliveries" ON deliveries
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all deliveries" ON deliveries
FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert deliveries" ON deliveries
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- NOTIFICATIONS - Admin Access
-- =====================
CREATE POLICY "Admins can view all notifications" ON notifications
FOR SELECT USING (is_admin());

CREATE POLICY "Admins can insert notifications" ON notifications
FOR INSERT WITH CHECK (is_admin());

-- =====================
-- PRODUCTS - Admin Write Access
-- =====================
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage products" ON products
FOR ALL USING (is_admin());

-- =====================
-- SUBSCRIPTION PLANS - Admin Write Access
-- =====================
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view subscription plans" ON subscription_plans
FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage subscription plans" ON subscription_plans
FOR ALL USING (is_admin());

-- =====================
-- DELIVERY ROUTES - Admin Access
-- =====================
ALTER TABLE delivery_routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage delivery routes" ON delivery_routes
FOR ALL USING (is_admin());

CREATE POLICY "Delivery persons can view their routes" ON delivery_routes
FOR SELECT USING (delivery_person_id = auth.uid());

-- =====================================================
-- CREATE FIRST ADMIN USER
-- Run this after signing up to make yourself admin
-- Replace 'YOUR_USER_ID' with your actual user ID
-- =====================================================
-- UPDATE profiles SET role = 'admin' WHERE id = 'YOUR_USER_ID';
