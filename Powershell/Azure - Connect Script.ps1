########################################################################################################
#CONNECT TO AZURE
$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

$Context = Get-AzContext
if($Context -eq $null)
{
    Connect-AzAccount
}
$Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
Set-AzContext $Subscription

Clear-Host
########################################################################################################