param(   
	$domain,   
	$password  
) 
$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)  

Install-WindowsFeature 
	-Name "AD-Domain-Services" '
	-IncludeManagementTools '
	-IncludeAllSubFeature
Install-ADDSForest 
	-DomainName $domain '
	-DomainMode Win2012 '
	-ForestMode Win2012 '
	-Force '
	-SafeModeAdministratorPassword $smPassword


--nova maquina
$scriptName = "install-active-directory.ps1" $scriptUri = http://$storageAccount.blob.core.windows.net/scripts/$scriptName $scriptArgument = "fabrikam.com $password" $imageFamily = "Windows Server 2012 R2 Datacenter" $imageName = Get-AzureVMImage |                 where { $_.ImageFamily -eq $imageFamily } |                            sort PublishedDate -Descending |                  select -ExpandProperty ImageName -First 1  
New-AzureVMConfig -Name $vmName `                   -InstanceSize $size `                   -ImageName $imageName |  
Add-AzureProvisioningConfig -Windows `                             -AdminUsername $adminUser `                              -Password $password | Set-AzureSubnet -SubnetNames $subnet | Set-AzureStaticVNetIP –IPAddress $ipAddress | Set-AzureVMCustomScriptExtension -FileUri $scriptUri `                                            -Run $scriptname `                                            -Argument "$domain $password" | New-AzureVM -ServiceName $serviceName `                       -Location $location `                       -VNetName $vnetName

--Maquina velha
Get-AzureVM -ServiceName $serviceName -Name $vmName | Set-AzureVMCustomScriptExtension -FileUri $scriptUri `                                            -Run $scriptname `                                            -Argument "$domain $password" | Update-AzureVM
