<#   
.NOTES   
    Author: Sergio Fonseca (@fonsecasergio)
    Last Updated: 2021-01-10

.SYNOPSIS   
    Look on images and videos in folder (Paramters folderPath) and 
    copy to folders based on datetake or date creation / date modification
   
.DESCRIPTION    
 
.PARAMETER folderPath 
    path where images and videos will be searched
    **By Design not recursive**
       
.PARAMETER DEBUG 
    if true = just simulate process
       
#> 

$ErrorActionPreference = "Stop"

Clear-Host
[string]$folderPath = "D:\OneDrive_Personal\OneDrive\Pictures\Imagens\TEMP\iPhone Sergio"
[bool]$DEBUG = $false


########################################################################################################
Function Get-FileMetaData { 
    # ----------------------------------------------------------------------------- 
    # https://devblogs.microsoft.com/scripting/use-powershell-to-find-metadata-from-photograph-files/
    # Script: Get-FileMetaDataReturnObject.ps1 
    # Author: ed wilson, msft 
    # Date: 01/24/2014 12:30:18 
    # Keywords: Metadata, Storage, Files 
    # comments: Uses the Shell.APplication object to get file metadata 
    # Gets all the metadata and returns a custom PSObject 
    # it is a bit slow right now, because I need to check all 266 fields 
    # for each file, and then create a custom object and emit it. 
    # If used, use a variable to store the returned objects before attempting 
    # to do any sorting, filtering, and formatting of the output. 
    # To do a recursive lookup of all metadata on all files, use this type 
    # of syntax to call the function: 
    # Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
    # note: this MUST point to a folder, and not to a file. 
    # ----------------------------------------------------------------------------- 

    <# 
    .Synopsis 
    This function gets file metadata and returns it as a custom PS Object  
    .Description 
    This function gets file metadata using the Shell.Application object and 
    returns a custom PSObject object that can be sorted, filtered or otherwise 
    manipulated. 
    .Example 
    Get-FileMetaData -folder "e:\music" 
    Gets file metadata for all files in the e:\music directory 
    .Example 
    Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
    This example uses the Get-ChildItem cmdlet to do a recursive lookup of  
    all directories in the e:\music folder and then it goes through and gets 
    all of the file metada for all the files in the directories and in the  
    subdirectories.   
    .Example 
    Get-FileMetaData -folder "c:\fso","E:\music\Big Boi" 
    Gets file metadata from files in both the c:\fso directory and the 
    e:\music\big boi directory. 
    .Example 
    $meta = Get-FileMetaData -folder "E:\music" 
    This example gets file metadata from all files in the root of the 
    e:\music directory and stores the returned custom objects in a $meta  
    variable for later processing and manipulation. 
    .Parameter Folder 
    The folder that is parsed for files  
    .Notes 
    NAME:  Get-FileMetaData 
    AUTHOR: ed wilson, msft 
    LASTEDIT: 01/24/2014 14:08:24 
    KEYWORDS: Storage, Files, Metadata 
    HSG: HSG-2-5-14 
    .Link 
        Http://www.ScriptingGuys.com 
    #Requires -Version 2.0 
    #> 
    Param([string[]]$folder) 
    foreach ($sFolder in $folder) { 
        $a = 0 
        $objShell = New-Object -ComObject Shell.Application 
        $objFolder = $objShell.namespace($sFolder) 
 
        foreach ($File in $objFolder.items()) {  
    
            $FileMetaData = New-Object PSOBJECT 
            for ($a ; $a -le 266; $a++) {  
                if ($objFolder.getDetailsOf($File, $a)) { 
                    $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a)) = 
                        $($objFolder.getDetailsOf($File, $a)) 
                    } 
                    $FileMetaData | Add-Member $hash 
                    $hash.clear()  
                } #end if 
            } #end for  
            $a = 0 
            $FileMetaData          
        } #end foreach $file 
    } #end foreach $sfolder 
} #end Get-FileMetaData

########################################################################################################
function Get-AsciiFromUnicode {
    Param([string]$UnicodeString)

    $encoding = [System.Text.Encoding]::ASCII
    $uencoding = [System.Text.Encoding]::UNICODE
    [System.Text.Encoding]::Convert([System.Text.Encoding]::UNICODE, $encoding, $uencoding.GetBytes($DateTaken)) | % { $myStr += [char]$_ }
    $myStr = ($myStr.Replace("?", ""))
    $myStr
} #end Get-AsciiFromUnicode
########################################################################################################


########################################################################################################

#Remove-Variable -Name "Files"

if ($Files -eq $null) { 
    if ($DEBUG)
    { Write-Host "Get-FileMetaData ($($folderPath))" -ForegroundColor Yellow }

    $Files = Get-FileMetaData -folder $folderPath
    $Files = $Files | Where-Object -Property Kind -ne "Folder"
}
else { 
    if ($DEBUG)
    { Write-Host "Already got file metadata ($($folderPath))" -ForegroundColor Yellow }
    
}

if ($DEBUG) {
    $Files | Out-GridView
}


[int]$QtFiles = $Files.Count
[int]$QtFilesCopied = 0

#####################################################################################################################

Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "IMAGES" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow

#####################################################################################################################
$picMetadata = $Files | Where-Object -Property Kind -eq "Picture"

[int]$QtFilesImages = $picMetadata.Count

foreach ($picture in $picMetadata) {
    ##########################################################################
    Write-Host "---------------------------------------------------" -ForegroundColor Red
    Write-Host "Name ($($picture.Name))" -ForegroundColor Red

    ##########################################################################
    $DateCreated = ($picture.'Date created').Substring(0, 10)
    $DateCreated = [datetime]::parseexact($DateCreated, 'dd/MM/yyyy', $null)
    Write-Host " - DateCreated ($($DateCreated.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow

    ##########################################################################
    $DateModified = ($picture.'Date modified').Substring(0, 10)
    $DateModified = [datetime]::parseexact($DateModified, 'dd/MM/yyyy', $null)
    Write-Host " - DateModified ($($DateModified.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow
    ##########################################################################
    $FolderNameToCreate = "NODATEINFO"
    ##########################################################################

    if (($picture.'Date taken') -ne $null) {
        $DateTaken = ($picture.'Date taken').Substring(0, 13)
        $DateTaken = Get-AsciiFromUnicode -UnicodeString $DateTaken

        #$DateTaken
        ##########################################################################
        $DateTaken = [datetime]::parseexact($DateTaken, 'dd/MM/yyyy', $null)
        Write-Host " - DateTaken ($($DateTaken.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow
        ##########################################################################
        $FolderNameToCreate = $DateTaken
    }
    else {           
        Write-Host " - DateTaken (NULL)" -ForegroundColor DarkYellow

        if ($DateCreated -gt $DateModified)
        { $FolderNameToCreate = $DateCreated }
        else
        { $FolderNameToCreate = $DateModified }
    }

    ################################################################################################
    $FolderNameToCreate = $FolderNameToCreate.ToString("yyyy-MM-dd")

    Write-Host "  * FolderToCreate ($($FolderNameToCreate))" -ForegroundColor Yellow

    $PathFolderToCreate = "$($folderPath)\$($FolderNameToCreate)"
    $PathFolderToCreate = $PathFolderToCreate.Replace("\\", "\")

    ################################################################################################
    if (!(Test-Path -Path $PathFolderToCreate)) {
        if (!($DEBUG))
        { New-Item -Path $PathFolderToCreate -ItemType directory | Out-Null }
        else
        { Write-Host "  - New-Item -Path $($PathFolderToCreate) -ItemType directory | Out-Null" -ForegroundColor Gray }
    }

    ################################################################################################
    Write-Host "  * Copy-Item -Path $($picture.Path) -Destination $($PathFolderToCreate)" -ForegroundColor Yellow
    if (!($DEBUG))
    { Copy-Item -Path $picture.Path -Destination $PathFolderToCreate }
    
    $QtFilesCopied += 1
    ################################################################################################
}








#####################################################################################################################

Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "VIDEOS" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow

#####################################################################################################################
$vidMetadata = $Files | Where-Object -Property Kind -eq "Video"

[int]$QtFilesVideos = $vidMetadata.Count

foreach ($video in $vidMetadata) {
    Write-Host "---------------------------------------------------" -ForegroundColor Red
    Write-Host "Name ($($video.Name))" -ForegroundColor Red

    ##########################################################################
    $DateCreated = ($video.'Date created').Substring(0, 10)
    $DateCreated = [datetime]::parseexact($DateCreated, 'dd/MM/yyyy', $null)
    Write-Host " - DateCreated ($($DateCreated.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow

    ##########################################################################
    $DateModified = ($video.'Date modified').Substring(0, 10)
    $DateModified = [datetime]::parseexact($DateModified, 'dd/MM/yyyy', $null)
    Write-Host " - DateModified ($($DateModified.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow
    ##########################################################################
    $FolderNameToCreate = "NODATEINFO"
    ##########################################################################

    if (($video.'Media Created') -ne $null) {
        $DateTaken = ($video.'Media Created').Substring(0, 13)
        $DateTaken = Get-AsciiFromUnicode -UnicodeString $DateTaken

        #$DateTaken
        ##########################################################################
        $DateTaken = [datetime]::parseexact($DateTaken, 'dd/MM/yyyy', $null)
        Write-Host " - MediaCreated ($($DateTaken.ToString("yyyy-MM-dd")))" -ForegroundColor DarkYellow
        ##########################################################################
        $FolderNameToCreate = $DateTaken
    }
    else {           
        Write-Host " - DateTaken (NULL)" -ForegroundColor DarkYellow

        if ($DateCreated -gt $DateModified)
        { $FolderNameToCreate = $DateCreated }
        else
        { $FolderNameToCreate = $DateModified }
    }

    ################################################################################################
    $FolderNameToCreate = $FolderNameToCreate.ToString("yyyy-MM-dd")

    Write-Host "  * FolderToCreate ($($FolderNameToCreate))" -ForegroundColor Yellow

    $PathFolderToCreate = "$($folderPath)\$($FolderNameToCreate)"
    $PathFolderToCreate = $PathFolderToCreate.Replace("\\", "\")

    ################################################################################################
    if (!(Test-Path -Path $PathFolderToCreate)) {
        if (!($DEBUG))
        { New-Item -Path $PathFolderToCreate -ItemType directory | Out-Null }
        else
        { Write-Host "  - New-Item -Path $($PathFolderToCreate) -ItemType directory | Out-Null" -ForegroundColor Gray }
    }

    ################################################################################################
    Write-Host "  * Copy-Item -Path $($video.Path) -Destination $($PathFolderToCreate)" -ForegroundColor Yellow
    if (!($DEBUG))
    { Copy-Item -Path $video.Path -Destination $PathFolderToCreate }

    [int] $QtFilesCopied += 1
    ################################################################################################

}


Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "QtFiles ($($QtFiles))" -ForegroundColor Cyan
Write-Host "QtFilesImages ($($QtFilesImages))" -ForegroundColor Cyan
Write-Host "QtFilesVideos ($($QtFilesVideos))" -ForegroundColor Cyan
Write-Host "QtFilesOther ($($QtFiles - $QtFilesImages - $QtFilesVideos))" -ForegroundColor Cyan
Write-Host "QtFilesCopied ($($QtFilesCopied))" -ForegroundColor Cyan
if ($QtFiles -eq $QtFilesCopied) {
    Write-Host "OK QtFiles = QtFilesCopied" -ForegroundColor Green
}
else {
    Write-Error "QtFiles != QtFilesCopied"
}
Write-Host "-------------------------------------------" -ForegroundColor Cyan
