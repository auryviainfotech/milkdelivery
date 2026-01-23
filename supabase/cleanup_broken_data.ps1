# Cleanup script for broken delivery person data
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

Write-Host "=== CLEANUP BROKEN DATA ===" -ForegroundColor Cyan

# 1. Find orphaned delivery person IDs in customer profiles
Write-Host "`n1. Checking for orphaned assigned_delivery_person_id in customers..." -ForegroundColor Yellow
$orphanedAssignments = Invoke-SQL "
SELECT p.id, p.full_name, p.assigned_delivery_person_id 
FROM profiles p 
WHERE p.role = 'customer' 
AND p.assigned_delivery_person_id IS NOT NULL 
AND NOT EXISTS (SELECT 1 FROM profiles dp WHERE dp.id = p.assigned_delivery_person_id);
"
if ($orphanedAssignments -and $orphanedAssignments.Count -gt 0) {
    Write-Host "   Found $($orphanedAssignments.Count) customers with orphaned assignments" -ForegroundColor Red
    foreach ($c in $orphanedAssignments) {
        Write-Host "   - $($c.full_name) -> $($c.assigned_delivery_person_id)"
    }
    
    # Clear orphaned assignments
    Write-Host "`n   Clearing orphaned assignments..." -ForegroundColor Yellow
    Invoke-SQL "UPDATE profiles SET assigned_delivery_person_id = NULL WHERE role = 'customer' AND assigned_delivery_person_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles dp WHERE dp.id = profiles.assigned_delivery_person_id);"
    Write-Host "   DONE" -ForegroundColor Green
} else {
    Write-Host "   No orphaned assignments found" -ForegroundColor Green
}

# 2. Find deliveries with non-existent delivery person IDs
Write-Host "`n2. Checking for deliveries with orphaned delivery_person_id..." -ForegroundColor Yellow
$orphanedDeliveries = Invoke-SQL "
SELECT d.id, d.delivery_person_id, d.scheduled_date 
FROM deliveries d 
WHERE d.delivery_person_id IS NOT NULL 
AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = d.delivery_person_id);
"
if ($orphanedDeliveries -and $orphanedDeliveries.Count -gt 0) {
    Write-Host "   Found $($orphanedDeliveries.Count) deliveries with orphaned person IDs" -ForegroundColor Red
    
    # Delete orphaned deliveries
    Write-Host "`n   Deleting orphaned deliveries..." -ForegroundColor Yellow
    Invoke-SQL "DELETE FROM deliveries WHERE delivery_person_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = deliveries.delivery_person_id);"
    Write-Host "   DONE" -ForegroundColor Green
} else {
    Write-Host "   No orphaned deliveries found" -ForegroundColor Green
}

# 3. Delete orders without deliveries
Write-Host "`n3. Checking for orders without deliveries..." -ForegroundColor Yellow
$orphanedOrders = Invoke-SQL "
SELECT o.id FROM orders o 
WHERE NOT EXISTS (SELECT 1 FROM deliveries d WHERE d.order_id = o.id);
"
if ($orphanedOrders -and $orphanedOrders.Count -gt 0) {
    Write-Host "   Found $($orphanedOrders.Count) orders without deliveries" -ForegroundColor Red
    
    # Delete order_items first
    Write-Host "`n   Deleting orphaned order_items..." -ForegroundColor Yellow
    Invoke-SQL "DELETE FROM order_items WHERE order_id IN (SELECT o.id FROM orders o WHERE NOT EXISTS (SELECT 1 FROM deliveries d WHERE d.order_id = o.id));"
    
    # Delete orders
    Write-Host "   Deleting orphaned orders..." -ForegroundColor Yellow
    Invoke-SQL "DELETE FROM orders WHERE NOT EXISTS (SELECT 1 FROM deliveries d WHERE d.order_id = orders.id);"
    Write-Host "   DONE" -ForegroundColor Green
} else {
    Write-Host "   No orphaned orders found" -ForegroundColor Green
}

# 4. Delete orphaned delivery auth users
Write-Host "`n4. Checking for orphaned delivery auth users..." -ForegroundColor Yellow
$orphanedAuth = Invoke-SQL "
SELECT au.id, au.email 
FROM auth.users au 
WHERE au.email LIKE 'delivery_%' 
AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = au.id);
"
if ($orphanedAuth -and $orphanedAuth.Count -gt 0) {
    Write-Host "   Found $($orphanedAuth.Count) orphaned auth users" -ForegroundColor Red
    foreach ($a in $orphanedAuth) {
        Write-Host "   - $($a.email)"
    }
    
    Write-Host "`n   Deleting orphaned auth users..." -ForegroundColor Yellow
    Invoke-SQL "DELETE FROM auth.users WHERE email LIKE 'delivery_%' AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.users.id);"
    Write-Host "   DONE" -ForegroundColor Green
} else {
    Write-Host "   No orphaned auth users found" -ForegroundColor Green
}

Write-Host "`n=== CLEANUP COMPLETE ===" -ForegroundColor Cyan
