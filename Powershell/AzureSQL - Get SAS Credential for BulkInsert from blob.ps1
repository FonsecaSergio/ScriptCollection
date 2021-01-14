<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Update Date: 2020-09-03

.SYNOPSIS   
   
.DESCRIPTION    
    # Script created based on https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-ver15#SAS
 
.PARAMETER xxxx 
       
#> 

Clear-Host

# Define global variables for the script  
$subscriptionName='SEFONSEC Microsoft Azure Internal Consumption'
$resourceGroupNameStorage = "StorageAccounts"
$storageAccountName= 'fonsecanetstorage'
$containerName= 'csv'
$policyName = 'BulkInsertPolicy'

# set the tenant, subscription and environment for use in the rest of   
Set-AzContext -SubscriptionName $subscriptionName   

# Get the access keys for the ARM storage account  
$accountKeys = Get-AzStorageAccountKey `
    -ResourceGroupName $resourceGroupNameStorage `
    -Name $storageAccountName  

# Create a new storage account context using an ARM storage account  
$storageContext = New-AzStorageContext `
    -StorageAccountName $storageAccountName `
    -StorageAccountKey $accountKeys[0].value 

# Creates a new container in blob storage  
$container = Get-AzStorageContainer `
    -Context $storageContext `
    -Name $containerName

$cbc = $container.CloudBlobContainer  

# Sets up a Stored Access Policy and a Shared Access Signature for the new container  

#Remove old policy if needed
<#
   Remove-AzStorageContainerStoredAccessPolicy -Container $containerName -Policy $policyName -Context $storageContext
   Remove-Variable policy
#>

$policy = Get-AzStorageContainerStoredAccessPolicy `
    -Container $containerName `
    -Policy $policyName `
    -Context $storageContext `
    -ErrorAction Ignore

if (!$policy)
{
    Write-Host "Policy ($($policyName)) does not exist- Creating now" -ForegroundColor Blue
    New-AzStorageContainerStoredAccessPolicy `
        -Container $containerName `
        -Policy $policyName `
        -Context $storageContext `
        -ExpiryTime $(Get-Date).ToUniversalTime().AddYears(10) `
        -Permission "rwld" | Out-Null
    
    $policy = Get-AzStorageContainerStoredAccessPolicy `
        -Container $containerName `
        -Policy $policyName `
        -Context $storageContext `
        -ErrorAction Ignore
}
else {
    Write-Host "Policy ($($policyName)) exist, check permission and start expire date" -ForegroundColor Blue
}

Write-Host $policy -ForegroundColor DarkBlue

$sas = New-AzStorageContainerSASToken `
    -Policy $policyName `
    -Context $storageContext `
    -Container $containerName

Write-Host 'Shared Access Signature = '$($sas.Substring(1))'' -ForegroundColor DarkGray

# Outputs the Transact SQL to the clipboard and to the screen to create the credential using the Shared Access Signature  
Write-Host 'Create Credential T-SQL was sent to CLIPBOARD' -ForegroundColor Blue
$tSql = "CREATE DATABASE SCOPED CREDENTIAL [{0}] WITH IDENTITY='Shared Access Signature', SECRET='{1}'" -f $cbc.Uri,$sas.Substring(1)   
$tSql | clip  
Write-Host $tSql -ForegroundColor Yellow