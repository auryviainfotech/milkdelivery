$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"
$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== FINAL ID COMPARISON ===" -ForegroundColor Cyan
Write-Host "Today: $today" -ForegroundColor Yellow

# 1. Get ALL delivery persons with FULL IDs
Write-Host "`n1. All Delivery Persons in DB:" -ForegroundColor Yellow
$sql = "SELECT id, full_name, phone, role FROM public.profiles WHERE role = 'delivery';"
$body = @{ query = $sql } | ConvertTo-Json
$persons = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
$persons | ForEach-Object {
    Write-Host "  Name: $($_.full_name)"
    Write-Host "  Phone: $($_.phone)"
    Write-Host "  ID: $($_.id)" -ForegroundColor Green
    Write-Host ""
}

# 2. Get today's delivery with assigned person ID
Write-Host "2. Today's Deliveries:" -ForegroundColor Yellow
$sql = "SELECT id, delivery_person_id, status, scheduled_date FROM public.deliveries WHERE scheduled_date = '$today';"
$body = @{ query = $sql } | ConvertTo-Json
$deliveries = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
if ($deliveries) {
    $deliveries | ForEach-Object {
        Write-Host "  Delivery ID: $($_.id)"
        Write-Host "  delivery_person_id: $($_.delivery_person_id)" -ForegroundColor Green
        Write-Host "  Status: $($_.status)"
        Write-Host ""
    }
} else {
    Write-Host "  NO DELIVERIES FOR TODAY!" -ForegroundColor Red
}

# 3. Cross-check: Does any delivery person ID match today's delivery assignment?
Write-Host "3. MATCH CHECK:" -ForegroundColor Yellow
if ($deliveries -and $persons) {
    $match = $false
    $deliveries | ForEach-Object {
        $dpId = $_.delivery_person_id
        $matchPerson = $persons | Where-Object { $_.id -eq $dpId }
        if ($matchPerson) {
            Write-Host "  MATCH FOUND: Delivery assigned to '$($matchPerson.full_name)'" -ForegroundColor Green
            Write-Host "  Their ID: $dpId"
            Write-Host "  Their Phone: $($matchPerson.phone)"
            $match = $true
        }
    }
    if (-not $match) {
        Write-Host "  NO MATCH! delivery_person_id doesn't match any delivery person in profiles!" -ForegroundColor Red
    }
}

Write-Host "`n=== ACTION REQUIRED ===" -ForegroundColor Magenta
Write-Host "When you log in to the Delivery App, make sure you enter the phone number"
Write-Host "that matches the delivery person assigned to today's delivery."
Write-Host "The app stores the profile ID after login, which must match delivery_person_id."
