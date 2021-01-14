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