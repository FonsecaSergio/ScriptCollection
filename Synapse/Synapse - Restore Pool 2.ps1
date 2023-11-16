$SubscriptionId = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$ResourceGroupName = 'SynapseWorkspace'
$WorkspaceName = 'xxxxxxxxxxxxx'
$SourcePoolName = 'yyyyyyyyyyyy'
$TargetSqlPoolName = 'yyyyyyyyyyyy_BKP'


Connect-AzAccount -Subscription $SubscriptionId



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

try {

    $Output = Restore-AzSynapseSqlPool `
    -FromRestorePoint `
    -RestorePoint $restorePoint.RestorePointCreationDate `
    -Name $TargetSqlPoolName `
    -ResourceGroupName $pool.ResourceGroupName `
    -WorkspaceName $pool.WorkspaceName `
    -ResourceId $databaseId `
    -PerformanceLevel DW100c `
    -Confirm:$false

    Write-Output "Successfully restored SQL Pool"
    Write-Output $Output
}
catch
{
    Write-Output $_
    Do
    {
        # List ALL sql pools under the $TargetWorkspace .
        # IMPORTANT: do not add parameter for sql pool name as ARM has negative caching:
        # ARM may cache the fact that creation of the sql pool failed and return NotFound error without forwarding the request to the resource provider
        $sqlPools = Get-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -WorkspaceName $pool.WorkspaceName

        # check if the sql pool with name $TargetSqlPoolName is in the $sqlPools list
        $foundSqlPool= ....

        # check if sql pool is found and restore is in progress, sleep 5 minutes
        $isRestoreInProgress = ($foundSqlPool -ne $null) -and ($foundSqlPool.Status -ne "Online")
        if ($isRestoreInProgress)
        {
            Start-Sleep -Seconds 300
        }
        elseif ($foundSqlPool.Status -eq "Online")
        {
            Write-Output "Successfully restored SQL Pool database"
            # ARM negative caching can still be in effect: if Get-AzSynapseSqlPool returns NotFound 
            # Do New-AzSynapseSqlPool - it will send PUT request to the backend 
            # which is treated as "update" operation for exsiting sql pools and will return qucikly with 200 as there are not properties to update
            try
            {
                $foundSqlPool = Get-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -WorkspaceName $pool.WorkspaceName -SqlPoolName $TargetSqlPoolName
                Write -Output "Successfully get SQL Pool database"
                Write-Output $Output
            }
            catch
            {
               $foundSqlPool = New-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -WorkspaceName $pool.WorkspaceName -SqlPoolName $TargetSqlPoolName -PerformanceLevel DW100c
            }
        }
    }
    While($isRestoreInProgress)
}
 