-- Migration: Add UPDATE policies for deliveries and orders
-- This is needed for the delivery app to mark deliveries as completed

-- Drop existing update policy if exists (to recreate with correct logic)
DROP POLICY IF EXISTS "Delivery can update assigned deliveries" ON deliveries;

-- Deliveries: Delivery personnel can update their assigned deliveries
CREATE POLICY "Delivery can update assigned deliveries" 
ON deliveries 
FOR UPDATE 
TO authenticated
USING (delivery_person_id = auth.uid())
WITH CHECK (delivery_person_id = auth.uid());

-- Orders: Allow delivery personnel to update order status for their deliveries
-- This is needed when marking an order as delivered
DROP POLICY IF EXISTS "Delivery can update order status" ON orders;
CREATE POLICY "Delivery can update order status"
ON orders
FOR UPDATE
TO authenticated
USING (
  id IN (
    SELECT order_id FROM deliveries WHERE delivery_person_id = auth.uid()
  )
)
WITH CHECK (
  id IN (
    SELECT order_id FROM deliveries WHERE delivery_person_id = auth.uid()
  )
);

-- Also allow delivery personnel to view orders they are delivering
DROP POLICY IF EXISTS "Delivery can view assigned orders" ON orders;
CREATE POLICY "Delivery can view assigned orders"
ON orders
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT order_id FROM deliveries WHERE delivery_person_id = auth.uid()
  )
);
