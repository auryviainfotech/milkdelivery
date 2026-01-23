# Check if delivery person ID exists in auth.users
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

function Invoke-SQL {
    param($sql)
    $body = @{ query = $sql } | ConvertTo-Json -Depth 10
    try {
        $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $null
    }
}

$deliveryPersonId = "ea9ae4c7-347e-4ba1-97eb-6062356394ea"

Write-Host "Checking ID: $deliveryPersonId"

# Check auth.users
Write-Host "`n1. In AUTH.USERS?"
$auth = Invoke-SQL "SELECT id, email FROM auth.users WHERE id = '$deliveryPersonId';"
if ($auth -and $auth.Count -gt 0) {
    Write-Host "   YES: $($auth[0].email)" -ForegroundColor Green
} else {
    Write-Host "   NO - NOT IN AUTH.USERS!" -ForegroundColor Red
}

# Check profiles
Write-Host "`n2. In PROFILES?"
$profile = Invoke-SQL "SELECT id, full_name, role FROM profiles WHERE id = '$deliveryPersonId';"
if ($profile -and $profile.Count -gt 0) {
    Write-Host "   YES: $($profile[0].full_name) (role: $($profile[0].role))" -ForegroundColor Green
} else {
    Write-Host "   NO - NOT IN PROFILES!" -ForegroundColor Red
}

# Check deliveries
Write-Host "`n3. In DELIVERIES (assigned)?"
$deliveries = Invoke-SQL "SELECT COUNT(*) as cnt FROM deliveries WHERE delivery_person_id = '$deliveryPersonId';"
if ($deliveries -and $deliveries[0].cnt -gt 0) {
    Write-Host "   YES: $($deliveries[0].cnt) deliveries assigned" -ForegroundColor Green
} else {
    Write-Host "   NO deliveries assigned" -ForegroundColor Yellow
}

Write-Host "`n=== CONCLUSION ==="
if ($auth -and $auth.Count -gt 0) {
    Write-Host "Auth user EXISTS. RLS should work." -ForegroundColor Green
} else {
    Write-Host "Auth user MISSING. RLS will block all deliveries for this person!" -ForegroundColor Red
    Write-Host "SOLUTION: Create a Supabase Auth user with this ID, or re-create the delivery person properly." -ForegroundColor Yellow
}
