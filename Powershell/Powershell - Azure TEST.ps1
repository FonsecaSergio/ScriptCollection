#Conecta no Azure com sua conta
Add-AzureAccount

#Lista Subscriptions
Get-AzureSubscription | select SubscriptionName

$SubscriptionName = 'Visual Studio Ultimate com MSDN - Microsoft'

#Seleciona Subscriptions
Select-AzureSubscription –SubscriptionName $SubscriptionName

#Lista StorageAccount
Get-AzureStorageAccount | select StorageAccountName, Location, GeoPrimaryLocation

$StorageAccount = 'fonsecastorage'

#Seleciona StorageAccount
Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccount $StorageAccount

#Seleciona Subscriptions, ver detalhes
Select-AzureSubscription -SubscriptionName $SubscriptionName

#---------------------------------------------------------------------------------------------------------
#Onde vai ficar a VM
$dclocation = 'West US'

#Container da VM
$cloudSvcName = 'FonsecanetPowershellTest'

#Test if cloudSvcName is AVAILABLE -- FALSE = LIVRE
Test-AzureName -Service $cloudSvcName

#Seleciona IMAGE
$image = (Get-AzureVMImage | Where {$_.ImageFamily -eq "Windows Server 2012 R2 Datacenter" } | sort PublishedDate -Descending | Select-Object -First 1).ImageName
$image

#VM Simples
$adminUserName = 'FonsecaSergio'
$adminPassword = 'Pa$$word'
$vmname = 'PowershellVM'

New-AzureQuickVM -AdminUserName $adminUserName -Windows -ServiceName $cloudSvcName -Name $vmname -ImageName $image -Password $adminPassword -Location $dclocation

#Ver Status
Get-AzureVM -ServiceName $cloudSvcName 
Get-AzureVM -ServiceName $cloudSvcName -Name $vmname | select status

# Restart
Restart-AzureVM -ServiceName $cloudSvcName -Name $vmname

# Shutdown 
Stop-AzureVM -ServiceName $cloudSvcName -Name $vmname

# Start
Start-AzureVM -ServiceName $cloudSvcName -Name $vmname

#New VM Complexa
$vmname2 = 'mytestvm2'
$vmname3 = 'mytestvm3'

$vm2 = New-AzureVMConfig -Name $vmname2 -InstanceSize ExtraSmall -ImageName $image | 
    Add-AzureProvisioningConfig -Windows -AdminUserName $adminUserName -Password $adminPassword | 
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 50 -DiskLabel 'datadisk1' -LUN 0 | 
    Add-AzureEndpoint -Protocol tcp -LocalPort 80 -PublicPort 80 -Name 'lbweb' -LBSetName 'lbweb' -ProbePort 80 -ProbeProtocol http -ProbePath '/' 

$vm3 = New-AzureVMConfig -Name $vmname3 -InstanceSize ExtraSmall -ImageName $image | 
    Add-AzureProvisioningConfig -Windows -AdminUserName $adminUserName -Password $adminPassword  | 
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 50 -DiskLabel 'datadisk2' -LUN 0  | 
    Add-AzureEndpoint -Protocol tcp -LocalPort 80 -PublicPort 80 -Name 'lbweb' -LBSetName 'lbweb' -ProbePort 80 -ProbeProtocol http -ProbePath '/' 

New-AzureVM -ServiceName $cloudSvcName -VMs $vm2,$vm3

#Update VM
$vmname = 'PowershellVM'

Get-AzureVM -Name $vmname -ServiceName $cloudSvcName | 
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 50 -DiskLabel 'datadisk1' -LUN 0 | 
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 50 -DiskLabel 'translogs1' -LUN 1 |
    Add-AzureEndpoint -Protocol tcp -LocalPort 1433 -PublicPort 2000 -Name 'sql' | 
    Update-AzureVM 

#Get RDP File
Get-AzureRemoteDesktopFile -ServiceName $cloudSvcName -Name $vmname -LocalPath 'C:\Temp\myvmconnection.rdp' -Launch 


Stop-AzureVM -ServiceName $cloudSvcName -Name $vmname2
Stop-AzureVM -ServiceName $cloudSvcName -Name $vmname3