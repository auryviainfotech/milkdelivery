$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== CLEANING UP CUSTOMERS ===" -ForegroundColor Cyan
Write-Host "Keeping 'Hafsiya', Admin, and Delivery persons."
Write-Host "Deleting all other CUSTOMERS." -ForegroundColor Yellow

# 1. Find Hafsiya's ID
$sql = "SELECT id, full_name, role FROM public.profiles WHERE full_name ILIKE '%hafsiya%';"
$body = @{ query = $sql } | ConvertTo-Json
$hafsiya = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if (-not $hafsiya) {
    Write-Host "ERROR: Could not find user 'Hafsiya'!" -ForegroundColor Red
    exit
}

$hafsiyaId = $hafsiya.id
Write-Host "Found Hafsiya: $($hafsiya.full_name) ($hafsiyaId)" -ForegroundColor Green

# 2. Find Customers to Delete (Exclude Hafsiya)
# We only delete role = 'customer' to be safe (preserve admin/delivery)
$sql = "SELECT id, full_name FROM public.profiles WHERE role = 'customer' AND id != '$hafsiyaId';"
$body = @{ query = $sql } | ConvertTo-Json
$toDelete = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if (-not $toDelete -or $toDelete.Count -eq 0) {
    Write-Host "No other customers found to delete." -ForegroundColor Green
    exit
}

Write-Host "Found $($toDelete.Count) customers to delete." -ForegroundColor Yellow
$ids = $toDelete | ForEach-Object { "'$($_.id)'" }
$idsStr = $ids -join ","

# 3. Delete Data (Order matters due to FKs)
# Deliveries -> Orders -> Subscriptions -> Profiles

# We need to find orders/subscriptions belonging to these users
# But easier to just cascade delete if possible, or do manual clean up.
# Since we don't have CASCADE ON DELETE setup guaranteed, we delete manually.

Write-Host "Deleting data for $($toDelete.Count) users..."

# Delete Deliveries (via Orders)
$sql = "DELETE FROM public.deliveries WHERE order_id IN (SELECT id FROM public.orders WHERE user_id IN ($idsStr));"
$body = @{ query = $sql } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "  Deleted related Deliveries" -ForegroundColor Gray
} catch { Write-Host "  Error deleting deliveries: $_" -ForegroundColor Red }

# Delete Orders
$sql = "DELETE FROM public.orders WHERE user_id IN ($idsStr);"
$body = @{ query = $sql } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "  Deleted related Orders" -ForegroundColor Gray
} catch { Write-Host "  Error deleting orders: $_" -ForegroundColor Red }

# Delete Subscriptions
$sql = "DELETE FROM public.subscriptions WHERE user_id IN ($idsStr);"
$body = @{ query = $sql } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "  Deleted related Subscriptions" -ForegroundColor Gray
} catch { Write-Host "  Error deleting subscriptions: $_" -ForegroundColor Red }

# Delete Profiles
$sql = "DELETE FROM public.profiles WHERE id IN ($idsStr);"
$body = @{ query = $sql } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "  Deleted Profiles" -ForegroundColor Green
} catch { Write-Host "  Error deleting profiles: $_" -ForegroundColor Red }

Write-Host "`n=== CLEANUP COMPLETE ===" -ForegroundColor Cyan
