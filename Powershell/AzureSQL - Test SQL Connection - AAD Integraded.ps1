Clear-Host

$DatabaseServer = "fonsecanet.database.windows.net,1433"
$Database = "sandbox"


#######################################################################################################################################################################################################################################################
$ConnectionTimeout = 15
$connectionString = "Server=tcp:$DatabaseServer;Initial Catalog=$Database;Authentication=""Active Directory Integrated"";Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=$($ConnectionTimeout)"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
$connection.StatisticsEnabled = 1 

Write-Host "CurrentTime: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ss")) UTC"
Write-Host "Connection to Server ($($DatabaseServer)) / DB ($($Database)) / UserName (Active Directory Integrated)"

Try{
    
    $connection.Open()    
    Write-Host "Connection with success ClientConnectionId($($connection.ClientConnectionId))"

    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.CommandTimeout = 60
    $command.Connection=$connection

    $command.CommandText = "Select getdate() as NOW"
    $result = $command.ExecuteScalar()    
    Write-Host "Query success. Server currenttime ($($result))"
    
    $connection.Close()

}
catch [System.Data.SqlClient.SqlException]
{
    $_.Exception.Errors[0] | Out-Host

    $ExceptionMessage = "SQL Exception: ($($_.Exception.Number)) / State: ($($_.Exception.State)) / $($_.Exception.Message)"    
    Write-Error $ExceptionMessage
    Write-Host "ClientConnectionId($($connection.ClientConnectionId))"
    Write-Host "Exception.ClientConnectionId ($($_.Exception.ClientConnectionId))"
}
Catch
{
    Write-Error $_.Exception.Message
}

