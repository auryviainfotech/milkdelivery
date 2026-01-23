# Dump Everything to find Bilal
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

Write-Host "--- ALL PROFILES (Name, Role, ID) ---"
$profiles = Invoke-SQL "SELECT full_name, role, id FROM profiles;"
$profiles | Format-Table -AutoSize

Write-Host "`n--- ALL AUTH USERS (Email, ID) ---"
$users = Invoke-SQL "SELECT email, id FROM auth.users;"
$users | Format-Table -AutoSize
