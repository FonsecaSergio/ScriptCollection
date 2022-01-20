<#
ACTIVATE SYNAPSE WORKSPACE
#>

$workspaceName = "fonsecanetcmk"
$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b"
$ResourceGroup = "testCMK"
$keyName = "AzureSQLDBKey"
$vaultName = "FonsecanetKeyVault"

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
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resgroup/providers/Microsoft.Synapse/workspaces/$($workspaceName)?api-version=2019-06-01-preview"
$uri
$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

$InternalkeyName = $result.properties.encryption.cmk.key.name

########################################################################################################

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
$headers = @{ Authorization = "Bearer $token" }

# ------------------------------------------
$uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/keys/$($InternalkeyName)?api-version=2019-06-01-preview"
$uri

$body = @"
{
    "name" : "$keyName",
    "properties": {
       "keyVaultUrl": "https://$vaultName.vault.azure.net/keys/$keyName",
       "isActiveCMK": true
    }
}
"@
$body

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)
