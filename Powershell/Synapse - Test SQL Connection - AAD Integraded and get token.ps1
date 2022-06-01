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
# https://docs.microsoft.com/en-us/sql/powershell/sql-server-powershell       

Can decrypt token at https://jwt.ms/

#> 

# ------------------------------------------

$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b"
$Servername = "xxxxxxxxxxxx.sql.azuresynapse.net"
$DatabaseName = "yyyyyyyyyyyy"

# ------------------------------------------

Import-Module Az.Accounts 
Import-Module SqlServer

########################################################################################################
#CONNECT TO AZURE

Connect-AzAccount -Subscription $SubscriptionId
########################################################################################################

$token = (Get-AzAccessToken -Resource "https://database.windows.net").Token
########################################################################################################
Write-Output "AAD TOKEN: $($token)"
Write-Output "------------------"
Write-Output "Current UTC time: $([datetime]::Now.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"))"

Invoke-Sqlcmd `
    -AccessToken $token `
    -ServerInstance $Servername `
    -Database $DatabaseName `
    -Query "SELECT SQLTIME = GETDATE()"
