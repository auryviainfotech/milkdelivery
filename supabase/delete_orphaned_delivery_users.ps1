# Delete orphaned delivery auth users using Supabase Management API (SQL endpoint)
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

Write-Host "=== Cleaning Up Orphaned Delivery Auth Users ===" -ForegroundColor Cyan

# First, list delivery auth users
Write-Host "`nFinding delivery auth users..." -ForegroundColor Yellow
$listResult = Invoke-SQL "SELECT id, email FROM auth.users WHERE email LIKE 'delivery_%@milkdelivery.local';"

if ($listResult -and $listResult.Count -gt 0) {
    Write-Host "Found $($listResult.Count) delivery auth users:" -ForegroundColor Yellow
    foreach ($user in $listResult) {
        Write-Host "  - $($user.email) (ID: $($user.id))" -ForegroundColor Gray
    }
    
    # Delete them
    Write-Host "`nDeleting orphaned delivery auth users..." -ForegroundColor Yellow
    $deleteResult = Invoke-SQL "DELETE FROM auth.users WHERE email LIKE 'delivery_%@milkdelivery.local';"
    
    if ($deleteResult -ne $null) {
        Write-Host "Deleted successfully!" -ForegroundColor Green
    }
} else {
    Write-Host "No orphaned delivery auth users found." -ForegroundColor Green
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Cyan
