#CREATE USER VMSQLCLient from EXTERNAL PROVIDER
#ALTER ROLE db_ddladmin ADD MEMBER VMSQLCLient
#ALTER ROLE db_datareader ADD MEMBER VMSQLCLient


$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdatabase.windows.net%2F' -Method GET -Headers @{Metadata="true"}

$content = $response.Content | ConvertFrom-Json

$AccessToken = $content.access_token

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source = fonsecanet.database.windows.net; Initial Catalog = sandbox"
$SqlConnection.AccessToken = $AccessToken
$SqlConnection.Open()

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "SELECT @@SERVERNAME;"
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

$SqlCmd.CommandText = "DROP SCHEMA IF EXISTS XPTO;"
##$SqlConnection.Open()
$SqlCmd.ExecuteNonQuery()

$SqlCmd.CommandText = "CREATE SCHEMA XPTO"
##$SqlConnection.Open()
$SqlCmd.ExecuteNonQuery()
$SqlConnection.Close()