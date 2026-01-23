$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$sql = "SELECT id, full_name, phone, role, address as password FROM public.profiles WHERE role = 'delivery' OR role = 'admin';"
$body = @{ query = $sql } | ConvertTo-Json
$result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body

$result | ConvertTo-Json -Depth 5 | Out-File -FilePath "delivery_persons_output.json" -Encoding UTF8
Write-Host "Output saved to delivery_persons_output.json"
