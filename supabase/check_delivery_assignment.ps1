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
        $result | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "=== DELIVERY PERSONS ===" -ForegroundColor Cyan
Invoke-SQL "SELECT id, full_name, phone, service_pin_codes, qr_code FROM public.profiles WHERE role = 'delivery';"

Write-Host "`n=== DELIVERIES FOR TOMORROW ===" -ForegroundColor Cyan
Invoke-SQL "SELECT d.id, d.status, d.delivery_person_id, d.scheduled_date, p.full_name as person_name FROM public.deliveries d LEFT JOIN public.profiles p ON d.delivery_person_id = p.id ORDER BY d.scheduled_date DESC;"
