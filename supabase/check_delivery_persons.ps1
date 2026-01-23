# Check Delivery Persons Only
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

Write-Host "--- DELIVERY PERSONS ---"
$result = Invoke-SQL "SELECT id, full_name, phone, role FROM profiles WHERE role = 'delivery';"
if ($result -and $result.Count -gt 0) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "NO DELIVERY PERSONS FOUND!"
}

Write-Host "`n--- ALL PROFILES ---"
$all = Invoke-SQL "SELECT id, full_name, role FROM profiles;"
$all | ConvertTo-Json -Depth 5
