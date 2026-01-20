-- =====================================================
-- MIGRATION: Add Liters Quota System
-- Run this in the Supabase SQL Editor
-- =====================================================

-- Add liters_remaining and subscription_status to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS liters_remaining DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'inactive' 
    CHECK (subscription_status IN ('inactive', 'pending', 'active'));

-- Add monthly_liters and pending status to subscriptions
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS monthly_liters INT DEFAULT 30,
ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id),
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS time_slot VARCHAR(20) DEFAULT 'morning',
ADD COLUMN IF NOT EXISTS skip_weekends BOOLEAN DEFAULT false;

-- Update subscriptions status check to include 'pending'
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_status_check;
ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_status_check 
    CHECK (status IN ('pending', 'active', 'paused', 'expired', 'cancelled'));

-- Add payment_method and payment_status to orders for COD tracking
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS order_type VARCHAR(20) DEFAULT 'subscription' 
    CHECK (order_type IN ('subscription', 'one_time')),
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'wallet' 
    CHECK (payment_method IN ('wallet', 'cod', 'online')),
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending' 
    CHECK (payment_status IN ('pending', 'paid', 'failed')),
ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS delivery_address TEXT;

-- Add liters_delivered to deliveries for tracking
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS liters_delivered DECIMAL(10, 2) DEFAULT 0.00;

-- =====================================================
-- FUNCTION: Deduct liters from customer quota
-- Called when delivery person scans QR and confirms delivery
-- =====================================================
CREATE OR REPLACE FUNCTION deduct_liters(
    p_user_id UUID,
    p_liters DECIMAL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_remaining DECIMAL;
BEGIN
    -- Get current liters
    SELECT liters_remaining INTO v_remaining
    FROM profiles WHERE id = p_user_id FOR UPDATE;
    
    -- Check if enough liters
    IF v_remaining < p_liters THEN
        RETURN FALSE;
    END IF;
    
    -- Deduct liters
    UPDATE profiles 
    SET liters_remaining = liters_remaining - p_liters, 
        updated_at = NOW()
    WHERE id = p_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Add liters to customer quota (Admin action)
-- Called when admin activates subscription
-- =====================================================
CREATE OR REPLACE FUNCTION add_liters(
    p_user_id UUID,
    p_liters DECIMAL
)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles 
    SET liters_remaining = liters_remaining + p_liters,
        subscription_status = 'active',
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Activate subscription (Admin action)
-- Sets subscription status to active and adds initial liters
-- =====================================================
CREATE OR REPLACE FUNCTION activate_subscription(
    p_subscription_id UUID,
    p_initial_liters DECIMAL
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get user id from subscription
    SELECT user_id INTO v_user_id
    FROM subscriptions WHERE id = p_subscription_id;
    
    -- Update subscription status
    UPDATE subscriptions 
    SET status = 'active'
    WHERE id = p_subscription_id;
    
    -- Add liters to profile
    UPDATE profiles 
    SET liters_remaining = liters_remaining + p_initial_liters,
        subscription_status = 'active',
        updated_at = NOW()
    WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
