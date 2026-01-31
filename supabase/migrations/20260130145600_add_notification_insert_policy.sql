-- =============================================
-- Add INSERT Policy for Notifications Table
-- Allow authenticated users to create notifications
-- =============================================

-- Enable RLS (just in case)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing insert policy if it exists to avoid conflicts
DROP POLICY IF EXISTS "Authenticated can insert notifications" ON notifications;

-- Create the insert policy
-- This allows any authenticated user (including delivery personnel) to insert a notification
CREATE POLICY "Authenticated can insert notifications" ON notifications 
FOR INSERT TO authenticated 
WITH CHECK (true);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
