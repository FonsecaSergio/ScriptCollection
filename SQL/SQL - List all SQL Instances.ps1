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

$property = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
$instancesObject = $property.psobject.properties | ?{$_.Value -like 'MSSQL*'}  
$instances = $instancesObject.Value 

$instances