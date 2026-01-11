# Apply Admin RLS Policies for wallet_transactions
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
        Write-Host "SUCCESS: Executed SQL" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Details: $($reader.ReadToEnd())"
        }
    }
}

Write-Host "=== Fixing RLS Policies for wallet_transactions ===" -ForegroundColor Cyan

# First, ensure the is_admin function exists
Write-Host "`nCreating is_admin helper function..." -ForegroundColor Yellow
Invoke-SQL "
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS `$`$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    );
END;
`$`$ LANGUAGE plpgsql SECURITY DEFINER;
"

# Drop existing policies on wallet_transactions to recreate them
Write-Host "`nDropping existing wallet_transactions policies..." -ForegroundColor Yellow
Invoke-SQL "DROP POLICY IF EXISTS ""Admins can view all wallet transactions"" ON wallet_transactions;"
Invoke-SQL "DROP POLICY IF EXISTS ""Admins can insert wallet transactions"" ON wallet_transactions;"

# Create admin policies for wallet_transactions
Write-Host "`nCreating admin policies for wallet_transactions..." -ForegroundColor Yellow
Invoke-SQL "
CREATE POLICY ""Admins can view all wallet transactions"" ON wallet_transactions
FOR SELECT USING (is_admin());
"

Invoke-SQL "
CREATE POLICY ""Admins can insert wallet transactions"" ON wallet_transactions
FOR INSERT WITH CHECK (is_admin());
"

# Also ensure wallets table allows admin updates
Write-Host "`nEnsuring admin policies for wallets table..." -ForegroundColor Yellow
Invoke-SQL "DROP POLICY IF EXISTS ""Admins can view all wallets"" ON wallets;"
Invoke-SQL "DROP POLICY IF EXISTS ""Admins can update all wallets"" ON wallets;"
Invoke-SQL "DROP POLICY IF EXISTS ""Admins can insert wallets"" ON wallets;"

Invoke-SQL "CREATE POLICY ""Admins can view all wallets"" ON wallets FOR SELECT USING (is_admin());"
Invoke-SQL "CREATE POLICY ""Admins can update all wallets"" ON wallets FOR UPDATE USING (is_admin());"
Invoke-SQL "CREATE POLICY ""Admins can insert wallets"" ON wallets FOR INSERT WITH CHECK (is_admin());"

Write-Host "`n=== Done! Admin policies applied. ===" -ForegroundColor Green
