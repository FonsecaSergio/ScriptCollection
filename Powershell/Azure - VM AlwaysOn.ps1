#Gerar publishsettings
Get-AzurePublishSettingsFile

################################################################################################################################################################################

Import-AzurePublishSettingsFile -PublishSettingsFile "C:\Users\Sergio\SkyDrive\Visual Studio Ultimate com MSDN - Microsoft-credentials.publishsettings"

################################################################################################################################################################################

# Define variables
$AGNodes = "SQL-AON-01","SQL-AON-02" # all availability group nodes should be included, separated by commas
$ServiceName = "SQL-AON" # the name of the cloud service that contains the availability group nodes
$EndpointName = "AlwaysOnListener" # name of the endpoint
$EndpointPort = "1433" # public port to use for the endpoint

# Configure a load balanced endpoint for each node in $AGNodes, with direct server return enabled
ForEach ($node in $AGNodes)
{
    Get-AzureVM -ServiceName $ServiceName -Name $node | Add-AzureEndpoint -Name $EndpointName -Protocol "TCP" -PublicPort $EndpointPort -LocalPort $EndpointPort -LBSetName "$EndpointName-LB" -ProbePort 59999 -ProbeProtocol "TCP" -DirectServerReturn $true | Update-AzureVM
}


################################################################################################################################################################################
# RODA NA VM - PRIMARY NODE
################################################################################################################################################################################

$ag = "AG-AON" # The availability group name 
$serviceName = "SQL-AON" # The cloud service name 
$networkName = "Cluster Network 1" # The cluster network name, usually "Cluster Network 1" if the nodes are in the same subnet 
$listenerPort = "1433" # Listener port. Same as the endpoint port.

$aglistener = $ag + "Listener" 
$agendpoint = (Resolve-DnsName -Name "$serviceName.cloudapp.net").IPAddress  

Import-Module FailoverClusters 
# Add IP address resource for the listener to AG resource group. The probe port is set so the AG owner node will respond to probes from Windows Azure. 
Add-ClusterResource "IP Address $agendpoint" -ResourceType "IP Address" -Group $ag | Set-ClusterParameter -Multiple @{"Address"="$agendpoint";"ProbePort"="59999";SubnetMask="255.255.255.255";"Network"="$networkName";"OverrideAddressMatch"=1;"EnableDhcp"=0} 
# Add Network Name resource for the listener to AG resource group 
Add-ClusterResource -Name $aglistener -ResourceType "Network Name" -Group $ag | Set-ClusterParameter -Multiple @{"Name"=$aglistener;"DnsName"=$aglistener} 
# Set dependency for the Network Name resource on the IP address resource  
Get-ClusterResource -Name $aglistener | Set-ClusterResourceDependency "[IP Address $agendpoint]" 
# Start the listener resource 
Start-ClusterResource -Name $aglistener 
# Set dependency for the AG resource group on the listener's network name 
Get-ClusterResource -Name $ag | Set-ClusterResourceDependency "[$aglistener]" 
# Change port number on the listener to 1433 
Set-SqlAvailabilityGroupListener -Path SQLSERVER:\SQL\$env:COMPUTERNAME\DEFAULT\AvailabilityGroups\$ag\AvailabilityGroupListeners\$aglistener -Port $listenerPort 
