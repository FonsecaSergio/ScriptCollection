<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-03-11

.SYNOPSIS   
   GET SYNAPSE ROLES AND ADD NEW ADMIN

.DESCRIPTION
       
#> 

$workspaceName = "SERVERNAME"
$SubscriptionId = "de41dc76XXXXXXXXXXXXXXXXXXX"
$aadUserName = "sefonsec@microsoft.com"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 
Import-Module Az.Resources

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
# https://docs.microsoft.com/en-us/rest/api/synapse/data-plane/role-definitions/list-role-definitions
# GET {endpoint}/roleDefinitions?api-version=2020-12-01

$uri = "https://$workspaceName.dev.azuresynapse.net/"
$uri += "roleDefinitions?api-version=2020-12-01"

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)