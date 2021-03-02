# GET SUBSCRIPTION REGIONS AND QUOTA

########################################################################################################
#CONNECT TO AZURE
Clear-Host

$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

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
 
# get AAD token for REST calls
Write-Host "Getting Bearer token from AAD for REST calls..."
$apiToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null)
$headers = @{ 'authorization' = ('Bearer {0}' -f ($apiToken.AccessToken)) }
 
# Get Locations where Synapse is available
Write-Host "Getting Locations where Synapse is available..."
$synapseLocations = Get-AzLocation | Where-Object { $_.Providers -contains "Microsoft.Synapse" } | Sort-Object Location | Select-Object Location, DisplayName
 
# ------------------------------------------------------------------------------
# get subscription quota and regional available SLOs for Synapse SQL
 
Write-Host "Getting subscription quota settings for Synapse..."
$quotaResults = [System.Collections.ObjectModel.Collection[psobject]]@()
 
foreach($location in $synapseLocations)
{
    # ------------------
    # available slos
    # https://docs.microsoft.com/en-us/rest/api/sql/capabilities/listbylocation
    $capabilitiesUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Sql/locations/$($location.Location)/capabilities?api-version=2015-05-01-preview"
    $regionalCapabilities = ConvertFrom-Json (Invoke-WebRequest -Method Get -Uri $capabilitiesUri -Headers $headers).Content
    
    # ------------------------------------
 
    $quotaResults += [PSCustomObject]@{
        Location = $location.Location;
        DisplayName = $location.DisplayName;
        Status = $regionalCapabilities.status;
    }
}
 
$quotaResults | ft -AutoSize



# Get Locations where Synapse is available
Write-Host "Getting Locations where Synapse is available..."
$synapseLocations = Get-AzLocation | Where-Object { $_.Providers -contains "Microsoft.Synapse" } | Sort-Object Location | Select-Object Location, DisplayName

# ------------------------------------------------------------------------------
# get subscription quota and regional available SLOs for Synapse SQL

Write-Host "Getting subscription quota settings for Synapse..."
$quotaResults = [System.Collections.ObjectModel.Collection[psobject]]@()

foreach($location in $synapseLocations)
{
    # ------------------
    # subscription quota
    # https://docs.microsoft.com/en-us/rest/api/sql/subscriptionusages/get
    $subscriptionQuotaUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Sql/locations/$($location.Location)/usages/ServerQuota?api-version=2015-05-01-preview"
    $currentQuotaResult = (ConvertFrom-Json (Invoke-WebRequest -Method Get -Uri $subscriptionQuotaUri -Headers $headers).Content).properties
    
    # ------------------------------------

    $quotaResults += [PSCustomObject]@{
        Location = $location.Location;
        DisplayName = $location.DisplayName;
        CurrentServerWorkspaceCount = $currentQuotaResult.currentValue;
        ServerWorkspaceQuotaLimit = $currentQuotaResult.limit;
    }
}

$quotaResults | ft -AutoSize




# ------------------------------------------------------------------------------
# SQL server DTU limits

Write-Host "Getting SQL DTU limits..."

# all servers in this subscription for SQL
# https://docs.microsoft.com/en-us/rest/api/sql/servers/list
# GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Sql/servers?api-version=2019-06-01-preview
$serversUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Sql/servers?api-version=2019-06-01-preview"
$serverList = (ConvertFrom-Json (Invoke-WebRequest -Method Get -Uri $serversUri -Headers $headers).Content).value

$serverQuotas = @()

foreach($server in $serverList)
{
    # usage detail of indiviual server
    # https://docs.microsoft.com/en-us/rest/api/sql/servers/usages
    # GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/usages?api-version=2014-01-01
    $serverQuotaUri = "https://management.azure.com$($server.id)/usages?api-version=2014-01-01"
    $serverQuota = (ConvertFrom-Json (Invoke-WebRequest -Method Get -Uri $serverQuotaUri -Headers $headers).Content).value

    $serverQuotas += [PSCustomObject]@{
        Location = $server.location;
        Id = $server.id;
        Name = $server.name;
        CurrentDTU = ($serverQuota | ? { $_.name -eq 'server_dtu_quota_current' }).currentValue;
        DTULimit = ($serverQuota | ? { $_.name -eq 'server_dtu_quota_current' }).limit;
    }
}

$serverQuotas | Sort-Object Location, Name | ft Location, Name, CurrentDTU, DTULimit -AutoSize