<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-11-22

.SYNOPSIS   
    Pause all ADX 
     - Azure Data Explorer Clusters
     - Azure Data Explorer Clusters on Synapse

    Made to run on Automation account with MSI account

.DESCRIPTION
       
#> 

param (
    [bool]$debug = $false
)

$detailedAPIrequests = $true

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 


##########################################################################################################################################################
#Connect using Automation Account
##########################################################################################################################################################

$AzureContext = Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

$SubscriptionId = $AzureContext.Subscription.Id

########################################################################################################

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------


########################################################################################################
#https://learn.microsoft.com/en-us/rest/api/azurerekusto/clusters/list?tabs=HTTP
#GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Kusto/clusters?api-version=2022-07-07

$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "/providers/Microsoft.Kusto/clusters?api-version=2022-07-07"

if ($debug -or $detailedAPIrequests) {
    $uri
}

$result = $null
$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

$ADXClusterList = @($result.value)

foreach ($ADXCluster in $ADXClusterList) {
    Write-Host "Cluster ($($ADXCluster.name)) / State ($($ADXCluster.properties.state))" -ForegroundColor Blue

    if ($ADXCluster.properties.state -eq "Running") {
        Write-Host "Pausing Cluster ($($ADXCluster.name))" -ForegroundColor Yellow

        #Pause
        #https://learn.microsoft.com/en-us/rest/api/azurerekusto/clusters/stop?tabs=HTTP
        #POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Kusto/clusters/{clusterName}/stop?api-version=2022-07-07

        #Start
        #https://learn.microsoft.com/en-us/rest/api/azurerekusto/clusters/start?tabs=HTTP
        #POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Kusto/clusters/{clusterName}/start?api-version=2022-07-07

        $uri = "https://management.azure.com$($ADXCluster.id)/stop?api-version=2022-07-07"

        if ($debug -or $detailedAPIrequests) {
            $uri
        }
        $result = $null
        if ($debug -ne $true) {
            $result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers
        }

        Write-Host "Pause request sent. Check results" -ForegroundColor Yellow
        ($result | ConvertTo-Json)
    }
    else {
        Write-Host "No action done as cluster state is not running but ($($ADXCluster.properties.state))"
    }
}




########################################################################################################
#Synapse ADX Cluster

#https://learn.microsoft.com/en-us/rest/api/synapse/workspaces/list?tabs=HTTP
#GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01
$uri = "https://management.azure.com/subscriptions/$SubscriptionID/"
$uri += "providers/Microsoft.Synapse/workspaces?api-version=2021-06-01"

if ($debug -or $detailedAPIrequests) {
    $uri
}

$result = $null
$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

$SynapseWorkspacesList = @($result.value)

foreach ($SynapseWorkspace in $SynapseWorkspacesList) {
    Write-Host "Checking Synapse Workspace ($($SynapseWorkspace.name))" -ForegroundColor Blue

    #https://learn.microsoft.com/en-us/rest/api/synapse/kusto-pools/list-by-workspace?tabs=HTTP
    #GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Synapse/workspaces/{workspaceName}/kustoPools?api-version=2021-06-01-preview

    $uri = "https://management.azure.com$($SynapseWorkspace.id)/kustoPools?api-version=2021-06-01-preview"

    if ($debug -or $detailedAPIrequests) {
        $uri
    }
    
    $result = $null
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers
    
    $ADXSynapseClusterList = @($result.value)
    
    foreach ($ADXCluster in $ADXSynapseClusterList) {
        Write-Host "Cluster ($($ADXCluster.name)) / State ($($ADXCluster.properties.state))" -ForegroundColor Blue

        if ($ADXCluster.properties.state -eq "Running") {
            Write-Host "Pausing Cluster ($($ADXCluster.name))" -ForegroundColor Yellow

            #Pause
            #https://learn.microsoft.com/en-us/rest/api/synapse/kusto-pools/stop?tabs=HTTP
            #POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Synapse/workspaces/{workspaceName}/kustoPools/{kustoPoolName}/stop?api-version=2021-06-01-preview

            #Start
            #https://learn.microsoft.com/en-us/rest/api/synapse/kusto-pools/start?tabs=HTTP
            #POST POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Synapse/workspaces/{workspaceName}/kustoPools/{kustoPoolName}/start?api-version=2021-06-01-preview

            $uri = "https://management.azure.com$($ADXCluster.id)/stop?api-version=2021-06-01-preview"

            if ($debug -or $detailedAPIrequests) {
                $uri
            }
            

            $result = $null
            if ($debug -ne $true) {
                $result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers
            }
         

            Write-Host "Pause request sent. Check results" -ForegroundColor Yellow
            ($result | ConvertTo-Json)
        }
        else {
            Write-Host "No action done as cluster state is not running but ($($ADXCluster.properties.state))"
        }
    }

}

