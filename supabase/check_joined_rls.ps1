$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== RLS CHECK ON JOINED TABLES ===" -ForegroundColor Cyan

# Function to check table RLS
function Check-RLS {
    param($tableName)
    Write-Host "`nChecking '$tableName'..." -ForegroundColor Yellow
    
    # Check if RLS enabled
    $sql = "SELECT relrowsecurity FROM pg_class WHERE relname = '$tableName';"
    $body = @{ query = $sql } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    
    if ($result.relrowsecurity) {
        Write-Host "  RLS is ENABLED" -ForegroundColor Red
        
        # Get policies
        $sql = "SELECT policyname, cmd, roles, qual, with_check FROM pg_policies WHERE tablename = '$tableName';"
        $body = @{ query = $sql } | ConvertTo-Json
        $pRes = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
        
        if ($pRes -and $pRes.Count -gt 0) {
            $pRes | ForEach-Object {
                Write-Host "  - Policy: $($_.policyname) ($($_.cmd))" -ForegroundColor Green
                Write-Host "    Qual: $($_.qual)"
            }
        } else {
             Write-Host "  (No policies found!)" -ForegroundColor Red
        }
    } else {
        Write-Host "  RLS is DISABLED (Open access)" -ForegroundColor Green
    }
}

Check-RLS "orders"
Check-RLS "subscriptions"
Check-RLS "profiles"
Check-RLS "products"

Write-Host "`n=== END ===" -ForegroundColor Cyan
