$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== ALL DELIVERY PERSONS ===" -ForegroundColor Cyan

$sql = "SELECT id, full_name, phone, role, address as password FROM public.profiles WHERE role = 'delivery' OR role = 'admin';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($result) {
    Write-Host "Found $($result.Count) profiles:" -ForegroundColor Green
    $result | ForEach-Object {
        Write-Host "-----------------------------------"
        Write-Host "  Name:     $($_.full_name)"
        Write-Host "  Phone:    $($_.phone)"
        Write-Host "  Role:     $($_.role)"
        Write-Host "  Password: $($_.password)"
        Write-Host "  ID:       $($_.id)"
    }
} else {
    Write-Host "No delivery persons found!" -ForegroundColor Red
}
