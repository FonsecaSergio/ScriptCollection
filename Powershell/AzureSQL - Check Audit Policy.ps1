Connect-AzureRmAccount

########################################################################################################
Get-AzureRmSqlServerAuditingPolicy -ResourceGroupName "CSSAzureDB" -ServerName "fonsecanet"

#AuditType                    : Blob
#AuditActionGroup             : {SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP, 
#                               FAILED_DATABASE_AUTHENTICATION_GROUP, BATCH_COMPLETED_GROUP}
#ResourceGroupName            : CSSAzureDB
#ServerName                   : fonsecanet
#AuditState                   : Enabled
#StorageAccountName           : fonsecanetstorage
#StorageAccountSubscriptionId : de41dc76-12ed-4406-a032-0c96495def6b
#StorageKeyType               : Primary
#RetentionInDays              : 30

########################################################################################################
Get-AzureRmSqlDatabaseAuditingPolicy -ResourceGroupName "CSSAzureDB" -ServerName "fonsecanet" -DatabaseName "sandbox"

#AuditType                    : Blob
#DatabaseName                 : sandbox
#AuditAction                  : {}
#AuditActionGroup             : {SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP, 
#                               FAILED_DATABASE_AUTHENTICATION_GROUP, BATCH_COMPLETED_GROUP}
#ResourceGroupName            : CSSAzureDB
#ServerName                   : fonsecanet
#AuditState                   : Enabled
#StorageAccountName           : fonsecanetstorage
#StorageAccountSubscriptionId : de41dc76-12ed-4406-a032-0c96495def6b
#StorageKeyType               : Primary
#RetentionInDays              : 30