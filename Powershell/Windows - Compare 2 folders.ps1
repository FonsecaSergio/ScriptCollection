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

$fso = Get-ChildItem -Recurse -path "D:\Fotos"
$fsoBU = Get-ChildItem -Recurse -path "D:\OneDrive\Pictures\Imagens"
$X = Compare-Object -ReferenceObject $fso -DifferenceObject $fsoBU  -Property Name,Length
$X | Out-GridView