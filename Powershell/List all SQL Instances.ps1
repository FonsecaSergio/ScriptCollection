$property = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
$instancesObject = $property.psobject.properties | ?{$_.Value -like 'MSSQL*'}  
$instances = $instancesObject.Value 

$instances