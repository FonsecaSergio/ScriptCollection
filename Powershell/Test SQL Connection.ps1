Clear-Host

$DatabaseServer = "xxxxxxx.database.windows.net,1433"
$Database = "master"
$Username = "xxxxxx"
$Password = "xxxxxx" 

$connectionString = "Server=tcp:$DatabaseServer;Initial Catalog=$Database;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
$connection.StatisticsEnabled = 1 

Write-Host "CurrentTime: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ss")) UTC"

Try{
    $connection.Open()    
    Write-Host "Connection with success ClientConnectionId($($connection.ClientConnectionId)) / Server ($($DatabaseServer)) / DB ($($Database))"

    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.CommandTimeout = 60
    $command.Connection=$connection

    $command.CommandText = "Select getdate() as NOW"
    $result = $command.ExecuteScalar()    
    Write-Host "Query sucess. Server currenttime ($($result))"
    
    $connection.Close()

    

    $data = $connection.RetrieveStatistics()
    write-Output "-------------------------"
    write-Output ("NetworkServerTime (ms):  " +$data.NetworkServerTime)
    write-Output ("Execution Time (ms)   :  " +$data.ExecutionTime)
    write-Output ("Connection Time       :  " +$data.ConnectionTime)
    write-Output ("ServerRoundTrips      :  " +$data.ServerRoundtrips)
    write-Output ("BuffersReceived       :  " +$data.BuffersReceived)
    write-Output ("SelectRows            :  " +$data.SelectRows)
    write-Output ("SelectCount           :  " +$data.SelectCount)
    write-Output ("BytesSent             :  " +$data.BytesSent)
    write-Output ("BytesReceived         :  " +$data.BytesReceived)
    write-Output "-------------------------"   

}
catch [System.Data.SqlClient.SqlException]
{
    $ExceptionMessage = "SQL Exception: ($($_.Exception.Number)) / State: ($($_.Exception.State)) / ClientConnectionId($($connection.ClientConnectionId)) / $($_.Exception.Message)"
    Write-Error $ExceptionMessage
}
Catch
{
    Write-Error $_.Exception.Message
}

$MyPublicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$MyPrivateIP = Get-NetIPAddress | SELECT IPAddress | Sort-Object -Property IPAddress

Write-Host "MyPublicIP: $($MyPublicIP)
"
Write-Host "MyPrivateIP: "
$MyPrivateIP
