<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-05-09

.SYNOPSIS   
   List ROLE ASSIGNMENTS

.DESCRIPTION
       
#> 

$workspaceName = "SERVERNAME"
$SubscriptionId = "de41dc76XXXXXXXXXXXXXXXXXXX"
$roleassignmentID = "7f38bed6-281a-472a-bec3-8cf8e3c454e5"

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
# https://docs.microsoft.com/en-us/rest/api/synapse/data-plane/role-assignments/delete-role-assignment-by-id
# DELETE {endpoint}/roleAssignments/{roleAssignmentId}?api-version=2020-12-01

$uri = "https://$workspaceName.dev.azuresynapse.net/"
$uri += "/rbac//roleAssignments/$($roleassignmentID)?api-version=2020-12-01"

$result = Invoke-RestMethod -Method DELETE -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)
