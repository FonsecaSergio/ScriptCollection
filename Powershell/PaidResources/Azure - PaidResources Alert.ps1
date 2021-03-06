﻿Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Resources
Import-Module Az.Compute
##########################################################################################################################################################
#Parameters
##########################################################################################################################################################
[string]$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

[System.Collections.ArrayList]$AzureResourcesToIgnoreTypesFree = @(
    "microsoft.insights/alertrules",
    "Microsoft.Network/networkWatchers",
    "Microsoft.Network/virtualNetworks",
    "Microsoft.Sql/servers",
    "Microsoft.Automation/automationAccounts",
    "Microsoft.Automation/automationAccounts/runbooks",
    "microsoft.insights/actiongroups",
    "microsoft.insights/metricalerts",
    "Microsoft.Network/networkIntentPolicies",
    "Microsoft.Network/networkSecurityGroups",
    "Microsoft.Network/routeTables",
    "Microsoft.DevTestLab/schedules",
    "Microsoft.Network/networkInterfaces",
    "Microsoft.Network/publicIPAddresses",
    "Microsoft.Compute/disks",
    "Microsoft.Compute/virtualMachines/extensions",
    "Microsoft.SqlVirtualMachine/SqlVirtualMachines",
    "Microsoft.Sql/managedInstances/databases",
    "Microsoft.Sql/virtualClusters",
    "Microsoft.KeyVault/vaults",
    "Microsoft.DataMigration/services"
)

[string]$TagIgnoreName = "Ignore"
[string]$TagIgnoreValue = "true"
$ErrorActionPreference = "Stop"



##########################################################################################################################################################
#Connect
##########################################################################################################################################################
Clear-Host
#Disconnect-AzAccount

$context = Get-AzContext 

if ($context -eq $null)
{
    Connect-AzAccount
    $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
    Set-AzContext $Subscription | Out-Null
}

##########################################################################################################################################################
#Get Resources Groups / Remove  Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Will only evaluate the selected RESOURCE GROUPS" -ForegroundColor  DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray

[System.Collections.ArrayList]$ResourceGroups = @()
[System.Collections.ArrayList]$ResourceGroupsToIgnore = @()

$ResourceGroups = @(Get-AzResourceGroup)

foreach ($AzureResourceGroup in $ResourceGroups)
{
    if ($AzureResourceGroup.Tags -ne $null)
    {
        if ($AzureResourceGroup.Tags.ContainsKey($TagIgnoreName))
        {
            if ($AzureResourceGroup.Tags.Item($TagIgnoreName) -eq $TagIgnoreValue)
            {
                Write-Host "--> Resource Group ($($AzureResourceGroup.ResourceGroupName)) with TAG - Ignore" -ForegroundColor Yellow
                $ResourceGroupsToIgnore.Add($AzureResourceGroup.ResourceGroupName) | Out-Null
            }
        }
    }
}

$ResourceGroups = @($ResourceGroups | Where-Object {$_.ResourceGroupName -notin $ResourceGroupsToIgnore})

Write-Host ($ResourceGroups | Select ResourceGroupName | Out-String) -ForegroundColor Gray



##########################################################################################################################################################
#Get Resources / Remove Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Will only evaluate the selected RESOURCES" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray

[System.Collections.ArrayList]$AzureResources = @()
[System.Collections.ArrayList]$AzureResourcesToIgnore = @()

$AzureResources = @(Get-AzResource)

#Remove Resource Groups to Ignore
$AzureResources = @($AzureResources | Where-Object {$_.ResourceGroupName -notin $ResourceGroupsToIgnore})

#Remove Resources that are free / unexpensive
$AzureResources = $AzureResources | Where-Object {$_.ResourceType -notin $AzureResourcesToIgnoreTypesFree}

foreach ($AzureResource in $AzureResources)
{
    if (($AzureResource.Tags).Count -gt 0)
    {
        if ($AzureResource.Tags.ContainsKey($TagIgnoreName))
        {
            if ($AzureResource.Tags.Item($TagIgnoreName) -eq $TagIgnoreValue)
            {
                Write-Host "--> Resource ($($AzureResource.ResourceId)) with TAG - Ignore" -ForegroundColor Yellow
                $AzureResourcesToIgnore.Add($AzureResource.ResourceId) | Out-Null
            }
        }
    }  
}
$AzureResources = @($AzureResources | Where-Object {$_.ResourceId -notin $AzureResourcesToIgnore})


foreach ($AzureResource in $AzureResources)
{
    Write-Host ("--> Type ($($AzureResource.Type)) / Res Group ($($AzureResource.ResourceGroupName)) / Name ($($AzureResource.Name))") -ForegroundColor Gray
    Write-Verbose "--> ResourceId ($($AzureResource.ResourceId))"
    Write-Verbose ("")
}


##########################################################################################################################################################
#Get Databases / Remove Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get Databases / Remove Ignorables" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureDatabases = @()
[System.Collections.ArrayList]$AzureDatabasesToIgnore = @()

$AzureDatabases = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})

foreach ($database in $AzureDatabases)
{
    $ServerName = ($database.Name -split '/')[0]
    $DatabaseName = ($database.Name -split '/')[1]

    if ($DatabaseName -eq "master")
    {
        Write-Verbose "DB ($($database.Name)) is master - Ignore"
        $AzureDatabasesToIgnore += $database.ResourceId
    }
    else
    {
        $databaseObject = Get-AzSqlDatabase -ResourceGroupName $database.ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
        
        #Database basic are cheap - Ignore
        if ($databaseObject.SkuName -eq "Basic")
        {
            Write-Host "--> DB ($($database.Name)) is Basic - Ignore" -ForegroundColor Yellow
            $AzureDatabasesToIgnore += $database.ResourceId
        }

        #Database S0 are cheap - Ignore
        if ($databaseObject.SkuName -eq "Standard" -and $databaseObject.CurrentServiceObjectiveName -eq "S0")
        {
            Write-Host "--> DB ($($database.Name)) is S0 - Ignore" -ForegroundColor Yellow
            $AzureDatabasesToIgnore += $database.ResourceId
        }
    }
}


$AzureResources = @($AzureResources | Where-Object {$_.ResourceId -notin $AzureDatabasesToIgnore})

Write-Host "Removed ($($AzureDatabasesToIgnore.Count) / $($AzureDatabases.Count)) databases" -ForegroundColor Gray
Write-Host ""
##########################################################################################################################################################
#Get StorageAccounts / Remove Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get StorageAccounts / Remove Ignorables" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureStorageAccounts = @()
[System.Collections.ArrayList]$AzureStorageAccountsToIgnore = @()

$AzureStorageAccounts = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Storage/storageAccounts"})

foreach ($StorageAccount in $AzureStorageAccounts)
{
    $StorageAccountObject = Get-AzStorageAccount -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.Name
    
    #Storage Account standard are cheap - Ignore
    if ($StorageAccountObject.Sku.Tier -eq "Standard")
    {
        Write-Host "--> Storage Account ($($StorageAccountObject.StorageAccountName)) is Standard - Ignore" -ForegroundColor Yellow
        $AzureStorageAccountsToIgnore += $StorageAccount.ResourceId
    }
}

$AzureResources = @($AzureResources | Where-Object {$_.ResourceId -notin $AzureStorageAccountsToIgnore})

Write-Host "Removed ($($AzureStorageAccountsToIgnore.Count) / $($AzureStorageAccounts.Count)) storage accounts" -ForegroundColor Gray
Write-Host ""


##########################################################################################################################################################
#Get VMs / Remove Dealocatted
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get VMs / Remove Dealocatted" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureVMs = @()
[System.Collections.ArrayList]$AzureVMsToIgnore = @()

## STILL NEED Resource type regular VM#######

#$AzureVMs = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.SqlVirtualMachine/SqlVirtualMachines"})
$AzureVMs = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Compute/virtualMachines"})

foreach ($AzureVM in $AzureVMs)
{
    $VMObject = Get-AzVM -ResourceGroupName $AzureVM.ResourceGroupName -Name $AzureVM.Name -Status
    
    #Storage Account standard are cheap - Ignore
    foreach ($VMStatus in $VMObject.Statuses)
    { 
        if($VMStatus.Code.CompareTo("PowerState/deallocated") -eq 0)
        {
            Write-Host "--> VM ($($AzureVM.Name)) is Dealocatted - Ignore" -ForegroundColor Yellow
            $AzureVMsToIgnore += $AzureVM
        }
    }
}

foreach ($AzureVM in $AzureVMsToIgnore)
{
    $AzureResources.Remove($AzureVM)
}

Write-Host "Removed ($($AzureVMsToIgnore.Count) / $($AzureVMs.Count)) VMs" -ForegroundColor Gray
Write-Host ""

##########################################################################################################################################################
#ALERTS
##########################################################################################################################################################
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
    Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
    Write-Host "Check this resources" -ForegroundColor Red
    Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
    Write-Host ($AzureResources | Select Type, ResourceGroupName, Name | Out-String) -ForegroundColor Red
    Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red

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

