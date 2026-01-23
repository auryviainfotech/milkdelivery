-- Allow delivery persons to view orders that have a delivery assigned to them
CREATE POLICY "Delivery can view assigned orders" ON orders
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM deliveries d
            WHERE d.order_id = orders.id
            AND d.delivery_person_id = auth.uid()
        )
    );

-- Allow delivery persons to view subscriptions for those orders
CREATE POLICY "Delivery can view assigned subscriptions" ON subscriptions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            JOIN deliveries d ON d.order_id = o.id
            WHERE o.subscription_id = subscriptions.id
            AND d.delivery_person_id = auth.uid()
        )
    );

-- Allow delivery persons to view customer profiles for their deliveries
CREATE POLICY "Delivery can view assigned customers" ON profiles
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            JOIN deliveries d ON d.order_id = o.id
            WHERE o.user_id = profiles.id
            AND d.delivery_person_id = auth.uid()
        )
    );
