-- =============================================
-- Push Notifications Schema Migration
-- =============================================
-- Run this in Supabase SQL Editor

-- Add OneSignal player ID to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal_player_id 
ON profiles(onesignal_player_id) 
WHERE onesignal_player_id IS NOT NULL;

-- =============================================
-- In-App Notifications Table
-- =============================================
-- Stores notifications for display in the app

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    data JSONB,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);

-- =============================================
-- Row Level Security
-- =============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only read their own notifications
CREATE POLICY "Users can read own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Service role can insert notifications (for backend triggers)
CREATE POLICY "Service role can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- =============================================
-- Notification Templates Table
-- =============================================
-- For admin to create reusable notification templates

CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'promotion',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- Marketing Campaigns Table
-- =============================================
-- Track notification campaigns for analytics

CREATE TABLE IF NOT EXISTS notification_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES notification_templates(id),
    name TEXT NOT NULL,
    target_type TEXT NOT NULL DEFAULT 'all', -- 'all', 'segment', 'individual'
    target_data JSONB, -- segment criteria or user IDs
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'draft', -- 'draft', 'scheduled', 'sent', 'cancelled'
    total_sent INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- =============================================
-- Helper Functions
-- =============================================

-- Function to create in-app notification for a user
CREATE OR REPLACE FUNCTION create_user_notification(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_type TEXT DEFAULT 'general',
    p_data JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (user_id, title, body, type, data)
    VALUES (p_user_id, p_title, p_body, p_type, p_data)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE
    WHERE user_id = p_user_id AND is_read = FALSE;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE user_id = p_user_id AND is_read = FALSE;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- Triggers for Automatic Notifications
-- =============================================

-- Notify on order status change
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only notify if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        PERFORM create_user_notification(
            NEW.user_id,
            'Order Update',
            CASE NEW.status
                WHEN 'confirmed' THEN 'Your order has been confirmed!'
                WHEN 'out_for_delivery' THEN 'Your order is out for delivery!'
                WHEN 'delivered' THEN 'Your order has been delivered!'
                WHEN 'cancelled' THEN 'Your order has been cancelled.'
                ELSE 'Your order status has been updated.'
            END,
            'orderUpdate',
            jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for order status notifications
DROP TRIGGER IF EXISTS order_status_notification_trigger ON orders;
CREATE TRIGGER order_status_notification_trigger
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_status_change();

-- Notify on wallet transaction
CREATE OR REPLACE FUNCTION notify_wallet_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_title TEXT;
    v_body TEXT;
BEGIN
    IF NEW.type = 'credit' THEN
        v_title := 'Money Added';
        v_body := format('₹%s has been added to your wallet.', NEW.amount::INTEGER);
    ELSE
        v_title := 'Wallet Deduction';
        v_body := format('₹%s has been deducted from your wallet.', NEW.amount::INTEGER);
    END IF;
    
    PERFORM create_user_notification(
        NEW.user_id,
        v_title,
        v_body,
        'walletUpdate',
        jsonb_build_object('transaction_id', NEW.id, 'amount', NEW.amount, 'type', NEW.type)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for wallet transaction notifications
DROP TRIGGER IF EXISTS wallet_transaction_notification_trigger ON wallet_transactions;
CREATE TRIGGER wallet_transaction_notification_trigger
    AFTER INSERT ON wallet_transactions
    FOR EACH ROW
    EXECUTE FUNCTION notify_wallet_transaction();

-- =============================================
-- Sample Notification Templates
-- =============================================

INSERT INTO notification_templates (name, title, body, type) VALUES
    ('festival_diwali', '🪔 Happy Diwali!', 'Celebrate with 20% off on all products! Use code DIWALI20', 'promotion'),
    ('festival_holi', '🎨 Happy Holi!', 'Colorful offers inside! Get 15% off on your next order', 'promotion'),
    ('new_product', '✨ New Arrival!', 'Check out our new product! Fresh from the farm', 'newProduct'),
    ('subscription_expiring', '🔔 Renewal Reminder', 'Your subscription is expiring soon. Renew now to continue enjoying fresh milk!', 'subscriptionReminder'),
    ('low_wallet', '💰 Low Wallet Balance', 'Your wallet balance is running low. Top up now to avoid delivery interruptions!', 'walletUpdate'),
    ('welcome', '👋 Welcome!', 'Welcome to MilkDelivery! Start your subscription today for fresh milk daily.', 'general')
ON CONFLICT DO NOTHING;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_notification TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count TO authenticated;
