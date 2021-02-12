<#
ACTIVATE SYNAPSE WORKSPACE
NOT FULLY TESTED
#>

$workspaceName = "fonsecanetcmk"
$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"
$ResourceGroup = "testCMK"
$keyName = "AzureSQLDBKey"
$vaultName = "FonsecanetKeyVault"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

# ------------------------------------------
function Get-AccessToken([string]$TokenAudience) {

    $currentAzureContext = Get-AzContext

    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate( `
            $currentAzureContext.Account `
            , $currentAzureContext.Environment `
            , $currentAzureContext.Tenant.Id `
            , $null `
            , [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never `
            , $null `
            , $currentAzureContext.TokenCache `
            , $TokenAudience `
            )

    return $token
}

########################################################################################################
#CONNECT TO AZURE

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    Connect-AzAccount -Subscription $SubscriptionName
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Name -ne $SubscriptionName) {
        $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
        Select-AzSubscription -Subscription $Subscription.Id | Out-Null
        Write-Host "Current subscription is $($Subscription.Name)"
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
    }    
}
########################################################################################################

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AccessToken -TokenAudience "https://management.azure.com").AccessToken
$headers = @{ Authorization = "Bearer $token" }

# ------------------------------------------
$uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/keys/$($keyName)?api-version=2019-06-01-preview"

$body = @"
"properties": {
    "keyVaultUrl": "https://$vaultName.vault.azure.net/keys/$keyName"
    "isActiveCMK": true
}
"@

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)
