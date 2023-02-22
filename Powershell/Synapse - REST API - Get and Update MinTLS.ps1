<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-02-22

.SYNOPSIS   
   GET SYNAPSE MIN TLS and CHANGE IT

.DESCRIPTION
       
#> 

$ResourceGroup = "SynapseWorkspace"
$workspaceName = "fonsecanetsynapse"
$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

########################################################################################################
#CONNECT TO AZURE

#Connect-AzAccount -Subscription $SubscriptionId
#Below process will authenticate with your current windows account

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    Connect-AzAccount -Subscription $SubscriptionId
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Id -ne $SubscriptionId) {
        $result = Select-AzSubscription -Subscription $SubscriptionId
        Write-Host "Current subscription is $($result.Subscription.Name)"
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
    }
}
########################################################################################################

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------

########################################################################################################
#GET
#https://learn.microsoft.com/en-us/rest/api/synapse/sqlserver/workspace-managed-sql-server-dedicated-sql-minimal-tls-settings/get?tabs=HTTP

$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
$uri += "workspaces/$workspaceName/"
$uri += "dedicatedSQLminimalTlsSettings/default?api-version=2021-06-01"

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)

$result.properties.connectivityEndpoints.sql

########################################################################################################
#UPDATE
#https://learn.microsoft.com/en-us/rest/api/synapse/sqlserver/workspace-managed-sql-server-dedicated-sql-minimal-tls-settings/update?tabs=HTTP

$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
$uri += "workspaces/$workspaceName/"
$uri += "dedicatedSQLminimalTlsSettings/default?api-version=2021-06-01"

$Body = @"
{
    "properties": {
      "minimalTlsVersion": "1.2"
    }
  }
"@

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $Body

Write-Host ($result | ConvertTo-Json)

$result.properties.connectivityEndpoints.sql



