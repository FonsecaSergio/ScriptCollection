﻿$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption"

$workspaceName = "fonsecanetsynapse"
$ResourceGroup = "SynapseWorkspace"
$PoolName = "fonsecadwpool"

$LogAnalyticsName = "fonsecanetsynapselog"
$LogResGroup = "loganalytics"

$DiagnosticsName = "SQLSecurityAuditEvents"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

########################################################################################################
#CONNECT TO AZURE
Clear-Host

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    $x = Connect-AzAccount -Subscription $SubscriptionName
    $SubscriptionId = $x.Context.Subscription.Id
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Name -ne $SubscriptionName) {
        $Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -WarningAction Ignore
        Select-AzSubscription -Subscription $Subscription.Id | Out-Null
        Write-Host "Current subscription is $($Subscription.Name)"
        $SubscriptionId = $Subscription.Id
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
        $SubscriptionId = $Context.Subscription.Id
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
$uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/sqlPools/$PoolName/auditingSettings/default?api-version=2021-06-01"
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
$uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroup/providers/Microsoft.Synapse/workspaces/$workspaceName/sqlPools/$PoolName/providers/microsoft.insights/diagnosticSettings/$($DiagnosticsName)?api-version=2021-05-01-preview"
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
		"workspaceId": "/subscriptions/$SubscriptionID/resourcegroups/$LogResGroup/providers/Microsoft.OperationalInsights/workspaces/$LogAnalyticsName"
	}
}
"@
$body

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)
