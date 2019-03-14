<#
param(
    [Parameter (Mandatory = $true)]
    [string]$SubscriptionName,
    #SEFONSEC Microsoft Azure Internal Consumption

    [Parameter (Mandatory = $false)]
    [System.Collections.ArrayList]$IgnoreResGroups
    #On Azure Runbook send as JSON format ['LogAnalytics','MIJumpbox','NetworkWatcherRG']

#>
$ErrorActionPreference = "Stop"

Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Resources

try{
    $Conn = Get-AutomationConnection -Name 'AzureRunAsConnection'
} catch {}

if ((Get-Variable -Name "SubscriptionName" ) -eq $null) 
    { [string]$SubscriptionName = "" }  

if ((Get-Variable -Name "IgnoreResGroups" ) -eq $null) 
    { [System.Collections.ArrayList]$IgnoreResGroups }  


<#Enable for alert https://docs.microsoft.com/en-us/azure/automation/automation-alert-metric#>


<##########################################################################################################################################################
#Parameters
##########################################################################################################################################################>

<#
[string]$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

[System.Collections.ArrayList]$IgnoreResGroups = @(
    "LogAnalytics", 
    "MIJumpbox",
    "NetworkWatcherRG"
)
#>

[System.Collections.ArrayList]$IgnoreAzureResourcesTypesFree = @(
    "microsoft.insights/alertrules",
    "Microsoft.Network/networkWatchers",
    "Microsoft.Network/virtualNetworks",
    "Microsoft.Sql/servers",
    "Microsoft.Automation/automationAccounts",
    "Microsoft.Automation/automationAccounts/runbooks",
    "microsoft.insights/actiongroups",
    "microsoft.insights/metricalerts"
)



<##########################################################################################################################################################
#Connect
##########################################################################################################################################################>
<#
    Clear-Host
    Disconnect-AzAccount
#>

$context = Get-AzContext 

if ($context -eq $null)
{
    Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint -Subscription $Conn.SubscriptionId
}

<##########################################################################################################################################################
#Get Resources Groups / Remove  Ignorables
##########################################################################################################################################################>
[System.Collections.ArrayList]$AzureResourceGroups = Get-AzResourceGroup
$AzureResourceGroups = @($AzureResourceGroups | Where-Object {$_.ResourceGroupName -notin $IgnoreResGroups})

Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output "Will only evaluate the selected RESOURCE GROUPS, will ignore ($($IgnoreResGroups.Count) Res Group )"
Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output ($AzureResourceGroups | Select ResourceGroupName | Out-String)



<##########################################################################################################################################################
#Get Resources / Remove Ignorables
##########################################################################################################################################################>
[System.Collections.ArrayList]$AzureResources = Get-AzResource

$AzureResources = @($AzureResources | Where-Object {$_.ResourceGroupName -notin $IgnoreResGroups})
$AzureResources = $AzureResources | Where-Object {$_.ResourceType -notin $IgnoreAzureResourcesTypesFree}

[System.Collections.ArrayList]$AzureResourcesTypes = @($AzureResources | Select ResourceType | sort-object ResourceType | Get-Unique -AsString)

Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output "Will only evaluate the selected RESOURCES"
Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output ($AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String)



<##########################################################################################################################################################
#Get Databases / Remove Ignorables
##########################################################################################################################################################>
Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output "Get Databases / Remove Ignorables"
Write-Output "---------------------------------------------------------------------------------------------------------------"
[System.Collections.ArrayList]$AzureDatabasesToIgnore = @()
[System.Collections.ArrayList]$AzureDatabases = @()

$AzureDatabases = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})

foreach ($database in $AzureDatabases)
{
    $ServerName = ($database.Name -split '/')[0]
    $DatabaseName = ($database.Name -split '/')[1]

    if ($DatabaseName -eq "master")
    {
        $AzureDatabasesToIgnore += $database
    }
    else
    {
        $databaseObject = Get-AzSqlDatabase -ResourceGroupName $database.ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
        
        <#Database basic are cheap - Ignore#>
        if ($databaseObject.SkuName -eq "Basic")
        {
            $AzureDatabasesToIgnore += $database
        }

        try
        {
            <#Database containg tag "Ignore"#>
            if ($databaseObject.Tags.ContainsKey("Ignore").ToString() -eq "true")
            {
                $AzureDatabasesToIgnore += $database
            }
                
        }
        catch {}

    }
}

foreach ($database in $AzureDatabasesToIgnore)
{
    $AzureResources.Remove($database)
}

Write-Output "Removed ($($AzureDatabasesToIgnore.Count) / $($AzureDatabases.Count)) databases"
Write-Output ""

<##########################################################################################################################################################
#Get StorageAccounts / Remove Ignorables
##########################################################################################################################################################>
Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output "Get StorageAccounts / Remove Ignorables"
Write-Output "---------------------------------------------------------------------------------------------------------------"
[System.Collections.ArrayList]$AzureStorageToIgnore = @()
[System.Collections.ArrayList]$AzureStorageAccounts = @()

$AzureStorageAccounts = @($AzureResources | Where-Object {$_.Type -eq "Microsoft.Storage/storageAccounts"})

foreach ($StorageAccount in $AzureStorageAccounts)
{
    $StorageAccountObject = Get-AzStorageAccount -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.Name
    
    <#Storage Account standard are cheap - Ignore#>
    if ($StorageAccountObject.Sku.Tier -eq "Standard")
    {
        $AzureStorageToIgnore += $StorageAccount
    }
}

foreach ($StorageAccount in $AzureStorageToIgnore)
{
    $AzureResources.Remove($StorageAccount)
}

Write-Output "Removed ($($AzureStorageToIgnore.Count) / $($AzureStorageAccounts.Count)) storage accounts"
Write-Output ""

<##########################################################################################################################################################>
[System.Collections.ArrayList]$ResourcesAlert = @()
$ResourcesAlert = @($AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String)

Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output "Check this resources"
Write-Output "---------------------------------------------------------------------------------------------------------------"
Write-Output ($ResourcesAlert)
Write-Output "---------------------------------------------------------------------------------------------------------------"

if($ResourcesAlert.Count -ge 1)
{
    Write-Output "## Send Alert ##"

    $NotificationText = "$($ResourcesAlert.Count) PAYING Resources"

    Write-Error -Message ($NotificationText)

}
else
{
    Write-Output "## No issues ##"
}


