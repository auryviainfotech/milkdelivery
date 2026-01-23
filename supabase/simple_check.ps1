# Simple verification queries
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

# 1. All auth users
Write-Host "AUTH USERS:"
Invoke-SQL "SELECT id, email FROM auth.users;" | ConvertTo-Json

# 2. All profiles
Write-Host "`nPROFILES:"
Invoke-SQL "SELECT id, full_name, role FROM profiles;" | ConvertTo-Json

# 3. Customer assignments
Write-Host "`nASSIGNMENTS:"
Invoke-SQL "SELECT full_name, assigned_delivery_person_id FROM profiles WHERE role='customer';" | ConvertTo-Json

# 4. Deliveries
Write-Host "`nDELIVERIES:"
Invoke-SQL "SELECT delivery_person_id, scheduled_date FROM deliveries;" | ConvertTo-Json
