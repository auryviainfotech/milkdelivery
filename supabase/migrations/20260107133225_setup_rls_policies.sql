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

-- Also set up subscriptions table RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read subscriptions" ON subscriptions 
FOR SELECT USING (true);

CREATE POLICY "Authenticated can insert subscriptions" ON subscriptions 
FOR INSERT TO authenticated 
WITH CHECK (true);
