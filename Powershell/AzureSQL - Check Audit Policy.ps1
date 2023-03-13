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
$SubscriptionName = "Microsoft Azure";

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
    -ServerName "SERVERNAME"

<#     
    ResourceGroupName                   : CSSAzureDB
    ServerName                          : SERVERNAME
    AuditActionGroup                    : {SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP,
                                          FAILED_DATABASE_AUTHENTICATION_GROUP, BATCH_COMPLETED_GROUP}
    PredicateExpression                 :
    BlobStorageTargetState              : Enabled
    StorageAccountResourceId            : /subscriptions/de41dc76XXXXXXXXXXXXXXXXXXX/resourceGro
                                          ups/StorageAccounts/providers/Microsoft.Storage/storageAccounts 
                                          /STORAGENAME
    StorageKeyType                      : Primary
    RetentionInDays                     : 30
    EventHubTargetState                 : Disabled
    EventHubName                        :
    EventHubAuthorizationRuleResourceId :
    LogAnalyticsTargetState             : Enabled
    WorkspaceResourceId                 : /subscriptions/de41dc76XXXXXXXXXXXXXXXXXXX/resourcegro
                                          ups/loganalytics/providers/microsoft.operationalinsights/worksp
                                          aces/NAMEloganalitics 
#>

########################################################################################################
Get-AzSqlDatabaseAudit `
    -ResourceGroupName "CSSAzureDB" `
    -ServerName "SERVERNAME" `
    -DatabaseName "sandbox"

<# 
    DatabaseName                        : sandbox
    AuditAction                         : {}
    ResourceGroupName                   : CSSAzureDB
    ServerName                          : SERVERNAME
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