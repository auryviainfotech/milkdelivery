$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$email = "mdt01569@gmail.com"

# Query to get user from auth.users and join with public.profiles
$sql = "
SELECT 
    au.id as auth_id, 
    au.email, 
    p.id as profile_id, 
    p.full_name, 
    p.role 
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE au.email = '$email';
"

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Checking profile for $email..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Result:" -ForegroundColor Green
    $result | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
