$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== RLS POLICIES CHECK ===" -ForegroundColor Cyan

# Check RLS policies on deliveries table
$sql = @"
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'deliveries';
"@
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "`nRLS Policies on 'deliveries' table:" -ForegroundColor Yellow
if ($result -and $result.Count -gt 0) {
    $result | ForEach-Object {
        Write-Host "  Policy: $($_.policyname)" -ForegroundColor Green
        Write-Host "    Command: $($_.cmd)"
        Write-Host "    Roles: $($_.roles)"
        Write-Host "    Qual: $($_.qual)"
    }
} else {
    Write-Host "  (no policies found - RLS might be disabled or open)" -ForegroundColor Yellow
}

# Check if RLS is enabled on deliveries
$sql = "SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'deliveries';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "`nRLS Status on 'deliveries':" -ForegroundColor Yellow
$result | ForEach-Object {
    $status = if ($_.relrowsecurity) { "ENABLED" } else { "DISABLED" }
    Write-Host "  RLS is: $status" -ForegroundColor $(if ($_.relrowsecurity) { "Red" } else { "Green" })
}

Write-Host "`n=== END ===" -ForegroundColor Cyan
