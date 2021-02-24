$workspaceName = "FonsecanetSynapse"
$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

########################################################################################################
#CONNECT TO AZURE

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    $x = Connect-AzAccount -Subscription $SubscriptionName
    $SubscriptionId = $x.Context.Subscription.Id
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Name -ne $SubscriptionName) {
        $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
        Select-AzSubscription -Subscription $Subscription.Id | Out-Null
        Write-Host "Current subscription is $($Subscription.Name)"
        $SubscriptionId = $Subscription.Id
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
        $SubscriptionId = $Context.Subscription.Id
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

# with Body
    # https://docs.microsoft.com/rest/api/synapse/data-plane/createroleassignment/createroleassignment
    # POST {endpoint}/rbac/roleAssignments?api-version=2020-02-01-preview
    #$body = @{ roleId = $workspaceAdminRole; principalId = $principalId; } | ConvertTo-Json -Compress
    #Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body


