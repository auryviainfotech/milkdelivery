-- =====================================================
-- PAYMENT VERIFICATION EDGE FUNCTION
-- This should be deployed as a Supabase Edge Function
-- =====================================================

-- This SQL creates a table to store verified payments
-- The actual Edge Function needs to be deployed separately

-- =====================
-- PAYMENT VERIFICATIONS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS payment_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    razorpay_payment_id VARCHAR(100) UNIQUE NOT NULL,
    razorpay_order_id VARCHAR(100),
    razorpay_signature VARCHAR(500),
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'failed')),
    user_id UUID REFERENCES profiles(id),
    subscription_id UUID REFERENCES subscriptions(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX idx_payment_verifications_payment_id ON payment_verifications(razorpay_payment_id);

-- RLS
ALTER TABLE payment_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payment verifications" ON payment_verifications
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all payment verifications" ON payment_verifications
FOR SELECT USING (is_admin());

-- =====================================================
-- EDGE FUNCTION CODE (deploy to Supabase Functions)
-- File: supabase/functions/verify-payment/index.ts
-- =====================================================
/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!

serve(async (req) => {
  try {
    const { razorpay_payment_id, razorpay_order_id, razorpay_signature, user_id, subscription_data } = await req.json()
    
    // Verify signature
    const body = razorpay_order_id + "|" + razorpay_payment_id
    const expectedSignature = await generateSignature(body, RAZORPAY_KEY_SECRET)
    
    if (expectedSignature !== razorpay_signature) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 400 })
    }
    
    // Create Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    // Store verification
    const { error: verifyError } = await supabase
      .from('payment_verifications')
      .insert({
        razorpay_payment_id,
        razorpay_order_id,
        razorpay_signature,
        amount: subscription_data.amount,
        status: 'verified',
        user_id,
        verified_at: new Date().toISOString()
      })
    
    if (verifyError) throw verifyError
    
    // Create subscription (server-side, trusted)
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .insert({
        user_id,
        ...subscription_data,
        payment_verified: true
      })
      .select()
      .single()
    
    if (subError) throw subError
    
    return new Response(JSON.stringify({ success: true, subscription }), { status: 200 })
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

async function generateSignature(body: string, secret: string): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey(
    "raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  )
  const signature = await crypto.subtle.sign("HMAC", key, enc.encode(body))
  return Array.from(new Uint8Array(signature)).map(b => b.toString(16).padStart(2, '0')).join('')
}
*/

-- =====================================================
-- HOW TO USE:
-- 1. Run this SQL in Supabase to create the table
-- 2. Create the Edge Function in supabase/functions/verify-payment/
-- 3. Deploy: supabase functions deploy verify-payment
-- 4. Update customer app to call the Edge Function after payment
-- =====================================================
