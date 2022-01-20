<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2020-02-07

.SYNOPSIS   
   
.DESCRIPTION    
    https://docs.microsoft.com/en-us/azure/automation/automation-alert-metric
 
.PARAMETER SubscriptionId  
       
#> 
param (
    [string]$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b",
    [bool]$debug = $false
)

Clear-Host


##########################################################################################################################################################
Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Synapse
##########################################################################################################################################################
#Parameters
##########################################################################################################################################################
$ErrorActionPreference = "Continue"

##########################################################################################################################################################
#VARIABLES
##########################################################################################################################################################
[int]$iErrorCount = 0
[System.Collections.ArrayList]$AzureSQLServers = @()
[System.Collections.ArrayList]$AzureSynapseWorkspaces = @()
[System.Collections.ArrayList]$SynapseSqlPools = @()

##########################################################################################################################################################
#CONNECT TO AZURE
##########################################################################################################################################################

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


##########################################################################################################################################################
#Get SQL / Synapse RESOURCES
##########################################################################################################################################################
Write-Output ""
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Get SQL / Synapse RESOURCES"
Write-Output "---------------------------------------------------------------------------------------------------"

try {
    $AzureSQLServers = @(Get-AzSqlServer -ErrorAction Stop)
    $AzureSynapseWorkspaces = @(Get-AzSynapseWorkspace -ErrorAction Stop)        
}
catch {
    $iErrorCount += 1;
    Write-Error $_.Exception.Message
}

#$AzureSynapseWorkspaces | Out-GridView
#$AzureSQLServers | Out-GridView

##########################################################################################################################################################
# Loop through all Synapse Workspaces
##########################################################################################################################################################
Write-Output ""
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Loop through all Synapse Workspaces"
Write-Output "---------------------------------------------------------------------------------------------------"

for ($i = 0; $i -lt $AzureSynapseWorkspaces.Count; $i++) {
    $AzureSynapseWorkspace = $AzureSynapseWorkspaces[$i]

    Write-Output " ***************************************************************************************"
    Write-Output " Checking Azure Synapse Workspace [$($AzureSynapseWorkspace.Name)] for Synapse SQL Pools"
    
    try {
        $SynapseSqlPools = @($AzureSynapseWorkspace | Get-AzSynapseSqlPool -ErrorAction Stop)
    }
    catch [Microsoft.Azure.Commands.Synapse.Models.Exceptions.SynapseException] {
        if ($_.Exception.InnerException.Message -eq "Operation returned an invalid status code 'Conflict'") {
            Write-Error "  -> Operation returned an invalid status code 'Conflict'"
            Write-Output "  -> Removed ($($AzureSynapseWorkspace.Name)) from AzureSynapseWorkspaces"            
            $AzureSynapseWorkspaces.Remove($AzureSynapseWorkspace);
        }
        else {
            $iErrorCount += 1;
            Write-Error $_.Exception.Message
        }
    }
    catch {
        $iErrorCount += 1;
        Write-Error $_.Exception.Message
    }
    
    foreach ($SynapseSqlPool in $SynapseSqlPools) {
        
        ##########################################################################################################################################################
        if ($SynapseSqlPool.Status -eq "Paused") {
            Write-Output "  -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Paused]"
        }
        ##########################################################################################################################################################
        elseif ($SynapseSqlPool.Status -eq "Online") {
            Write-Output "  -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Online]"
            # Pause Synapse SQL Pool
            $startTimePause = Get-Date
            Write-Output "  -> Pausing Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)]"
            
            if (!$debug) {
                $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSynapseSqlPool    
            }
            
            # Show that the Synapse SQL Pool has been pause and how long it took
            $endTimePause = Get-Date
            $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

            if ($resultsynapseSqlPool.Status -eq "Paused") {
                Write-Output "  -> Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
            }
            else {
                if (!$debug) {
                    $iErrorCount += 1;
                    Write-Error "  -> (resultsynapseSqlPool.Status -ne ""Paused"") - Synapse SQL Pool [$($resultsynapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
                }
                else {
                    Write-Host "This is a debug session - Nothing was done" -ForegroundColor Yellow
                }
            }           
        }
        ##########################################################################################################################################################
        else {
            $iErrorCount += 1;
            Write-Error "  -> (SynapseSqlPool.Status -eq ""Online"") Checking Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [$($SynapseSqlPool.Status)]"
        }
        ##########################################################################################################################################################
    }    
}



##########################################################################################################################################################
# Loop through all SQL Servers (former SQLDW)
##########################################################################################################################################################
Write-Output ""
Write-Output  "---------------------------------------------------------------------------------------------------"
Write-Output  "Loop through all SQL Servers (former SQLDW)"
Write-Output  "---------------------------------------------------------------------------------------------------"

for ($i = 0; $i -lt $AzureSQLServers.Count; $i++) {
    $AzureSQLServer = $AzureSQLServers[$i]

    # Log which SQL Servers are checked and in which resource group
    Write-Output " ***************************************************************************************"    
    Write-Output " Checking SQL Server [$($AzureSQLServer.ServerName)] in Resource Group [$($AzureSQLServer.ResourceGroupName)] for Synapse SQL Pools"
    
    #Check if server os part of Azure Synapse Workspace
    $isServerSynapseWorkspace = $false

    foreach ($AzureSynapseWorkspace in $AzureSynapseWorkspaces) {
        if ($AzureSynapseWorkspace.Name -eq $AzureSQLServer.ServerName) {
            $isServerSynapseWorkspace = $true
            Write-Output " -> This Server is part of Synapse Workspace - Ignore here Should be done above using Az.Synapse Module"
        }
    }

    if (!$isServerSynapseWorkspace) {

        # Get all databases from a SQL Server, but filter on Edition = "DataWarehouse"
        $allSynapseSqlPools = Get-AzSqlDatabase `
            -ResourceGroupName $AzureSQLServer.ResourceGroupName `
            -ServerName $AzureSQLServer.ServerName `
        | Where-Object { $_.Edition -eq "DataWarehouse" }

    
        # Loop through each found Synapse SQL Pool
        foreach ($SynapseSqlPool in $allSynapseSqlPools) {

            ##########################################################################################################################################################

            if ($SynapseSqlPool.Status -eq "Paused") {
                Write-Output  "  -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Paused]"
            }
            ##########################################################################################################################################################
            elseif ($SynapseSqlPool.Status -eq "Online") {
                Write-Output  "  -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [Online]"
                # Pause Synapse SQL Pool
                $startTimePause = Get-Date
                Write-Output  "  -> Pausing Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)]"

                if (!$debug) {
                    $resultsynapseSqlPool = $SynapseSqlPool | Suspend-AzSqlDatabase
                }

                # Show that the Synapse SQL Pool has been pause and how long it took
                $endTimePause = Get-Date
                $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause

                if ($resultsynapseSqlPool.Status -eq "Paused") {
                    Write-Output "  -> Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
                }
                else {
                    if (!$debug) {
                        $iErrorCount += 1;
                        Write-Error "  -> (resultsynapseSqlPool.Status -eq ""Paused"") Synapse SQL Pool [$($resultsynapseSqlPool.DatabaseName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and $($durationPause.Seconds) seconds. Current status [$($resultsynapseSqlPool.Status)]"
                    }
                    else {
                        Write-Host "This is a debug session - Nothing was done" -ForegroundColor Yellow
                    }
                }           
            }
            ##########################################################################################################################################################
            else {
                $iErrorCount += 1;
                Write-Error "  -> ((SynapseSqlPool.Status -eq ""Online"")) Checking Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] found with status [$($SynapseSqlPool.Status)]"
            }
            ##########################################################################################################################################################
           
        }
    }
}

##########################################################################################################################################################
if ($iErrorCount > 0) {
    Write-Error -Message "Pause DB script error count ($($iErrorCount)) check logs" `
        -Exception ([System.Exception]::new()) -ErrorAction Stop 
}
