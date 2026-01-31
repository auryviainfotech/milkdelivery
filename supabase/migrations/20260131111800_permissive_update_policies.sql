-- Migration: Allow authenticated users to update deliveries and orders
-- This is a temporary fix to test if RLS is the bottleneck

-- Make deliveries UPDATE more permissive (any authenticated user can update any delivery)
DROP POLICY IF EXISTS "Delivery can update assigned deliveries" ON deliveries;
CREATE POLICY "Authenticated can update deliveries" 
ON deliveries 
FOR UPDATE 
TO authenticated
USING (true)
WITH CHECK (true);

-- Make orders UPDATE more permissive (any authenticated user can update any order)
DROP POLICY IF EXISTS "Delivery can update order status" ON orders;
CREATE POLICY "Authenticated can update orders"
ON orders
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Also ensure profiles update is permissive for liters_remaining
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Authenticated can update profiles"
ON profiles
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
