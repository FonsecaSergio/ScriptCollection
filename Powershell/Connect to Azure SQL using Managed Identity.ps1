#CREATE USER [VMSQLCLient] from EXTERNAL PROVIDER
#ALTER ROLE db_datareader ADD MEMBER [VMSQLCLient]
#ALTER ROLE db_datawriter ADD MEMBER [VMSQLCLient]
#GRANT EXECUTE TO [VMSQLCLient]



$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdatabase.windows.net%2F' -Method GET -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$AccessToken = $content.access_token

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=tcp:SERVERNAME.database.windows.net,1433;Initial Catalog=sandbox;Persist Security Info=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=5;"
$SqlConnection.AccessToken = $AccessToken

try
{
    $SqlConnection.Open()

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = "SELECT SERVERNAME = @@SERVERNAME, SUSER_SNAME = SUSER_SNAME();"
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) | Out-Null

    Write-Host "Success Connection @@SERVERNAME = $($DataSet.Tables[0].Rows[0].SERVERNAME) / SUSER_SNAME = $($DataSet.Tables[0].Rows[0].SUSER_SNAME)" -ForegroundColor Green

    $SqlConnection.Close()
}
catch
{
  Write-Host "An error occurred:" -ForegroundColor Red
  Write-Host $_ -ForegroundColor Red
}
