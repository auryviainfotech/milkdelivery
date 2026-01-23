$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

Write-Host "=== DEEP CLEAN: PURGING ALL NON-HAFSIYA DATA ===" -ForegroundColor Cyan
Write-Host "Target: Remove everything not related to 'Hafsiya', Admins, or Delivery Staff."

# 1. Get Hafsiya's ID
$sql = "SELECT id, full_name FROM public.profiles WHERE full_name ILIKE '%hafsiya%';"
$body = @{ query = $sql } | ConvertTo-Json
$hafsiya = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

if (-not $hafsiya) {
    Write-Host "ERROR: Hafsiya profile not found! Aborting to prevent total data loss." -ForegroundColor Red
    exit
}
$hafsiyaId = $hafsiya.id
Write-Host "Preserving Customer: $($hafsiya.full_name) ($hafsiyaId)" -ForegroundColor Green

# 2. Delete ALL Deliveries NOT linked to Hafsiya
# Logic: Delete if linked order's user_id != Hafsiya OR if order_id is invalid
Write-Host "Cleaning Deliveries..." -ForegroundColor Yellow
$sql = "DELETE FROM public.deliveries WHERE order_id IN (SELECT id FROM public.orders WHERE user_id != '$hafsiyaId');"
$body = @{ query = $sql } | ConvertTo-Json
try { Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body; Write-Host "  Removed deliveries for other customers" } catch { Write-Host "  Error: $_" }

# Also clean orphan deliveries (no order or bad order)
$sql = "DELETE FROM public.deliveries WHERE order_id IS NULL OR order_id NOT IN (SELECT id FROM public.orders);"
$body = @{ query = $sql } | ConvertTo-Json
try { Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body; Write-Host "  Removed orphan deliveries" } catch { Write-Host "  Error: $_" }


# 3. Delete ALL Orders NOT linked to Hafsiya
Write-Host "Cleaning Orders..." -ForegroundColor Yellow
$sql = "DELETE FROM public.orders WHERE user_id != '$hafsiyaId';"
$body = @{ query = $sql } | ConvertTo-Json
try { Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body; Write-Host "  Removed orders for other customers" } catch { Write-Host "  Error: $_" }


# 4. Delete ALL Subscriptions NOT linked to Hafsiya
Write-Host "Cleaning Subscriptions..." -ForegroundColor Yellow
$sql = "DELETE FROM public.subscriptions WHERE user_id != '$hafsiyaId';"
$body = @{ query = $sql } | ConvertTo-Json
try { Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body; Write-Host "  Removed subscriptions for other customers" } catch { Write-Host "  Error: $_" }


# 5. Delete ALL Customer Profiles (Except Hafsiya)
Write-Host "Cleaning Profiles..." -ForegroundColor Yellow
$sql = "DELETE FROM public.profiles WHERE role = 'customer' AND id != '$hafsiyaId';"
$body = @{ query = $sql } | ConvertTo-Json
try { Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body; Write-Host "  Removed other customer profiles" } catch { Write-Host "  Error: $_" }


Write-Host "`n=== DEEP CLEAN COMPLETE ===" -ForegroundColor Cyan
Write-Host "Only 'Hafsiya' and staff data remains."
