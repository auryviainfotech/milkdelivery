# Check Who is Who
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

Write-Host "--- ID CHECK ---"
# Check the ID found in the previous step
$unknownId = "dc2369a8-e429-4103-956d-fc6e7ee75e7b"
Write-Host "Checking ID: $unknownId"
$profile = Invoke-SQL "SELECT full_name, role FROM profiles WHERE id = '$unknownId';"
if ($profile.Count -gt 0) {
    Write-Host "It belongs to: $($profile[0].full_name) ($($profile[0].role))"
} else {
    Write-Host "ID NOT FOUND in profiles (Likely a deleted user)"
}

# Check Customer Assignment
Write-Host "`nCustomer Assignments:"
$customers = Invoke-SQL "SELECT full_name, assigned_delivery_person_id FROM profiles WHERE role = 'customer';"
$customers | Format-Table

# List ALL delivery persons to find the real Bilal
Write-Host "`nAll Delivery Persons:"
$allDelivery = Invoke-SQL "SELECT id, full_name FROM profiles WHERE role='delivery';"
$allDelivery | Format-Table
