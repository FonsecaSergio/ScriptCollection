$workspaceName = "FonsecanetSynapse"

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
# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API

#Connect-AzAccount
$token = (Get-AccessToken -TokenAudience "https://dev.azuresynapse.net").AccessToken
$headers = @{ Authorization = "Bearer $token" }

# ------------------------------------------
# https://docs.microsoft.com/en-us/rest/api/synapse/data-plane/sqlpools/list
# GET {endpoint}/sqlPools?api-version=2019-06-01-preview

$uri = "https://$workspaceName.dev.azuresynapse.net/"
$uri += "sqlPools?api-version=2019-06-01-preview"

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers
$result

# with Body
    # https://docs.microsoft.com/rest/api/synapse/data-plane/createroleassignment/createroleassignment
    # POST {endpoint}/rbac/roleAssignments?api-version=2020-02-01-preview
    #$body = @{ roleId = $workspaceAdminRole; principalId = $principalId; } | ConvertTo-Json -Compress
    #Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body


