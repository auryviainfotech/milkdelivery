# Find delivery auth users specifically
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

Write-Host "--- DELIVERY AUTH USERS ---"
$result = Invoke-SQL "SELECT id, email FROM auth.users WHERE email LIKE 'delivery_%';"
if ($result -and $result.Count -gt 0) {
    Write-Host "Found delivery users:"
    $result | ConvertTo-Json -Depth 5
    
    # Delete them
    Write-Host "`nDeleting..."
    Invoke-SQL "DELETE FROM auth.users WHERE email LIKE 'delivery_%';"
    Write-Host "Done!"
} else {
    Write-Host "No delivery auth users found."
}

Write-Host "`n--- CHECK PROFILES FOR BILAL ---"
$bilal = Invoke-SQL "SELECT id, full_name, role FROM profiles WHERE full_name ILIKE '%bilal%';"
if ($bilal -and $bilal.Count -gt 0) {
    Write-Host "Found Bilal in profiles:"
    $bilal | ConvertTo-Json -Depth 5
} else {
    Write-Host "No Bilal in profiles."
}
