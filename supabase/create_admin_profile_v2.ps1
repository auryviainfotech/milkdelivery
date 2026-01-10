$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$email = "mdt01569@gmail.com"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        Write-Host "SUCCESS: Executed SQL" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "Creating/Updating profile for $email..." -ForegroundColor Cyan

# 1. Insert/Update Profile
Invoke-SQL "
INSERT INTO public.profiles (id, role, full_name, created_at)
SELECT id, 'admin', 'System Admin', now()
FROM auth.users
WHERE email = '$email'
ON CONFLICT (id) DO UPDATE SET role = 'admin';
"

# 2. Insert Wallet
Invoke-SQL "
INSERT INTO public.wallets (user_id, balance, created_at)
SELECT id, 0.00, now()
FROM auth.users
WHERE email = '$email'
ON CONFLICT (user_id) DO NOTHING;
"
