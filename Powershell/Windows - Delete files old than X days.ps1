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

$limit = (Get-Date).AddDays(-15)
$path = "C:\temp\teste"
$FileNameLike = "SQLMaint*.txt"

Get-ChildItem -Path $path -Force | `
    Where-Object { ($_.Name -like $FileNameLike) -and $_.LastWriteTime -lt $limit } | `
    SELECT Name, LastWriteTime

# Delete files older than the $limit.
Get-ChildItem -Path $path -Force | `
    Where-Object { ($_.Name -like $FileNameLike) -and $_.LastWriteTime -lt $limit } | `
    Remove-Item -Force
