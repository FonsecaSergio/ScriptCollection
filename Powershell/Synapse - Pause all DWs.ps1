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
#Get Synapse Resources
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Synapse RESOURCES" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray

[System.Collections.ArrayList]$AzureResources = @()

$AzureResources = @(Get-AzResource)

$AzureResources = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})

foreach ($AzureResource in $AzureResources)
{
        Write-Host ("--> Type ($($AzureResource.Type)) / Res Group ($($AzureResource.ResourceGroupName)) / Name ($($AzureResource.Name))") -ForegroundColor Gray
        Write-Verbose "--> ResourceId ($($AzureResource.ResourceId))"
        Write-Verbose ("")
}


##########################################################################################################################################################
#Get Databases
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get Databases" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureDatabases = @()
[System.Collections.ArrayList]$AzureDatabasesDW = @()

$AzureDatabases = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})

foreach ($database in $AzureDatabases)
{
    $ServerName = ($database.Name -split '/')[0]
    $DatabaseName = ($database.Name -split '/')[1]

    if ($DatabaseName -eq "master")
    {
        Write-Host "DB ($($database.Name)) is master - Ignore" -ForegroundColor Yellow
        $AzureDatabasesToIgnore += $database.ResourceId
    }
    else
    {
        $databaseObject = Get-AzSqlDatabase -ResourceGroupName $database.ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
        
        

        #Database basic are cheap - Ignore
        if ($databaseObject.SkuName -ne "DataWarehouse")
        {
            $AzureDatabasesDW += $database.ResourceId

            Write-Host "Server($($ServerName)) / DB ($($DatabaseName)) / SkuName $($databaseObject.SkuName)" -ForegroundColor Red
        }

    }
}


$AzureResources = @($AzureResources | Where-Object {$_.ResourceId -in $AzureDatabasesToIgnore})

Write-Host "Removed ($($AzureDatabasesToIgnore.Count) / $($AzureDatabases.Count)) databases" -ForegroundColor Gray
Write-Host ""


##########################################################################################################################################################
$AzureResources



##########################################################################################################################################################
#ALERTS
##########################################################################################################################################################
<#
[System.Collections.ArrayList]$ResourcesAlert = @()
if (($AzureResources | Select Type, ResourceGroupName, Name | Out-String).Length -gt 0)
{
    foreach ($AzureResource in @($AzureResources | Select Type, ResourceGroupName, Name))
    {
        $ResourcesAlert.Add($AzureResource) | Out-Null
    }
}

if($ResourcesAlert.Count -ge 1)
{
    Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Red
    Write-Host "Check this resources" -ForegroundColor Red
    Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Red
    Write-Host ($AzureResources | Select Type, ResourceGroupName, Name | Out-String) -ForegroundColor Red
    Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor Red

    Write-Host "## Send Alert ##" -ForegroundColor Red

    $NotificationText = "$($ResourcesAlert.Count) PAYING Resources"
    
    Add-Type -AssemblyName System.Windows.Forms 
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -id $pid).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
    $balloon.BalloonTipTitle = "Attention AZURE Resource Alert" 
    $balloon.BalloonTipText = $NotificationText
    $balloon.Visible = $true 
    $balloon.ShowBalloonTip(5000)

    Write-Error -Message ($NotificationText) 
}
else
{
    Write-Host "## No issues ##" -ForegroundColor Green
}

#>