########################################################################################################
#CONNECT TO AZURE
Clear-Host

$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    Connect-AzAccount -Subscription $SubscriptionName
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
    Select-AzSubscription -Subscription $Subscription.Id | Out-Null
    Write-Host "Current subscription is $($Context.Subscription.Name)"
}
########################################################################################################