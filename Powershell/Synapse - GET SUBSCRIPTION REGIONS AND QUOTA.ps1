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