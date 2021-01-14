<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-xx-xx

.SYNOPSIS   
   
.DESCRIPTION    
    GET NTFS BLOCKSIZE
    http://msdn.microsoft.com/en-us/library/dd758814%28v=SQL.100%29.aspx
 
.PARAMETER xxxx 
       
#> 

[string] $serverName = "localhost"

$vols = Get-WmiObject -computername $serverName -query "select name, blocksize from Win32_Volume where Capacity <> NULL and DriveType = 3"

foreach($vol in $vols)
{
    [string] $drive = "{0}" -f $vol.name + ";" + $vol.blocksize
    Write-Output $drive
} 