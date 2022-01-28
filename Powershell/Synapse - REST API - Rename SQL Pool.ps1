<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-01-28

.SYNOPSIS   
   RENAME SYNAPSE DEDICATED POOL
   NOT WORKING YET FOR Synapse Dedicated pool / Only former SQL DW

.DESCRIPTION
       
#> 

$ResourceGroup = "SynapseWorkspace"
$workspaceName = "fonsecanetsynapse"
$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b"
$OldPoolName = "test123"
$NewPoolName = "test456"

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

#POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Synapse/workspaces/{workspaceName}/sqlPools/{sqlPoolName}/move?api-version=2021-06-01
# { "id": "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/Default-SQL-SouthEastAsia/providers/Microsoft.Synapse/workspaces/testsvr/sqlPools/newtestdb" }

$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
$uri += "workspaces/$workspaceName/sqlPools/$OldPoolName/move?api-version=2021-06-01"

$body = "{ ""id"": ""/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/sqlPools/$NewPoolName"" }"

$result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)


$result.properties.connectivityEndpoints.sql
