Connect-AzAccount

$Subscription = Get-AzSubscription -SubscriptionName "SEFONSEC Microsoft Azure Internal Consumption"
Set-AzContext $Subscription 


