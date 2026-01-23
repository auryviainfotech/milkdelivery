$headers = @{ 
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2p0Ymh5eXd3cGNlaHdoZWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MjMyNDYsImV4cCI6MjA1MzA5OTI0Nn0.xbMXTOGYEHxwhLI2R1E5Gu9OrMFQ4rE3B06Ib1c14rk"
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2p0Ymh5eXd3cGNlaHdoZWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MjMyNDYsImV4cCI6MjA1MzA5OTI0Nn0.xbMXTOGYEHxwhLI2R1E5Gu9OrMFQ4rE3B06Ib1c14rk"
    "Content-Type" = "application/json"
}

$supabaseUrl = "https://qxwjtbhyywwpcehwhegz.supabase.co"
$today = Get-Date -Format "yyyy-MM-dd"
$bilalId = "bcef3e1c-3893-4ec8-a103-7de6dffbe78e"

$url = "$supabaseUrl/rest/v1/deliveries?select=id,order_id,scheduled_date,status,delivery_person_id&delivery_person_id=eq.$bilalId&scheduled_date=eq.$today"

try {
    $result = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    $result | ConvertTo-Json -Depth 3 | Out-File -FilePath "anon_result.json" -Encoding UTF8
    Write-Host "Success - check anon_result.json"
} catch {
    $_.Exception | Out-File -FilePath "anon_error.txt" -Encoding UTF8
    try {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $reader.ReadToEnd() | Out-File -FilePath "anon_error_body.txt" -Encoding UTF8
    } catch {}
    Write-Host "Error - check anon_error.txt and anon_error_body.txt"
}
