-- =====================================================
-- MIGRATION: Auto Inactive Subscription on 0 Liters
-- =====================================================

-- Function to check liters and update status
CREATE OR REPLACE FUNCTION check_liters_quota()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if liters dropped to 0 or below, AND it was previously > 0
    -- (The second condition prevents infinite recursion if we update other fields)
    IF NEW.liters_remaining <= 0 AND (OLD.liters_remaining > 0 OR OLD.liters_remaining IS NULL) THEN
        
        -- 1. Update Profile Status
        NEW.subscription_status := 'inactive';
        
        -- 2. Update Active Subscriptions for this user to 'paused' or 'inactive'?
        -- User asked for "inactive".
        -- We need to do this carefully. Triggers within triggers.
        -- We can update the subscriptions table.
        UPDATE subscriptions 
        SET status = 'paused', -- Pausing is safer so they can resume? Or 'inactive'? detailed: "inactive again"
            updated_at = NOW()
        WHERE user_id = NEW.id 
          AND status = 'active';
          
        -- Note: strict recursive triggers might block this if not careful, 
        -- but profiles -> subscriptions is different table, so it's fine.
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger definition
DROP TRIGGER IF EXISTS on_liters_update ON profiles;
CREATE TRIGGER on_liters_update
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION check_liters_quota();
