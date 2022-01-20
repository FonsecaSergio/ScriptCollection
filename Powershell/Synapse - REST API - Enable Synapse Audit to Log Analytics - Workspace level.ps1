$SubscriptionId = "de41dc76-12ed-4406-a032-0c96495def6b"

$workspaceName = "fonsecanetsynapse"
$ResourceGroup = "SynapseWorkspace"

$LogAnalyticsName = "fonsecanetsynapselog"
$LogResGroup = "loganalytics"

$DiagnosticsName = "SQLSecurityAuditEvents"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

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

#https://docs.microsoft.com/en-us/rest/api/synapse/sqlserver/workspace-managed-sql-server-blob-auditing-policies/create-or-update
#PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Synapse/workspaces/{workspaceName}/auditingSettings/default?api-version=2021-06-01
# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
$headers = @{ Authorization = "Bearer $token" }

# ------------------------------------------
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/auditingSettings/default?api-version=2021-06-01"
$uri

$body = @"
{
	"properties": {
		"state": "Enabled",
		"storageEndpoint": "",
		"storageAccountAccessKey": "",
		"auditActionsAndGroups": [
			"SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP",
			"FAILED_DATABASE_AUTHENTICATION_GROUP",
			"BATCH_COMPLETED_GROUP"
		],
		"retentionDays": 0,
		"storageAccountSubscriptionId": null,
		"isStorageSecondaryKeyInUse": false,
		"isAzureMonitorTargetEnabled": true
	}
}
"@
$body

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)


#THIS WILL NOT CHANGE ANYTHING IN PORTAL UNTIL NEXT STEP IS DONE



########################################################################################################
#https://docs.microsoft.com/en-us/rest/api/monitor/diagnostic-settings/create-or-update
#PUT https://management.azure.com/{resourceUri}/providers/Microsoft.Insights/diagnosticSettings/{name}?api-version=2021-05-01-preview
#HTTP Method: PUT
#https://management.azure.com//subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.Synapse/workspaces/<wsName>/providers/microsoft.insights/diagnosticSettings/SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1?api-version=2017-05-01-preview

# ------------------------------------------
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/providers/microsoft.insights/diagnosticSettings/$($DiagnosticsName)?api-version=2021-05-01-preview"
$uri

$body = @"
{
	"properties": {
		"metrics": [],
		"logs": [
			{
				"category": "SQLSecurityAuditEvents",
				"enabled": true,
				"retentionPolicy": {
					"enabled": false,
					"days": 0
				}
			}
		],
		"workspaceId": "/subscriptions/$SubscriptionId/resourcegroups/$LogResGroup/providers/Microsoft.OperationalInsights/workspaces/$LogAnalyticsName"
	}
}
"@
$body

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)
