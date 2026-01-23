$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== CURRENT DATABASE STATE ===" -ForegroundColor Cyan

# Count customers
$sql = "SELECT COUNT(*) as count FROM public.profiles WHERE role = 'customer';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Customers: $($result.count)" -ForegroundColor Yellow

# List customer names
$sql = "SELECT id, full_name FROM public.profiles WHERE role = 'customer';"
$body = @{ query = $sql } | ConvertTo-Json
$customers = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Customer Names:"
$customers | ForEach-Object { Write-Host "  - $($_.full_name)" }

# Count subscriptions
$sql = "SELECT COUNT(*) as count FROM public.subscriptions;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "`nTotal Subscriptions: $($result.count)" -ForegroundColor Yellow

# Count active subscriptions
$sql = "SELECT COUNT(*) as count FROM public.subscriptions WHERE status = 'active';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Active Subscriptions: $($result.count)" -ForegroundColor Yellow

# Count deliveries
$sql = "SELECT COUNT(*) as count FROM public.deliveries;"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "`nTotal Deliveries: $($result.count)" -ForegroundColor Yellow

# Today's deliveries
$sql = "SELECT COUNT(*) as count FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
Write-Host "Today's Deliveries ($today): $($result.count)" -ForegroundColor Yellow

Write-Host "`n=== END ===" -ForegroundColor Cyan
