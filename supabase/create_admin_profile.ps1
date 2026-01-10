$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$email = "mdt01569@gmail.com"

# SQL to insert missing profile and wallet
$sql = "
DO $$
DECLARE
    user_id uuid;
BEGIN
    SELECT id INTO user_id FROM auth.users WHERE email = '$email';
    
    IF user_id IS NOT NULL THEN
        -- Insert or Update Profile
        INSERT INTO public.profiles (id, role, full_name, phone, created_at)
        VALUES (user_id, 'admin', 'System Admin', NULL, now())
        ON CONFLICT (id) DO UPDATE SET role = 'admin';
        
        -- Create Wallet if not exists
        INSERT INTO public.wallets (user_id, balance, created_at)
        VALUES (user_id, 0.00, now())
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
END $$;
"

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Creating admin profile for $email..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: Profile created/updated!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
