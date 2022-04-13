 <#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-01-21
.SYNOPSIS   
#> 

param (
    [bool]$debug = $false
)

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
#Connect using Automation Account
##########################################################################################################################################################

$AzureContext = Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# getting credential to access to the Dedcated Sql Pool
$SQLServerCred = Get-AutomationPSCredential -Name "DedicatedSqlPool"


##########################################################################################################################################################
#Get SQL / Synapse RESOURCES
##########################################################################################################################################################
Write-Output ""
Write-Output "---------------------------------------------------------------------------------------------------"
Write-Output "Get SQL / Synapse RESOURCES"
Write-Output "---------------------------------------------------------------------------------------------------"

try {
    $AzureSQLServers = @(Get-AzSqlServer -ErrorAction Stop)
    $AzureSynapseWorkspaces = @(Get-AzSynapseWorkspace | Where-Object { $_.ExtraProperties.WorkspaceType -eq "Normal" } -ErrorAction Stop) #Filter connected synapse workspace with former SQL DW. Pause commands are different
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
            Write-Output "  -> Synapse Workspace [$($SynapseSqlPool.WorkspaceName)] -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] found with status [Online]"
           			
			# Checking running queries
            Write-Output "  -> Synapse Workspace [$($SynapseSqlPool.WorkspaceName)] -> Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)] looking for 'Running' queries"
			
			$endpoint = "$($SynapseSqlPool.WorkspaceName).sql.azuresynapse.net"
			$count = invoke-sqlcmd -ServerInstance $endpoint -Database $SynapseSqlPool.sqlpoolName -Query "Select count(*) active_queries from sys.dm_pdw_exec_requests where status in ('running', 'suspended')' and isnull([Label],'') != 'AutoPauseByAzureAutomationScript' option (Label = 'AutoPauseByAzureAutomationScript')" -Credential $SQLServerCred
			
			if($count.active_queries -gt 0){
				Write-Output "  -> [$($count.active_queries)] Active queries found. Ignoring this pool"}
			else
			{
				# Pause Synapse SQL Pool
				$startTimePause = Get-Date
				Write-Output "  -> [0] 'Running' queries found -> Pausing Synapse SQL Pool [$($SynapseSqlPool.SqlPoolName)]"
				
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
            Write-Output " -> This Server is part of Synapse Workspace - Ignore here. Should be done above using Az.Synapse Module"
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
                
				# Checking running queries
				Write-Output "  -> Synapse SQL Pool [$($SynapseSqlPool.DatabaseName)] looking for 'Running' queries"
				
				$endpoint = "$($SynapseSqlPool.ServerName).database.windows.net"
				$count = invoke-sqlcmd -ServerInstance $endpoint -Database $SynapseSqlPool.DatabaseName -Query "Select count(*) active_queries from sys.dm_pdw_exec_requests where status in ('running', 'suspended') and isnull([Label],'') != 'AutoPauseByAzureAutomationScript' option (Label = 'AutoPauseByAzureAutomationScript')" -Credential $SQLServerCred 

				if ($count.active_queries -gt 0) {
					Write-Output "  -> [$($count.active_queries)] Active queries found. Ignoring this pool"}
				else
				{
				
					# Pause Synapse SQL Pool
					$startTimePause = Get-Date
					Write-Output "  -> [0] 'Running' queries found -> Pausing Synapse SQL Pool"

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
