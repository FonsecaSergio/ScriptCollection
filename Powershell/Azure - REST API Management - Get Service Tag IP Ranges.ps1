<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-11-20

.SYNOPSIS   
    Get Service Tag IP Ranges for Azure Services

.DESCRIPTION
     
#> 

$SubscriptionId = "de41dc76XXXXXXXXXXXXXXXXXXX"
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

#https://docs.microsoft.com/en-us/rest/api/synapse/workspaces/get

$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Network/locations/westeurope/serviceTags?api-version=2023-05-01"

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)


($result.values | where name -EQ "PowerBI").properties.addressPrefixes