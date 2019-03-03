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


    http://www.microsoft.com/en-us/download/confirmation.aspx?id=17148

    Ex. PortQry.exe -n 192.168.2.125 -e 1433
    Ex. PortQry.exe -n 192.168.2.125 -e 1434 -p UDP



    --CREATE TABLE

    USE [SANDBOX]
    GO

    DROP TABLE [dbo].[PortQry]
    GO

    SET ANSI_NULLS ON
    GO

    SET QUOTED_IDENTIFIER ON
    GO

    SET ANSI_PADDING ON
    GO

    CREATE TABLE [dbo].[PortQry](
	    [Date] [datetime2](0) NULL CONSTRAINT [DF_PortQry_Date]  DEFAULT (sysdatetime()),
	    [Command] [varchar](100) NULL,
	    [Server] [varchar](255) NULL,
	    [Port] [varchar](20) NULL,
	    [Output] [varchar](max) NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

    GO

    SET ANSI_PADDING OFF
    GO


    SELECT * FROM [dbo].[PortQry] 
    WHERE 
		Output LIKE '%LISTENING%'


    --TRUNCATE TABLE [dbo].[PortQry]



#>

Clear-Host #Limpa Tela

########################################################################################################################################
#CONFIG
########################################################################################################################################
[Array] $servers =  "localhost",
                    "ERRO",
                    "SEFONSECNOTE"

[Array] $ports = "1433 -p TCP",
                 "80 -p TCP",
                 "135 -p TCP",
                 "1434 -p UDP"; 

$LOG_SERVER_connectionString  = "Server=LOCALHOST;Database=SANDBOX;Integrated Security=SSPI"
$LIST_SERVER_connectionString = "Server=LOCALHOST;Database=SANDBOX;Integrated Security=SSPI"
$LIST_SERVER_Command = "SELECT SERVER = 'LOCALHOST' UNION ALL SELECT SERVER = 'SEFONSECNOTE' UNION ALL SELECT SERVER = '127.0.0.1'"

$PortQryExe = "C:\Users\sefonsec\Downloads\PortQryV2\PortQry.exe"


$DEBUG_PrintToScreen = 0;
$DEBUG_SaveToSQL = 1;



########################################################################################################################################
#GET SERVER LIST
########################################################################################################################################
$conn = New-Object System.Data.SqlClient.SqlConnection($LIST_SERVER_connectionString) # SQL Connection String
$conn.Open() # Open SQL Connection 
    
$cmd = $conn.CreateCommand() # Set up SQLCommand object

$cmd.CommandText = $LIST_SERVER_Command # Configure TSQL

Try {
    if ($DEBUG_PrintToScreen -eq 1)
    {
        Write-Output ("{0}" -f $cmd.CommandText)
    }
    $ServersList = $cmd.ExecuteReader() 
}
Catch {
    Write-Warning "$_" # Report SQL Errors 
}
    

########################################################################################################################################
#SERVERS LOOP
########################################################################################################################################
#foreach($server in $servers) ##LISTA FIXA
foreach($serverAux in $ServersList) ##LISTA DINAMICA
{ 
    $server = $serverAux[0]

    Write-Output ("Server: {0}" -f $server);

    ########################################################################################################################################
    #PORTS LOOP
    ########################################################################################################################################
    foreach($port in $ports)
    {

        Try
        {
            $command = $PortQryExe + " -n " + $server + " -e " + $port

          
            $Output = invoke-expression -command $command | select

            #Validate WINRM :: winrm quickconfig
            #$Output = Invoke-Command -ComputerName $server -ScriptBlock {$command} | select
        
            $OutputString = ""
            Foreach ($line in $Output)
            {
                $OutputString = $OutputString + $line -replace "'",""
            }
            ########################################################################################################################################
            #WHITE TO SCREEN
            ########################################################################################################################################
            if ($DEBUG_PrintToScreen -eq 1)
            {
                Write-Output ("Command: {0} - Server: {1} - Port: {2} - Output: {3}" -f $command, $server, $port, $OutputString);
            }
            

            ########################################################################################################################################
            #WRITE TO DB
            ########################################################################################################################################
            if ($DEBUG_SaveToSQL -eq 1)
            {
                $conn = New-Object System.Data.SqlClient.SqlConnection($LOG_SERVER_connectionString) # SQL Connection String
                $conn.Open() # Open SQL Connection 
    
                $cmd = $conn.CreateCommand() # Set up SQLCommand object
                
                #INSERE VARIAS LINHAS
                Foreach ($line in $Output)
                {
                    $line = $line -replace "'",""
                    if ($line -ne "")
                    {
                        $cmd.CommandText ="INSERT INTO [dbo].[PortQry]([Command],[Server],[Port],[Output]) VALUES ('$command', '$server', '$port' , '$line')" # Configure TSQL
                        Try {
                            if ($DEBUG_PrintToScreen -eq 1)
                            {
                                Write-Output ("{0}" -f $cmd.CommandText)
                            }
                            $LIXO = $cmd.ExecuteNonQuery() # 
                        }
                        Catch {
                            Write-Warning "$_" # Report SQL Errors 
                        }
                    }

                }
                
                #INSERE LINHA UNICA
                #$cmd.CommandText ="INSERT INTO [dbo].[PortQry]([Command],[Server],[Port],[Output]) VALUES ('$command', '$server', '$port' , '$OutputString')" # Configure TSQL
                #Try {
                #    if ($DEBUG_PrintToScreen -eq 1)
                #    {
                #        Write-Output ("{0}" -f $cmd.CommandText)
                #    }
                #    $cmd.ExecuteNonQuery() # 
                #}
                #Catch {
                #    Write-Warning "$_" # Report SQL Errors 
                #} 
    
                $conn.Close() # Close SQL Connection
            }
            ########################################################################################################################################
        }
        Catch
        {
            Write-Warning "$_" # Report Errors Get-Service
        }

    }
       
}

Write-Output ("################")
Write-Output ("# FIM PROCESSO #")
Write-Output ("################")
            