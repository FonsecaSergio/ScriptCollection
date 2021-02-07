<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-xx-xx

.SYNOPSIS   
   
.DESCRIPTION    
 
.PARAMETER xxxx 
       
#> 
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
    if ($Context.Subscription.Name -ne $SubscriptionName) {
        $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
        Select-AzSubscription -Subscription $Subscription.Id | Out-Null
        Write-Host "Current subscription is $($Subscription.Name)"
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
    }    
}

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Output "Need to login"
    Connect-AzAccount -Subscription $SubscriptionName
}
else {
    Write-Output "Context exists"
    Write-Output "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Name -ne $SubscriptionName) {
        $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
        Select-AzSubscription -Subscription $Subscription.Id | Out-Null
        Write-Output "Current subscription is $($Subscription.Name)"
    }
    else {
        Write-Output "Current subscription is $($Context.Subscription.Name)"    
    }    
}
########################################################################################################