<#   
.SYNOPSIS   
    
   
.DESCRIPTION   
    
 
.PARAMETER SqlServerName  
       
.PARAMETER DatabaseName   
 
    
.EXAMPLE   
   
.NOTES   
    Author: Sergio Fonseca
    Last Updated: 2020-11-26
#> 

##########################################################################################################################################################
Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Resources
Import-Module Az.Compute
##########################################################################################################################################################
#Parameters
##########################################################################################################################################################
[string]$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

$ErrorActionPreference = "Stop"



##########################################################################################################################################################
#Connect
##########################################################################################################################################################
Clear-Host
#Disconnect-AzAccount

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

<#
##########################################################################################################################################################
#Get RESOURCE GROUPS
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get RESOURCE GROUPS" -ForegroundColor  DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray

[System.Collections.ArrayList]$ResourceGroups = @()

$ResourceGroups = @(Get-AzResourceGroup)

Write-Host ($ResourceGroups | Select ResourceGroupName | Out-String) -ForegroundColor Gray
#>


##########################################################################################################################################################
#Get SQL Resources
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get SQL RESOURCES" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray

[System.Collections.ArrayList]$AzureResources = @()
[System.Collections.ArrayList]$AzureDatabases = @()
[System.Collections.ArrayList]$AzureDatabasesDW = @()

$AzureResources = @(Get-AzResource)
$AzureDatabases = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})


##########################################################################################################################################################
#Check Synapse Resources
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Check Synapse Resources" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray

foreach ($database in $AzureDatabases)
{
    $ServerName = ($database.Name -split '/')[0]
    $DatabaseName = ($database.Name -split '/')[1]

    if ($DatabaseName -ne "master")
    {
        $databaseObject = Get-AzSqlDatabase -ResourceGroupName $database.ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

        #Database basic are cheap - Ignore
        if ($databaseObject.SkuName -eq "DataWarehouse") 
        {
            $AzureDatabasesDW += $database

            #$databaseObject

            if ($databaseObject.Status -eq "Paused")
            {
                Write-Host "Server($($ServerName)) / DB ($($DatabaseName)) / SkuName $($databaseObject.SkuName) / Status($($databaseObject.Status))" -ForegroundColor Green
            }
            elseif ($databaseObject.Status -eq "Online")
            {
                Write-Host "Server($($ServerName)) / DB ($($DatabaseName)) / SkuName $($databaseObject.SkuName) / Status($($databaseObject.Status))" -ForegroundColor Red
                Write-Host "Pausing ..." -ForegroundColor Red

                $databaseObject | Suspend-AzSqlDatabase
            }
            else
            {
                Write-Host "Server($($ServerName)) / DB ($($DatabaseName)) / SkuName $($databaseObject.SkuName) / Status($($databaseObject.Status))" -ForegroundColor Yellow
            }
            
        }
    }
}
##########################################################################################################################################################