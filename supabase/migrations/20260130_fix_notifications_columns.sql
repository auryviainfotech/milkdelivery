-- =============================================
-- Fix Missing Columns in Notifications Table
-- Adds 'data' and 'type' columns
-- =============================================

-- Add the 'data' column if it doesn't exist
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS data JSONB;

-- Add the 'type' column if it doesn't exist
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS type VARCHAR(50);

-- Reload schema cache (notify postgrest to pick up changes)
NOTIFY pgrst, 'reload schema';
