$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== CHECKING BILAL'S PROFILE ===" -ForegroundColor Cyan

# Check bilal by phone
$sql = "SELECT id, full_name, phone, role FROM public.profiles WHERE phone LIKE '%7993619422%';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "Profiles matching phone '7993619422':" -ForegroundColor Yellow
if ($result -and $result.Count -gt 0) {
    $result | ForEach-Object {
        Write-Host "  Name: $($_.full_name)"
        Write-Host "  Phone: $($_.phone)"
        Write-Host "  Role: $($_.role)"
        Write-Host "  ID: $($_.id)" -ForegroundColor Green
        Write-Host ""
    }
} else {
    Write-Host "  No profile found with that phone!" -ForegroundColor Red
}

# Also check the delivery person ID on today's delivery
$today = Get-Date -Format "yyyy-MM-dd"
$sql = "SELECT delivery_person_id FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$del = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

Write-Host "Today's Delivery assigned to:" -ForegroundColor Yellow
Write-Host "  $($del.delivery_person_id)" -ForegroundColor Green

Write-Host "`n=== COMPARISON ===" -ForegroundColor Magenta
Write-Host "For the app to show the delivery:"
Write-Host "  The ID stored in SharedPreferences (from login)"
Write-Host "  MUST MATCH the delivery_person_id above."
