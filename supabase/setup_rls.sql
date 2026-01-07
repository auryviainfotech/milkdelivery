-- Run this in Supabase SQL Editor: https://supabase.com/dashboard
-- Go to your project -> SQL Editor -> New Query -> Paste this and click "Run"

-- First, create the admin user (if not exists)
-- Note: Do this manually in Authentication -> Users -> Add User
-- Email: mdt01569@gmail.com
-- Password: (your choice)

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admin can insert" ON profiles;
DROP POLICY IF EXISTS "Everyone can read" ON profiles;
DROP POLICY IF EXISTS "Users can update own" ON profiles;
DROP POLICY IF EXISTS "Allow public insert" ON profiles;
DROP POLICY IF EXISTS "Allow public select" ON profiles;

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow admin (mdt01569@gmail.com) to insert into profiles
CREATE POLICY "Admin can insert" ON profiles 
FOR INSERT TO authenticated 
WITH CHECK (auth.jwt() ->> 'email' = 'mdt01569@gmail.com');

-- Allow everyone to read profiles
CREATE POLICY "Everyone can read" ON profiles 
FOR SELECT USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own" ON profiles 
FOR UPDATE TO authenticated 
USING (auth.uid() = id);

-- Allow admin to delete profiles
CREATE POLICY "Admin can delete" ON profiles 
FOR DELETE TO authenticated 
USING (auth.jwt() ->> 'email' = 'mdt01569@gmail.com');

-- Also set up subscriptions table RLS if needed
DROP POLICY IF EXISTS "Everyone can read subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Authenticated can insert subscriptions" ON subscriptions;

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read subscriptions" ON subscriptions 
FOR SELECT USING (true);

CREATE POLICY "Authenticated can insert subscriptions" ON subscriptions 
FOR INSERT TO authenticated 
WITH CHECK (true);
