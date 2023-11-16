<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-06-01

.SYNOPSIS   
   Test AAD authentication using powershell and print AAD Auth token

.PARAMETER SubscriptionId
.PARAMETER Servername
.PARAMETER DatabaseName

.DESCRIPTION
# these Az modules are required
# https://docs.microsoft.com/powershell/azure/install-az-ps

Can decrypt token at https://jwt.ms/

#> 

# ------------------------------------------

$SubscriptionId = "de41dc76XXXXXXXXXXXXXXXXXXX"
$Servername = "xxxxxxxxxx.sql.azuresynapse.net"
$DatabaseName = "yyyyyyyyyyy"

# ------------------------------------------

Import-Module Az.Accounts 

########################################################################################################
#CONNECT TO AZURE

Connect-AzAccount -Subscription $SubscriptionId
########################################################################################################

$token = (Get-AzAccessToken -Resource "https://database.windows.net").Token
########################################################################################################
Write-Output "AAD TOKEN"
Write-Output "------------------"
Write-Output $token
Write-Output "------------------"


#######################################################################################################################################################################################################################################################
$connectionString = "Server=tcp:$($Servername);Initial Catalog=$($DatabaseName);Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection($connectionString)
$connection.AccessToken = $token
$connection.StatisticsEnabled = 1 

Write-Host "CurrentTime UTC: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ss")) UTC"
Write-Host "Connection to Server ($($Servername)) / DB ($($DatabaseName))"

Try{
    
    $connection.Open()    
    Write-Host "Connection with success ClientConnectionId($($connection.ClientConnectionId))"

    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.CommandTimeout = 60
    $command.Connection=$connection

    $command.CommandText = "Select getdate() as NOW"
    $result = $command.ExecuteScalar()    
    Write-Host "Query success. Server currenttime ($($result))"
 
    Write-Host "CurrentTime UTC: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ss")) UTC"
    $connection.Close()

}
catch [System.Data.SqlClient.SqlException]
{
    #$_.Exception.Errors[0] | Out-Host

    $ExceptionMessage = "SQL Exception: ($($_.Exception.Number)) / State: ($($_.Exception.State)) / $($_.Exception.Message)"    
    Write-Error $ExceptionMessage    
    Write-Host "Exception.ClientConnectionId ($($_.Exception.ClientConnectionId))"
    Write-Host "CurrentTime UTC: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ss")) UTC"
}
Catch
{
    Write-Error $_.Exception.Message
}

