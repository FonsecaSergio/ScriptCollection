<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2025-07-22

.SYNOPSIS   
   GET SYNAPSE MIN TLS and CHANGE IT

.DESCRIPTION
2025-7-22 - Script now loop throgh all subscription workspaces
       
#> 

$ResourceGroup = "ALL" # change to your resource group name or leave ALL to loop through all workspaces in the subscription
$workspaceName = "ALL" # change to your Synapse Workspace name or leave ALL to loop through all workspaces in the resource group
$SubscriptionId = "5f5f53cb-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # change to your subscription ID

$UpdateMinTLS = $false # change to $true if you want to update the Min TLS version

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts -MinimumVersion 5.0.0
Import-Module Az.Synapse

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
# Get Bearer token for current user for Synapse Workspace API
$secureToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com" -AsSecureString).Token
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Securetoken)
try {
    $access_token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} 
finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr) 
}
$headers = @{ Authorization = "Bearer $access_token" }


########################################################################################################
# Get Synapse Workspaces
if ($workspaceName -eq "ALL") {
    if ($ResourceGroup -eq "ALL") {
        $synapseWorkspaces = Get-AzSynapseWorkspace
    }
    else {
        $synapseWorkspaces = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroup
    }
} else 
{
    $synapseWorkspaces = Get-AzSynapseWorkspace -Name $workspaceName
}

########################################################################################################
# Loop through each Synapse Workspace and get the Min TLS settings

foreach ($workspace in $synapseWorkspaces) {
    Write-Host "--------------------------------------------------------------------"    
    $workspaceName = $workspace.Name
    $ResourceGroup = $workspace.Id.Split('/')[4] # Extract Resource Group from the workspace ID    
    Write-Host "Checking workspace: ($workspaceName) in Resource Group: ($ResourceGroup)"


    ########################################################################################################
    #GET
    #https://learn.microsoft.com/en-us/rest/api/synapse/sqlserver/workspace-managed-sql-server-dedicated-sql-minimal-tls-settings/get?tabs=HTTP

    $uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
    $uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
    $uri += "workspaces/$workspaceName/"
    $uri += "dedicatedSQLminimalTlsSettings/default?api-version=2021-06-01"

    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

    Write-Host "Current Min TLS version: $($result.properties.minimalTlsVersion)"

    Write-Host ($result | ConvertTo-Json)



    ########################################################################################################
    #UPDATE
    #https://learn.microsoft.com/en-us/rest/api/synapse/sqlserver/workspace-managed-sql-server-dedicated-sql-minimal-tls-settings/update?tabs=HTTP

    $uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
    $uri += "resourceGroups/$ResourceGroup/providers/Microsoft.Synapse/"
    $uri += "workspaces/$workspaceName/"
    $uri += "dedicatedSQLminimalTlsSettings/default?api-version=2021-06-01"

    $Body = @"
{
    "properties": {
      "minimalTlsVersion": "1.2"
    }
  }
"@

    # Update the Min TLS version if $UpdateMinTLS is true - otherwise skip
    if ($UpdateMinTLS)
    {
        Write-Host "Updating Min TLS version to 1.2"
        $result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $Body

        Write-Host ($result | ConvertTo-Json)

        $result.properties.connectivityEndpoints.sql

    } else {
        Write-Host "--------------------------------------------------------------------"
        Write-Host "Not updating Min TLS version"
        Write-Host "To update the Min TLS version, set the \$UpdateMinTLS variable to \$true"
        Write-Host "--------------------------------------------------------------------"
        continue
    }

}




