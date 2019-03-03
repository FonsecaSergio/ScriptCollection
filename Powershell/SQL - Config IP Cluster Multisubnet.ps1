Get-ClusterResource | Select Name, ResourceType

Get-ClusterResource "Cluster Name" | Get-ClusterParameter
Get-ClusterResource "AG_Adventure_AdventureVIP" | Get-ClusterParameter

Get-ClusterResource "Cluster Name" | Set-ClusterParameter RegisterAllProvidersIP 1
Get-ClusterResource "AG_Adventure_AdventureVIP" | Set-ClusterParameter RegisterAllProvidersIP 1
