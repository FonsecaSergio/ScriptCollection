<#   
.SYNOPSIS    
   
.DESCRIPTION   
 
.PARAMETER SubscriptionName  
           
.EXAMPLE   
   
.NOTES   
    Author: Sergio Fonseca
    Last Updated: 2020-01-13

    https://docs.microsoft.com/en-us/azure/automation/automation-alert-metric
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
#https://docs.microsoft.com/en-us/azure/automation/automation-connections?tabs=azure-powershell#get-a-connection-in-a-runbook-or-dsc-configuration

$Conn = Get-AutomationConnection -Name "AzureRunAsConnection"
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint -Subscription $SubscriptionName

##########################################################################################################################################################
#Get SQL / Synapse RESOURCES
##########################################################################################################################################################
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Get SQL / Synapse RESOURCES"
Write-Output "---------------------------------------------------------------------------------------------------"

[System.Collections.ArrayList]$AzureSQLServers = @()
[System.Collections.ArrayList]$AzureSynapseWorkspaces = @()


$AzureSQLServers = @(Get-AzSqlServer)
$AzureSynapseWorkspaces = @(Get-AzSynapseWorkspace)

##########################################################################################################################################################
# Loop through all Synapse Workspaces
##########################################################################################################################################################
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Loop through all Synapse Workspaces"
Write-Output "---------------------------------------------------------------------------------------------------"

[System.Collections.ArrayList]$SynapseSqlPools = @()

foreach ($AzureSynapseWorkspace in $AzureSynapseWorkspaces) 
{
    Write-Output "Checking Azure Synapse Workspace [$($AzureSynapseWorkspace.Name)] for Synapse SQL Pools"
    
    $SynapseSqlPools = @($AzureSynapseWorkspace | Get-AzSynapseSqlPool)

    foreach ($SynapseSqlPool in $SynapseSqlPools) {
        
        ##########################################################################################################################################################
        if ($SynapseSqlPool.Status -eq "Paused")
        {
            Write-Output " -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Paused]"
        }
        ##########################################################################################################################################################
        elseif ($SynapseSqlPool.Status -eq "Online")
        {
            Write-Output " -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Online]"
            # Pause Synapse SQL Pool
            $startTimePause = Get-Date
            Write-Output " -> Pausing Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)]"
            $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSynapseSqlPool

            # Show that the Synapse SQL Pool has been pause and how long it took
            $endTimePause = Get-Date
            $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

            if ($resultsynapseSqlPool.Status -eq "Paused") 
            {
                Write-Output " -> Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
            }
            else 
            {
                Write-Output " -> Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
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
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Loop through all SQL Servers (former SQLDW)"
Write-Output "---------------------------------------------------------------------------------------------------"

foreach ($AzureSQLServer in $AzureSQLServers)
{
    # Log which SQL Servers are checked and in which resource group
    Write-Output "Checking SQL Server [$($AzureSQLServer.ServerName)] in Resource Group [$($AzureSQLServer.ResourceGroupName)] for Synapse SQL Pools"

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
                Write-Output " -> This DB is part of Synapse Workspace - Ignore here Should be done above using Az.Synapse Module"
            }
        }
        ##########################################################################################################################################################

        if (!$isPoolInWorkspace) 
        {
            if ($SynapseSqlPool.Status -eq "Paused")
            {
                Write-Output " -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Paused]"
            }
            ##########################################################################################################################################################
            elseif ($SynapseSqlPool.Status -eq "Online")
            {
                Write-Output " -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Online]"
                # Pause Synapse SQL Pool
                $startTimePause = Get-Date
                Write-Output " -> Pausing Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)]"
                $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSqlDatabase

                # Show that the Synapse SQL Pool has been pause and how long it took
                $endTimePause = Get-Date
                $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

                if ($resultsynapseSqlPool.Status -eq "Paused") 
                {
                    Write-Output " -> Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
                }
                else 
                {
                    Write-Output " -> Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
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