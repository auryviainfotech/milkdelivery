# Complete Chain Verification: Auth -> Profile -> Customer Assignment -> Delivery
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

Write-Host "=== COMPLETE CHAIN VERIFICATION ===" -ForegroundColor Cyan

# 1. Auth Users (only delivery emails)
Write-Host "`n1. DELIVERY AUTH USERS (auth.users):" -ForegroundColor Yellow
$authUsers = Invoke-SQL "SELECT id, email FROM auth.users WHERE email LIKE 'delivery_%';"
if ($authUsers -and $authUsers.Count -gt 0) {
    foreach ($u in $authUsers) {
        Write-Host "   Auth ID: $($u.id) | Email: $($u.email)"
    }
} else {
    Write-Host "   NONE FOUND - Delivery persons not created properly!" -ForegroundColor Red
}

# 2. Delivery Profiles
Write-Host "`n2. DELIVERY PROFILES (profiles where role='delivery'):" -ForegroundColor Yellow
$profiles = Invoke-SQL "SELECT id, full_name, phone FROM profiles WHERE role = 'delivery';"
if ($profiles -and $profiles.Count -gt 0) {
    foreach ($p in $profiles) {
        Write-Host "   Profile ID: $($p.id) | Name: $($p.full_name) | Phone: $($p.phone)"
    }
} else {
    Write-Host "   NONE FOUND - No delivery person profiles!" -ForegroundColor Red
}

# 3. Customer Assignments
Write-Host "`n3. CUSTOMER ASSIGNMENTS (assigned_delivery_person_id):" -ForegroundColor Yellow
$customers = Invoke-SQL "SELECT full_name, assigned_delivery_person_id FROM profiles WHERE role = 'customer';"
if ($customers) {
    foreach ($c in $customers) {
        $assignment = if ($c.assigned_delivery_person_id) { $c.assigned_delivery_person_id } else { "NULL (unassigned)" }
        Write-Host "   Customer: $($c.full_name) -> Assigned To: $assignment"
    }
}

# 4. Recent Deliveries
Write-Host "`n4. DELIVERIES (delivery_person_id assignments):" -ForegroundColor Yellow
$deliveries = Invoke-SQL "SELECT id, order_id, scheduled_date, delivery_person_id, status FROM deliveries ORDER BY scheduled_date DESC LIMIT 5;"
if ($deliveries -and $deliveries.Count -gt 0) {
    foreach ($d in $deliveries) {
        Write-Host "   Delivery: $($d.id.Substring(0,8))... | Date: $($d.scheduled_date) | Person: $($d.delivery_person_id) | Status: $($d.status)"
    }
} else {
    Write-Host "   NO DELIVERIES FOUND!" -ForegroundColor Red
}

# 5. Cross-check: Does delivery_person_id in deliveries match any auth user?
Write-Host "`n5. CROSS-CHECK (Does delivery_person_id in deliveries match auth users?):" -ForegroundColor Yellow
$crossCheck = Invoke-SQL "
SELECT d.delivery_person_id, au.email as auth_email, p.full_name as profile_name
FROM deliveries d
LEFT JOIN auth.users au ON d.delivery_person_id = au.id
LEFT JOIN profiles p ON d.delivery_person_id = p.id
LIMIT 5;
"
if ($crossCheck) {
    foreach ($row in $crossCheck) {
        $auth = if ($row.auth_email) { $row.auth_email } else { "NOT IN AUTH!" }
        $profile = if ($row.profile_name) { $row.profile_name } else { "NOT IN PROFILES!" }
        Write-Host "   Delivery Person ID: $($row.delivery_person_id)"
        Write-Host "     -> Auth: $auth"
        Write-Host "     -> Profile: $profile"
    }
}

Write-Host "`n=== END VERIFICATION ===" -ForegroundColor Cyan
