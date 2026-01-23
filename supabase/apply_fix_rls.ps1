# Apply SQL Fix
$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$sql = Get-Content -Path "fix_delivery_rls.sql" -Raw

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Applying RLS fixes..."
    Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "Done!"
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
