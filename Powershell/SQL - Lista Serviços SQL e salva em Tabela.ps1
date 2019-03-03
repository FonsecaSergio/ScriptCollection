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
    --CREATE TABLE

    USE [SANDBOX]
    GO

    CREATE TABLE [dbo].[tServiceStates](
	    [Data] [datetime2](0) NOT NULL,
	    [Server] [varchar](255) NOT NULL,
	    [Service] [varchar](50) NOT NULL,
	    [Status] [varchar](50) NOT NULL,
     CONSTRAINT [PK_tServiceStates] PRIMARY KEY CLUSTERED 
    (
	    [Data] ASC,
	    [Server] ASC,
	    [Service] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]

    GO

    ALTER TABLE [dbo].[tServiceStates] ADD  CONSTRAINT [DF_tServiceStates_Data]  DEFAULT (sysdatetime()) FOR [Data]
    GO



#>

Clear-Host #Limpa Tela

########################################################################################################################################
#CONFIG
########################################################################################################################################
[Array] $servers = "localhost",
                   "ERRO",
                   "SEFONSECNOTE";

$LOG_SERVER_connectionString = "Server=LOCALHOST;Database=SANDBOX;Integrated Security=SSPI"


$DEBUG_PrintToScreen = 1;
$DEBUG_SaveToSQL = 1;



########################################################################################################################################
#SERVERS LOOP
########################################################################################################################################
foreach($server in $servers) 
{ 
    ########################################################################################################################################
    #READ SERVICES DATA
    ########################################################################################################################################
    Try
    {
        Write-Output ("--------------------------------------") 
        Write-Output ("Server: {0}" -f $server);
        Write-Output ("--------------------------------------")

        $SQLServices  = Get-Service -ComputerName $server | select status, name | Where-Object{ 
            ($_.Name -like "MSSQLSERVER*") -or

            ($_.Name -like "MSSQLServerOLAPService*") -or  #SSAS Default
            ($_.Name -like "MSOLAP*") -or #SSAS Instance

            ($_.Name -like "MsDtsServer*") -or
            ($_.Name -like "ReportServer*") -or
            ($_.Name -like "SQLSERVERAGENT*")    
        }

        ########################################################################################################################################
        #WHITE TO SCREEN SERVICES DATA
        ########################################################################################################################################
        if ($DEBUG_PrintToScreen -eq 1)
        {
            foreach($SQLService in $SQLServices)
            {
                Write-Output ("Service: {1} - Status: {2}" -f $server, $SQLService.name, $SQLService.status);
            }
        }
    
    
        ########################################################################################################################################
        #WRITE TO DB SERVICES DATA
        ########################################################################################################################################
        if ($DEBUG_SaveToSQL -eq 1)
        {
            $conn = New-Object System.Data.SqlClient.SqlConnection($LOG_SERVER_connectionString) # SQL Connection String
            $conn.Open() # Open SQL Connection


            foreach($SQLService in $SQLServices)
            {
                $ServiceName = $SQLService.name
                $ServiceStatus = $SQLService.status


                $cmd = $conn.CreateCommand() # Set up SQLCommand object
                $ErrorActionPreference = 'stop' # Prepare script for stopping
                $cmd.CommandText ="INSERT INTO [dbo].[tServiceStates] ([Server],[Service],[Status]) VALUES ('$server', '$ServiceName', '$ServiceStatus')" # Configure TSQL
                Try {
                    if ($DEBUG_PrintToScreen -eq 1)
                    {
                        Write-Output ("{0}" -f $cmd.CommandText)
                    }
                    $cmd.ExecuteNonQuery() # 
                }
                Catch {
                    Write-Warning "$_" # Report SQL Errors 
                } 
            }  
    
            $conn.Close() # Close SQL Connection
        }
        ########################################################################################################################################

    }
    Catch
    {
        Write-Warning "$_" # Report Errors Get-Service
    }

 
}                 