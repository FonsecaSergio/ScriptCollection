<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-01-20

.SYNOPSIS   
   UPDATE AUTORESOLVEINTEGRATIONRUNTIME

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

#PUT https://management.azure.com/subscriptions/<subId>/resourcegroups/<resgroup>/providers/Microsoft.Synapse/workspaces/<workspacename>/integrationruntimes/IR1?api-version=2019-06-01-preview
#{"name":"AzureIntegrationRuntime","properties":{"type":"Managed","typeProperties":{"computeProperties":{"location":"AutoResolve","dataFlowProperties":{"computeType":"General","coreCount":8,"timeToLive":0,"cleanup":false}}}}}

$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
$uri += "workspaces/$workspaceName/integrationruntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"

$body = "{""name"":""AutoResolveIntegrationRuntime"",""properties"":{""type"":""Managed"",""typeProperties"":{""computeProperties"":{""location"":""AutoResolve"",""dataFlowProperties"":{""computeType"":""General"",""coreCount"":8,""timeToLive"":0,""cleanup"":false}}}}}"

$result = Invoke-RestMethod -Method PUT -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)

