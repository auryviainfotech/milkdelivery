# Run exact same query as Admin Panel
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

Write-Host "--- EXACT ADMIN PANEL QUERY ---"
Write-Host "SELECT * FROM profiles WHERE role = 'delivery' ORDER BY created_at DESC"
$result = Invoke-SQL "SELECT * FROM profiles WHERE role = 'delivery' ORDER BY created_at DESC;"
if ($result -and $result.Count -gt 0) {
    Write-Host "Found $($result.Count) delivery persons:"
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "RESULT: 0 rows (empty)"
}

Write-Host "`n--- ALL PROFILES WITH ROLE ---"
$all = Invoke-SQL "SELECT full_name, role FROM profiles;"
$all | ConvertTo-Json -Depth 5
