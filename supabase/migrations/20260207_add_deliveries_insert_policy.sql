-- Migration: Allow customers to insert delivery records when placing orders
-- This is needed for shop orders to be visible in the delivery app

-- Add INSERT policy for deliveries
-- Customers can create deliveries for their own orders
CREATE POLICY "Customers can create deliveries for own orders"
ON deliveries
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = order_id
        AND orders.user_id = auth.uid()
    )
);

-- Also allow SELECT for admin and for customers to see their delivery status
CREATE POLICY "Users can view deliveries for own orders"
ON deliveries
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = order_id
        AND orders.user_id = auth.uid()
    )
    OR delivery_person_id = auth.uid()
);
