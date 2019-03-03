<#

    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
    the object code form of the Sample Code, provided that You agree: 
    (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
    (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
    (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
    including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
    conditions contained within the Premier Customer Services Description.
#>

<#
--SAMPLE TABLE 

CREATE TABLE TESTE123
(
	 SERVERNAME SYSNAME
	,HOST SYSNAME
)

#>

########################################################################################################################
#first we need to import SQLPS module
#https://technet.microsoft.com/en-us/library/cc281962(v=sql.105).aspx
Import-Module SQLPS -DisableNameChecking;

########################################################################################################################
$Servers = 
    'SEFONSECNOTE', 
    'LOCALHOST';

$Database = "SANDBOX"

########################################################################################################################
#GET INFORMATION
########################################################################################################################
[System.Collections.ArrayList]$DS_Servers = @();

foreach ($Server in $Servers)
{
    $DS_Servers += Invoke-Sqlcmd -ServerInstance $Server -Query "SELECT SERVER='$Server', ComputerNamePhysicalNetBIOS = SERVERPROPERTY('ComputerNamePhysicalNetBIOS');" -QueryTimeout 3;
}

$DS_Servers | SELECT SERVER, ComputerNamePhysicalNetBIOS;
########################################################################################################################
#SAVE INFORMATION
########################################################################################################################
foreach ($Server in $Servers)
{
    $Query = "TRUNCATE TABLE TESTE123"
    Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Query $Query -QueryTimeout 3;

    foreach ($row in $DS_Servers)
    {
        $Query = "INSERT INTO TESTE123 (SERVERNAME,HOST) VALUES ('" + $row["SERVER"] + "','" + $row["ComputerNamePhysicalNetBIOS"] + "')"
        Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Query $Query -QueryTimeout 3;
    }
}

