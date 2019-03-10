Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Resources
##########################################################################################################################################################
#Parameters
##########################################################################################################################################################
[string]$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

[System.Collections.ArrayList]$IgnoreResGroups = @(
    "LogAnalytics", 
    "MIJumpbox",
    "NetworkWatcherRG"
)

[System.Collections.ArrayList]$IgnoreAzureResourcesTypesFree = @(
    "microsoft.insights/alertrules",
    "Microsoft.Network/networkWatchers",
    "Microsoft.Network/virtualNetworks",
    "Microsoft.Sql/servers",
    "Microsoft.Automation/automationAccounts",
    "Microsoft.Automation/automationAccounts/runbooks"
)



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
[System.Collections.ArrayList]$AzureResourceGroups = Get-AzResourceGroup
$AzureResourceGroups = $AzureResourceGroups | Where-Object {$_.ResourceGroupName -notin $IgnoreResGroups}

Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Will only evaluate the selected RESOURCE GROUPS, will ignore ($($IgnoreResGroups.Count) Res Group )" -ForegroundColor  DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ($AzureResourceGroups | Select ResourceGroupName | Out-String) -ForegroundColor Gray



##########################################################################################################################################################
#Get Resources / Remove Ignorables
##########################################################################################################################################################
[System.Collections.ArrayList]$AzureResources = Get-AzResource
$AzureResources = $AzureResources | Where-Object {$_.ResourceGroupName -notin $IgnoreResGroups}

[System.Collections.ArrayList]$AzureResourcesTypes = $AzureResources | Select ResourceType | sort-object ResourceType | Get-Unique -AsString
$AzureResources = $AzureResources | Where-Object {$_.ResourceType -notin $IgnoreAzureResourcesTypesFree}

Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Will only evaluate the selected RESOURCES" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ($AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String) -ForegroundColor Gray



##########################################################################################################################################################
#Get Databases / Remove Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get Databases / Remove Ignorables" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureDatabasesToIgnore = @()
[System.Collections.ArrayList]$AzureDatabases = @()

try
{
    $AzureDatabases = $AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"}
}
catch
{
    $AzureDatabases += ($AzureResources | Where-Object {$_.Type -eq "Microsoft.Sql/servers/databases"})
}

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
        
        #Database basic are cheap - Ignore
        if ($databaseObject.SkuName -eq "Basic")
        {
            $AzureDatabasesToIgnore += $database
        }

        try
        {
            #$databaseObject.DatabaseName
            #Database containg tag "Ignore"
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

Write-Host "Removed ($($AzureDatabasesToIgnore.Count) / $($AzureDatabases.Count)) databases" -ForegroundColor Gray
Write-Host ""
##########################################################################################################################################################
#Get StorageAccounts / Remove Ignorables
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Get StorageAccounts / Remove Ignorables" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray
[System.Collections.ArrayList]$AzureStorageToIgnore = @()
[System.Collections.ArrayList]$AzureStorageAccounts = @()
try
{
    $AzureStorageAccounts = $AzureResources | Where-Object {$_.Type -eq "Microsoft.Storage/storageAccounts"}
}
catch
{
    $AzureStorageAccounts += ($AzureResources | Where-Object {$_.Type -eq "Microsoft.Storage/storageAccounts"} )
}



foreach ($StorageAccount in $AzureStorageAccounts)
{
    $StorageAccountObject = Get-AzStorageAccount -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.Name
    
    #Storage Account standard are cheap - Ignore
    if ($StorageAccountObject.Sku.Tier -eq "Standard")
    {
        $AzureStorageToIgnore += $StorageAccount
    }
}

foreach ($StorageAccount in $AzureStorageToIgnore)
{
    $AzureResources.Remove($StorageAccount)
}

Write-Host "Removed ($($AzureStorageToIgnore.Count) / $($AzureStorageAccounts.Count)) storage accounts" -ForegroundColor Gray
Write-Host ""
##########################################################################################################################################################
[System.Collections.ArrayList]$ResourcesAlert = @()
try
{
    $ResourcesAlert = $AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String
}
catch
{
    if (($AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String).Length -gt 0)
    {
        $ResourcesAlert += ($AzureResources | Select Type, ResourceGroupName, Name, ParentResource | Out-String)
    }
}


Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
Write-Host "Check this resources" -ForegroundColor Red
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
Write-Host ($ResourcesAlert) -ForegroundColor Red
Write-Host "---------------------------------------------------------------------------------------------------------------" -ForegroundColor Red

#New-AzSqlDatabase -DatabaseName StandardTest -ResourceGroupName CSSAzureDB -ServerName Fonsecanet -Edition Standard -RequestedServiceObjectiveName S0
#Get-AzSqlDatabase  -DatabaseName StandardTest -ResourceGroupName CSSAzureDB -ServerName Fonsecanet | Set-AzSqlDatabase -Tags @{Ignore="true"}

if($ResourcesAlert.Count -ge 1)
{
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
}
else
{
    Write-Host "## No issues ##" -ForegroundColor Green
}

