$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== BILAL PROFILE CHECK ===" -ForegroundColor Cyan

$sql = "SELECT id, full_name, phone, role, address FROM public.profiles WHERE full_name ILIKE '%bilal%' OR phone LIKE '%7993619422%';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if ($result) {
    Write-Host "Found Profile(s):" -ForegroundColor Green
    $result | ForEach-Object {
        Write-Host "  ID:       $($_.id)"
        Write-Host "  Name:     $($_.full_name)"
        Write-Host "  Phone:    $($_.phone)"
        Write-Host "  Role:     $($_.role)"
        Write-Host "  Password: $($_.address)"
        Write-Host ""
    }
} else {
    Write-Host "No profile found for bilal!" -ForegroundColor Red
}
