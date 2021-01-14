<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-xx-xx

.SYNOPSIS   
   
.DESCRIPTION    
 
.PARAMETER xxxx 
       
#> 


Clear-Host
Import-Module Az

########################################################################################################
#CONNECT TO AZURE
$SubscriptionName = "SEFONSEC Microsoft Azure Internal Consumption";

$Context = Get-AzContext
$Context
if($null -eq $Context)
{
    Connect-AzAccount
}
$Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
Set-AzContext $Subscription

Clear-Host
########################################################################################################

########################################################################################################
Get-AzSqlServerAudit `
    -ResourceGroupName "CSSAzureDB" `
    -ServerName "fonsecanet"

<#     
    ResourceGroupName                   : CSSAzureDB
    ServerName                          : fonsecanet
    AuditActionGroup                    : {SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP,
                                          FAILED_DATABASE_AUTHENTICATION_GROUP, BATCH_COMPLETED_GROUP}
    PredicateExpression                 :
    BlobStorageTargetState              : Enabled
    StorageAccountResourceId            : /subscriptions/de41dc76-12ed-4406-a032-0c96495def6b/resourceGro
                                          ups/StorageAccounts/providers/Microsoft.Storage/storageAccounts 
                                          /fonsecanetsqlaudit
    StorageKeyType                      : Primary
    RetentionInDays                     : 30
    EventHubTargetState                 : Disabled
    EventHubName                        :
    EventHubAuthorizationRuleResourceId :
    LogAnalyticsTargetState             : Enabled
    WorkspaceResourceId                 : /subscriptions/de41dc76-12ed-4406-a032-0c96495def6b/resourcegro
                                          ups/loganalytics/providers/microsoft.operationalinsights/worksp
                                          aces/fonsecanetloganalitics 
#>

########################################################################################################
Get-AzSqlDatabaseAudit `
    -ResourceGroupName "CSSAzureDB" `
    -ServerName "fonsecanet" `
    -DatabaseName "sandbox"

<# 
    DatabaseName                        : sandbox
    AuditAction                         : {}
    ResourceGroupName                   : CSSAzureDB
    ServerName                          : fonsecanet
    AuditActionGroup                    : {}
    PredicateExpression                 :
    BlobStorageTargetState              : Disabled
    StorageAccountResourceId            :
    StorageKeyType                      : None
    RetentionInDays                     :
    EventHubTargetState                 : Disabled
    EventHubName                        :
    EventHubAuthorizationRuleResourceId :
    LogAnalyticsTargetState             : Disabled
    WorkspaceResourceId                 : 
#>