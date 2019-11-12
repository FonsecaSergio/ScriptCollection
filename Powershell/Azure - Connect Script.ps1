$Context = Get-AzContext

if($Context -eq $null)
{
    Connect-AzAccount

    $Subscription = Get-AzSubscription -SubscriptionName "SEFONSEC Microsoft Azure Internal Consumption"
    Set-AzContext $Subscription 
}


