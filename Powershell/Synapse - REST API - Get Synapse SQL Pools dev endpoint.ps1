<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-03-11

.SYNOPSIS   
   GET SYNAPSE SQL POOLS FROM SYNAPSE DEV ENDPOINT

.DESCRIPTION
    
#> 

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
$token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------

# https://docs.microsoft.com/en-us/rest/api/synapse/data-plane/sqlpools/list
# GET {endpoint}/sqlPools?api-version=2019-06-01-preview

$uri = "https://$workspaceName.dev.azuresynapse.net/"
$uri += "sqlPools?api-version=2019-06-01-preview"

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)


