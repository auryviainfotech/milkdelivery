$headers = @{ 
    "Authorization" = "Bearer sbp_489fd03f475007933447670bf67e17246db236fe"
    "Content-Type" = "application/json" 
}

$projectRef = "qxwjtbhyywwpcehwhegz"
$apiUrl = "https://api.supabase.com/v1/projects/$projectRef/database/query"

$sql = "
-- Enable RLS (ensure it is on)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing overlapping policies if any (to avoid conflicts)
DROP POLICY IF EXISTS ""Public profiles are viewable by everyone"" ON public.profiles;
DROP POLICY IF EXISTS ""Allow public read access"" ON public.profiles;

-- Create permissive SELECT policy
CREATE POLICY ""Allow public read access""
ON public.profiles
FOR SELECT
USING (true);

-- Ensure Insert/Update is still restricted (usually handled by existing policies, but good to be safe)
-- We only open SELECT.
"

$body = @{ query = $sql } | ConvertTo-Json -Depth 10

try {
    Write-Host "Applying RLS fix for 'profiles'..." -ForegroundColor Cyan
    $result = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
    Write-Host "SUCCESS: RLS Policy Applied" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
