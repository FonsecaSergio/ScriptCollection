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

	
	
	
	
	USE [SANDBOX]
	GO

	DROP TABLE [dbo].[FirewallRules]
	GO

	SET ANSI_NULLS ON
	GO

	SET QUOTED_IDENTIFIER ON
	GO

	SET ANSI_PADDING ON
	GO

	CREATE TABLE [dbo].[FirewallRules](
		[Date] [datetime2](7) NULL CONSTRAINT [DF_FirewallRules_Date]  DEFAULT (sysdatetime()),
		[SERVER] [varchar](255) NULL,
		[FirewallEnabled] [bit] NULL,
		[RuleName] [varchar](500) NULL,
		[Enabled] [varchar](5) NULL,
		[Direction] [varchar](100) NULL,
		[Action] [varchar](100) NULL,
		[Protocol] [varchar](100) NULL,
		[LocalPort] [varchar](6) NULL,
		[RemotePort] [varchar](6) NULL
	) ON [PRIMARY]

	GO

	SET ANSI_PADDING OFF
	GO


#>

Clear-Host


########################################################################################################################################
#CONFIG
########################################################################################################################################
$LOG_SERVER_connectionString  = "Server=LOCALHOST;Database=SANDBOX;Integrated Security=SSPI"
$LIST_SERVER_connectionString = "Server=LOCALHOST;Database=SANDBOX;Integrated Security=SSPI"

$LIST_SERVER_Command = "SELECT SERVER = 'LOCALHOST' UNION ALL SELECT SERVER = 'SEFONSECNOTE' UNION ALL SELECT SERVER = '127.0.0.1'"

$DEBUG_PrintToScreen = 1;
$DEBUG_SaveToSQL = 0;
$DEBUG_REMOTO = 0 #(0) - Executa na maquina local / (1) Executa nas maquinas listadas em $LIST_SERVER_Command 


$Ports_to_Test = 1433, 1434, 80, 666
$Apps_to_Test = "*DTC*", "*spoolsv.exe*", "*SQL*" #LIKE *

########################################################################################################################################
#GET SERVER LIST
########################################################################################################################################
if ($DEBUG_REMOTO -eq 1)
{

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

} 
else
{
    $ServersList = {LOCALHOST}
}





########################################################################################################################################
#LOOP SERVIDORES
########################################################################################################################################
foreach($serverAux in $ServersList) ##LISTA DINAMICA
{ 
    $server = $serverAux[0]

    Write-Output ("Server: {0}" -f $server);


    ########################################################################################################################################
    #Verifica se o profile DOMAIN esta ativo
    ########################################################################################################################################
    Try
    {
        if ($DEBUG_REMOTO -eq 1)
        {
            $DomainFirewallEnabled = Get-NetFirewallProfile -Name Domain -CimSession $Server | select Enabled
        } 
        else
        {
            $DomainFirewallEnabled = Get-NetFirewallProfile -Name Domain | select Enabled
        }


        IF ($DomainFirewallEnabled.Enabled.value__ -eq $false)
        {
            Write-Output("Domain Firewall Disabled")

            ########################################################################################################################################
            #WRITE TO DB
            ########################################################################################################################################
            if ($DEBUG_SaveToSQL -eq 1)
            {
                $conn = New-Object System.Data.SqlClient.SqlConnection($LOG_SERVER_connectionString) # SQL Connection String
                $conn.Open() # Open SQL Connection 
    
                $cmd = $conn.CreateCommand() # Set up SQLCommand object
                
                $cmd.CommandText ="INSERT INTO [dbo].[FirewallRules] ([SERVER],[FirewallEnabled]) 
                                    VALUES ('$Server', 0)" # Configure TSQL
                Try {
                    if ($DEBUG_PrintToScreen -eq 1)
                    {
                        Write-Output ("{0}" -f $cmd.CommandText)
                    }
                    $LIXO = $cmd.ExecuteNonQuery()  
                }
                Catch {
                    Write-Warning "$_" # Report SQL Errors 
                } 
    
                $conn.Close() # Close SQL Connection
            }
            ########################################################################################################################################


        }
        else
        {
            Write-Output("Domain Firewall Enabled")

            if ($DEBUG_REMOTO -eq 1)
            {
                $FirewallRules = Get-NetFirewallRule -All -CimSession $Server | select
            } 
            else
            {
                $FirewallRules = Get-NetFirewallRule -All | select
            }


            ########################################################################################################################################
            #LOOP REGRAS
            ########################################################################################################################################
            foreach ($Rule in $FirewallRules)
            {
                #Write-Output($Rule)
                #Write-Output("RULE::" + $Rule.Name)
            
                
                ########################################################################################################################################
                #LOOP PORTAS
                ########################################################################################################################################
                if ($DEBUG_REMOTO -eq 1)
                {
                    $FirewallRules_Ports = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $Rule -CimSession $Server
                } 
                else
                {
                    $FirewallRules_Ports = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $Rule
                }


                foreach($port in $FirewallRules_Ports)
                {
                    IF ($port.LocalPort -in $Ports_to_Test)
                    {

                        if ($DEBUG_PrintToScreen -eq 1)
                        {
                            Write-Output("------------------------------------------------------------------------------------------------------------")
                            Write-Output("Rule :: DisplayName: {0} / Enabled: {1} / Direction: {2} / Action: {3}" -f $Rule.DisplayName, $Rule.Enabled, $Rule.Direction, $Rule.Action)
                            Write-Output("Port :: Protocol: {0} / LocalPort: {1} / RemotePort: {2}" -f $port.Protocol, $port.LocalPort, $port.RemotePort)
                        }

                        ########################################################################################################################################
                        #WRITE TO DB
                        ########################################################################################################################################
                        if ($DEBUG_SaveToSQL -eq 1)
                        {
                            $conn = New-Object System.Data.SqlClient.SqlConnection($LOG_SERVER_connectionString) # SQL Connection String
                            $conn.Open() # Open SQL Connection 
    
                            $cmd = $conn.CreateCommand() # Set up SQLCommand object

                            $Command = "INSERT INTO [dbo].[FirewallRules] ([SERVER],[FirewallEnabled],[RuleName],[Enabled],[Direction],[Action],[Protocol],[LocalPort],[RemotePort]) "
                            $Command = $Command + "VALUES ('$Server', 1,'"+ $Rule.DisplayName + "', '" + $Rule.Enabled +"', '" + $Rule.Direction + "', '" + $Rule.Action + "', '" + $port.Protocol + "', '" + $port.LocalPort + "', '" + $port.RemotePort + "')" # Configure TSQL

                            $cmd.CommandText = $Command
                            Try {
                                if ($DEBUG_PrintToScreen -eq 1)
                                {
                                    Write-Output ("{0}" -f $cmd.CommandText)
                                }
                                $LIXO = $cmd.ExecuteNonQuery()  
                            }
                            Catch {
                                Write-Warning "$_" # Report SQL Errors 
                            } 
    
                            $conn.Close() # Close SQL Connection
                        }
                        ########################################################################################################################################


                    }
               }




                ########################################################################################################################################
                #LOOP APLICATIVOS
                ########################################################################################################################################
                if ($DEBUG_REMOTO -eq 1)
                {
                    $FirewallRules_Apps = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $Rule -CimSession $Server
                } 
                else
                {
                    $FirewallRules_Apps = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $Rule
                }

                foreach($app in $FirewallRules_Apps)
                {
                    #Write-Output ($app)

                    foreach ($App_to_Test in $Apps_to_Test)
                    {
                        if ($app.Program -like $App_to_Test)
                        {
                            if ($DEBUG_PrintToScreen -eq 1)
                            {
                                Write-Output("------------------------------------------------------------------------------------------------------------")
                                Write-Output("Rule :: DisplayName: {0} / Enabled: {1} / Direction: {2} / Action: {3}" -f $Rule.DisplayName, $Rule.Enabled, $Rule.Direction, $Rule.Action)
                                Write-Output("App Name: {0}" -f $app.Program);
                            }
                        }
                    }
                }






            }
        }

    }

    
    Catch {
        Write-Warning "$_" # Report Errors 
    }

}

Write-Output ("################")
Write-Output ("# FIM PROCESSO #")
Write-Output ("################")
            