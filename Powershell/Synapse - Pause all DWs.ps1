<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2020-01-13


.SYNOPSIS   
   
.DESCRIPTION    
    https://docs.microsoft.com/en-us/azure/automation/automation-alert-metric
 
.PARAMETER SubscriptionName  
       
#> 



##########################################################################################################################################################
Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Synapse
##########################################################################################################################################################
#Parameters
##########################################################################################################################################################
[string]$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

$ErrorActionPreference = "Continue"

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


##########################################################################################################################################################
#Get SQL / Synapse RESOURCES
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "Get SQL / Synapse RESOURCES" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan

[System.Collections.ArrayList]$AzureSQLServers = @()
[System.Collections.ArrayList]$AzureSynapseWorkspaces = @()


$AzureSQLServers = @(Get-AzSqlServer)
$AzureSynapseWorkspaces = @(Get-AzSynapseWorkspace)

##########################################################################################################################################################
# Loop through all Synapse Workspaces
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "Loop through all Synapse Workspaces" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan

[System.Collections.ArrayList]$SynapseSqlPools = @()

foreach ($AzureSynapseWorkspace in $AzureSynapseWorkspaces) 
{
    Write-Host "Checking Azure Synapse Workspace [$($AzureSynapseWorkspace.Name)] for Synapse SQL Pools" -ForegroundColor Gray
    
    $SynapseSqlPools = @($AzureSynapseWorkspace | Get-AzSynapseSqlPool)

    foreach ($SynapseSqlPool in $SynapseSqlPools) {
        
        ##########################################################################################################################################################
        if ($SynapseSqlPool.Status -eq "Paused")
        {
            Write-Host " -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Paused]" -ForegroundColor Green
        }
        ##########################################################################################################################################################
        elseif ($SynapseSqlPool.Status -eq "Online")
        {
            Write-Host " -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Online]" -ForegroundColor Red
            # Pause Synapse SQL Pool
            $startTimePause = Get-Date
            Write-Host " -> Pausing Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)]" -ForegroundColor Yellow 
            $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSynapseSqlPool

            # Show that the Synapse SQL Pool has been pause and how long it took
            $endTimePause = Get-Date
            $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

            if ($resultsynapseSqlPool.Status -eq "Paused") 
            {
                Write-Host " -> Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]" -ForegroundColor Green
            }
            else 
            {
                Write-Host " -> Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]" -ForegroundColor Red
            }           
        }
        ##########################################################################################################################################################
        else 
        {
            Write-Error " -> Checking Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [$($SynapseSqlPool.Status)]"
        }
        ##########################################################################################################################################################
    }    
}



##########################################################################################################################################################
# Loop through all SQL Servers (former SQLDW)
##########################################################################################################################################################
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "Loop through all SQL Servers (former SQLDW)" -ForegroundColor DarkCyan
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan

foreach ($AzureSQLServer in $AzureSQLServers)
{
    # Log which SQL Servers are checked and in which resource group
    Write-Host "Checking SQL Server [$($AzureSQLServer.ServerName)] in Resource Group [$($AzureSQLServer.ResourceGroupName)] for Synapse SQL Pools" -ForegroundColor Gray

    # Get all databases from a SQL Server, but filter on Edition = "DataWarehouse"
    $allSynapseSqlPools = Get-AzSqlDatabase `
                            -ResourceGroupName $AzureSQLServer.ResourceGroupName `
                            -ServerName $AzureSQLServer.ServerName `
                    | Where-Object {$_.Edition -eq "DataWarehouse"}

                                           # Loop through each found Synapse SQL Pool
    foreach ($SynapseSqlPool in $allSynapseSqlPools)
    {
        $isPoolInWorkspace = $false

        foreach ($AzureSynapseWorkspace in $AzureSynapseWorkspaces) 
        {
            if ($AzureSynapseWorkspace.Name -eq $SynapseSqlPool.ServerName)
            {
                $isPoolInWorkspace = $true
                Write-Host " -> This DB is part of Synapse Workspace - Ignore here Should be done above using Az.Synapse Module" -ForegroundColor Green                
            }
        }
        ##########################################################################################################################################################

        if (!$isPoolInWorkspace) 
        {
            if ($SynapseSqlPool.Status -eq "Paused")
            {
                Write-Host " -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Paused]" -ForegroundColor Green
            }
            ##########################################################################################################################################################
            elseif ($SynapseSqlPool.Status -eq "Online")
            {
                Write-Host " -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Online]" -ForegroundColor Red
                # Pause Synapse SQL Pool
                $startTimePause = Get-Date
                Write-Host " -> Pausing Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)]" -ForegroundColor Yellow 
                $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSqlDatabase

                # Show that the Synapse SQL Pool has been pause and how long it took
                $endTimePause = Get-Date
                $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

                if ($resultsynapseSqlPool.Status -eq "Paused") 
                {
                    Write-Host " -> Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]" -ForegroundColor Green
                }
                else 
                {
                    Write-Host " -> Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]" -ForegroundColor Red
                }           
            }
            ##########################################################################################################################################################
            else 
            {
                Write-Error " -> Checking Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [$($SynapseSqlPool.Status)]"
            }
            ##########################################################################################################################################################
        }      
    }
}