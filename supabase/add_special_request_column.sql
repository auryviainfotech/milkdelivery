-- Add special_request column to subscriptions table
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS special_request TEXT;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscriptions' AND column_name = 'special_request';
