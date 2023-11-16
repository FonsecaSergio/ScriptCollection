<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-02-14

.SYNOPSIS   
   Restore Dedicated Pool to same server with different name

.DESCRIPTION
   Created based on https://docs.microsoft.com/en-us/powershell/module/az.synapse/restore-azsynapsesqlpool?view=azps-7.2.0
       
#> 

########################################################################################################
#CONNECT TO AZURE

#Connect-AzAccount -Subscription $SubscriptionId
#Below process will authenticate with your current windows account

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    Connect-AzAccount -Subscription $SubscriptionId
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Id -ne $SubscriptionId) {
        $result = Select-AzSubscription -Subscription $SubscriptionId
        Write-Host "Current subscription is $($result.Subscription.Name)"
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
    }
}
########################################################################################################

$ResourceGroupName = 'SynapseWorkspace'
$WorkspaceName = 'xxxxxxxxxxxxx'
$SourcePoolName = 'yyyyyyyyyyyy'
$TargetSqlPoolName = 'yyyyyyyyyyyy_BKP'

# Transform Synapse SQL pool resource ID to SQL database ID because 
# currently the command only accepts the SQL databse ID. For example: /subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Sql/servers/<WorkspaceName>/databases/<DatabaseName>
$pool = Get-AzSynapseSqlPool `    -ResourceGroupName $ResourceGroupName `
    -WorkspaceName $WorkspaceName `
    -Name $SourcePoolName

$databaseId = $pool.Id -replace "Microsoft.Synapse", "Microsoft.Sql" `
	-replace "workspaces", "servers" `
	-replace "sqlPools", "databases"

# Get the latest restore point
$restorePoint = $pool | Get-AzSynapseSqlPoolRestorePoint | Select -Last 1

# Restore to same workspace with source SQL pool
$restoredPool = Restore-AzSynapseSqlPool `
    -FromRestorePoint `
    -RestorePoint $restorePoint.RestorePointCreationDate `
    -Name $TargetSqlPoolName `
    -ResourceGroupName $pool.ResourceGroupName `
    -WorkspaceName $pool.WorkspaceName `
    -ResourceId $databaseId `
    -PerformanceLevel DW100c

####################
Get-AzSynapseSqlPool `    -ResourceGroupName $ResourceGroupName `
    -WorkspaceName $WorkspaceName `
    -Name $TargetSqlPoolName