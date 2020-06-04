Param (
<#
 .SYNOPSYS
 Finds duplicate files based on a directory and a filetype filter.

 .DESCRIPTION
 Each folder is scanned recursivly for files that match a the given filter.  
 When a file is found the file is hashed and added to a collection based on the hash. 
 After all files are scanned the collection where files have the same has value are determined a duplicate and each duplicate's full path is printed to the screen.  

 .PARAMETER Directory
 The Directory of the file to search for duplicates in.

 .PARAMETER Filter
 The Filter used to perform the search for the directory specified. 

 .PARAMETER NoProgress
 If this switch is passed then the Write-Host is used instead of Write-Progress.  Helpful if scheduling as a task.


 .EXAMPLE
 Finds the duplicate xml files on the users desktop. 

 FindDuplicates -D %userprofile%\Desktop -F *.xml
 
#>
[Parameter(Mandatory=$False)]
[Alias("D")]
[ValidateScript({Test-Path $_ -PathType Container })]
$Directory = ".",  

[Parameter(Mandatory=$False)]
[Alias("F")]
$Filter="*",

[Parameter(Mandatory=$False)]
[Switch]
$NoProgress,

[Parameter(Mandatory=$False)]
[Switch]
$Delete

)

FUNCTION FindDupes($path, $filter="*") {
 
# Create C# type to increase the effeciency of identifying and grouping duplicate files.
$source = 
@"
    using System;
    using System.Collections.Generic;
    using System.IO;

    public class Dictionary
    {
        public Dictionary(){Console.WriteLine("Creating dictionary to hold files and check for duplicates");}

        // Dictionary will hold the string hash and the files that match each hash
        private Dictionary<String,List<FileInfo>> privateDict = new Dictionary<String,List<FileInfo>>();
    
        // Adds a file info to the dictionary based on the hash, silent unless passing debug
        public void Add(string key, FileInfo value, bool debug = false)
        {
            if (!privateDict.ContainsKey(key))
            {
                if(debug) { Console.WriteLine ("adding new List");}
                privateDict.Add(key, new List<FileInfo>());
            }
            
            if(debug) {Console.WriteLine ("adding {0} to {1}", value.FullName, key);}
            privateDict[key].Add(value);
        }

        // Get the dictionary
        public Dictionary<String,List<FileInfo>> GetDictionary()
        {
            return privateDict;
        }

        // Print the populated dictionary
        public void DisplayTree()
        {
            foreach ( string key in privateDict.Keys)
            {
                Console.WriteLine("Processing Key {0}", key);
                foreach (FileInfo fi in privateDict[key])
                {
                    Console.WriteLine("\t{0}", fi.FullName);
                }    
            }
        }
    }
    
"@

# .NET collections are faster then using |Where-Object |Sort-Object so add a simple type
Add-Type -TypeDefinition $source;

# What we want are exact binary duplicates across the directory, so, Create a haser and get all the items.
[System.Security.Cryptography.MD5]$hasher = [System.Security.Cryptography.MD5]::Create();
$allItems = Get-Item $path | Get-ChildItem -Recurse -File -Filter $filter 
$length = $allItems.Length
$groupHolder = New-Object Dictionary

$k=0;
$allItems | foreach { 
    if ( $NoProgress )
    { 
        Write-Host ("Hashing {0} " -f $_.FullName) 
    }
    else 
    { 
        Write-Progress -Activity "Grouping Files" -Status ("Hashing " + $_.FullName) -PercentComplete ((++$k/$length) * 100);
    }
    
    $hash = $hasher.ComputeHash([IO.File]::ReadAllBytes($_.FullName))
    $groupHolder.Add([String]::Concat($hash), $_, $false);
}

# store some statistics
$dupeSize = 0;
$dupeCount = 0;
$j =0;

# get the usable dictionary
$possibleDupes = $groupHolder.GetDictionary()


# Loop through all the files and check for duplicates based on the hash of the file
$possibleDupes.Keys | foreach {

    if ($NoProgress)
    {
        Write-Host "Processing Grouped files: Looking for duplicates"
    }
    else
    {
        Write-Progress -Activity "Processing Grouped files" -Status "Looking for Dupes..." -PercentComplete ($j++ / $possibleDupes.Count * 100);
    }
    
    # Files with no binary match will have a count of 1, all other files will 
    if ($possibleDupes[$_].Count -gt 1)
    {
        Write-Host "Files matching hashCode " $_ -ForegroundColor Yellow
        $i = 0;
        $possibleDupes[$_] | foreach {        
                if ($i++ -ge 1) 
                {
                    $dupeSize += $_.Length; 
                    $dupeCount++                                 #bytes     #kb    #mb 
                    Write-Host ("{0} {1}Kb" -f $_.FullName, ([Math]::Round($_.Length / 1024, 0)) ) -NoNewline
                    Write-Host " SHOULD DELETE" -ForegroundColor Red

                    if ($Delete)
                    {
                        Remove-Item -Path $_.FullName -Confirm
                    }

                }
                else 
                { 
                    Write-Host $_.FullName; 
                }
            }
        Write-Host
    }
}

Write-Host "Total Dupes: $dupeCount"        #bytes     #kb    #mb    
Write-Host ("Total Size : {0}mb" -f ([Math]::Round($DupeSize / 1024 / 1024 , 3)))
}

FindDupes -path $Directory -filter $filter