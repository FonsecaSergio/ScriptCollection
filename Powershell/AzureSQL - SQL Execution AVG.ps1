Clear-Host

$serverName = "fonsecanet.database.windows.net"
$databaseName = "sandbox"
$Username = "FonsecaSergio"

if ($Password -eq $null) {
    $Password = Read-Host "Enter Pass" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))     
}
#Remove-Variable Password

#Get from KeyVault
#$Password = (Get-AzKeyVaultSecret -VaultName FonsecanetKeyVault -Name AzureSQLDBPassword).SecretValueText

$query = "SELECT 1"
$LoopCount = 5


########################################################################################################
$ignore1execforAvg = $true
$ConnectionTimeout = 15
$connectionString = "Server=tcp:$($serverName);Initial Catalog=$($databaseName);Persist Security Info=False;User ID=$($Username);Password=$($Password);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=$($ConnectionTimeout)"

$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
$connection.StatisticsEnabled = 1

Write-Host "Connection to Server ($($serverName)) / DB ($($databaseName)) / UserName ($($Username))"
[System.Collections.ArrayList]$arrayLatency = @()

Try{
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.CommandTimeout = 60
    $command.CommandText = $query
    $command.Connection=$connection

    $aux = 0
    while ($aux -le $LoopCount)
    {

        $stopwatch = [system.diagnostics.stopwatch]::StartNew()
        $connection.Open() 
        $result = $command.ExecuteScalar() 
        Write-Host "Query success - Result ($($result))"

        $connection.Close() 

        $stopwatch.Stop()

        if($ignore1execforAvg -and $aux -eq 0)
        {
            write-Output ("FIRST EXECUTION WILL BE IGNORED for 1 - AVG - Stopwatch latency (ms): $($stopwatch.ElapsedMilliseconds)")
        }
        else
        {
            $arrayLatency.Add($stopwatch.ElapsedMilliseconds) | Out-Null

            write-Output ("Exec ($($aux)) Stopwatch latency (ms): $($stopwatch.ElapsedMilliseconds)")

            $data = $connection.RetrieveStatistics()
            write-Output "-------------------------"
            write-Output ("NetworkServerTime (ms): $($data.NetworkServerTime)")
            write-Output ("Execution Time (ms) : $($data.ExecutionTime)")
            write-Output ("Connection Time : $($data.ConnectionTime)")
            write-Output ("ServerRoundTrips : $($data.ServerRoundtrips)")
            write-Output ("BuffersReceived : $($data.BuffersReceived)")
            write-Output ("SelectRows : $($data.SelectRows)")
            write-Output ("SelectCount : $($data.SelectCount)")
            write-Output ("BytesSent : $($data.BytesSent)")
            write-Output ("BytesReceived : $($data.BytesReceived)")
            write-Output "-------------------------" 
        }

        $connection.ResetStatistics()

        $aux = $aux + 1
    }

    $LatencyAvg = ($arrayLatency | Measure-Object -Average).Average
    write-Output ("Stopwatch AVG latency for $($LoopCount) executions (ms): $($LatencyAvg)")

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