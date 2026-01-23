$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== DAILY DIAGNOSTIC: $today ===" -ForegroundColor Cyan

# 1. Check for ANY deliveries today
Write-Host "`n1. Checking Deliveries for Today ($today):" -ForegroundColor Yellow
$sql = "SELECT id, delivery_person_id, status FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    if ($result -and $result.Count -gt 0) {
        Write-Host "  Found $($result.Count) deliveries for today." -ForegroundColor Green
        $result | ForEach-Object {
            Write-Host "  - ID: $($_.id) | Person: $($_.delivery_person_id) | Status: $($_.status)"
        }
    } else {
        Write-Host "  NO DELIVERIES FOUND FOR TODAY!" -ForegroundColor Red
        Write-Host "  Action: You need to generate orders for today in the Admin Panel." -ForegroundColor Gray
    }
} catch {
    Write-Host "  ERROR Querying Deliveries: $_" -ForegroundColor Red
}

# 2. Check Bilal's ID
Write-Host "`n2. Verifying Bilal's ID:" -ForegroundColor Yellow
$sql = "SELECT id FROM public.profiles WHERE phone LIKE '%7993619422%';"
$body = @{ query = $sql } | ConvertTo-Json
$bilal = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($bilal) {
    Write-Host "  Bilal ID: $($bilal.id)" -ForegroundColor Green
} else {
    Write-Host "  Bilal profile not found!" -ForegroundColor Red
}

# 3. Check RLS Status (Quick Check)
Write-Host "`n3. RLS Status Check (Deliveries):" -ForegroundColor Yellow
$sql = "SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'deliveries';"
$body = @{ query = $sql } | ConvertTo-Json
$rls = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($rls) {
    Write-Host "  Table 'deliveries' RLS: $($rls.rowsecurity)" -ForegroundColor $(if ($rls.rowsecurity -eq $false) { "Green" } else { "Red" })
}
