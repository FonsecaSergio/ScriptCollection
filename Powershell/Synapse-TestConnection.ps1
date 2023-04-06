<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-03-08

.SYNOPSIS   
    TEST SYNAPSE ENDPOINTS AND PORTS NEEDED

        ## Sample execution

        ```
        .\"Synapse-TestConnection.ps1" WORKSPACENAME
        ```

        OR just copy and paste code to Powershell ISE and change parameter before run

        ```
        [string]$WorkspaceName = "xpto"
        ```

    ----------------------------------------------------------------------------------------------
    - Check all Windows HOST File entries
    - Check DNS configuration
    - Check name resolution for all possible endpoints used by Synapse and compare it with public DNS
    - Check if ports needed are open (1433 / 443 / 1443)
    - Check Internet and Self Hosted IR proxy that change name resolution from local machine to proxy
    ----------------------------------------------------------------------------------------------
    
    This script does not really try to connect to endpoint, just check the ports. For full test you can use
        https://docs.microsoft.com/en-us/azure/synapse-analytics/troubleshoot/troubleshoot-synapse-studio-powershell

    For SQL connectivity test use
        https://github.com/Azure/SQL-Connectivity-Checker/

    Script available at
     - https://github.com/Azure-Samples/Synapse/blob/main/PowerShell/Synapse-TestConnection.ps1
     - Last dev version from
        https://github.com/FonsecaSergio/ScriptCollection/blob/master/Powershell/Synapse-TestConnection.ps1


.PARAMETER WorkspaceName

.DESCRIPTION
#UPDATES
    - 2021-11-04 - Name resolution now also looks to host files to check if HOST file entry match Public DNS entry
    - 2022-01-21 - Shows note when open dns / cx dns name resultion fail
                 - Fix for when name resultion fails "No such host is known". Sample workspaces conected to former SQL DW does not resolve SERVERNAME.sql.azuresynapse.net
    - 2022-04-14 - 1443 port NOT needed anymore. Portal using only 443 now - documented in march https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network
                 - Improve message cx and public dns ips are not same
                 - Add method to get browser proxy and SHIR proxy settings
    - 2022-06-30 - Fixed error "The output stream for this command is already redirected"
				   Error caused by write output + char > causing redirect of output
    - 2022-10-31 - 1433 added again. Still needed in some regions for Synapse Studio
                   - https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network
                   - https://github.com/MicrosoftDocs/azure-docs/issues/69090
                 - Added Import-Module DnsClient just in case is not there by default - BUGFIX
                 - When name resolution fails. Test port shows CLOSED
                 - Check if machine is windows before executing. Not tested on Linux or Mac
    - 2023-03-08 - Test AAD Login endpoints ("login.windows.net" / "login.microsoftonline.com" / "secure.aadcdn.microsoftonline-p.com")
#KNOW ISSUES / TO DO

#> 

using namespace System.Net

param (
    [string]$WorkspaceName = "fonsecanetsynapse"
)

$VERSION = "2023-03-08"

Clear-Host

Import-Module DnsClient

Write-Host ("Current version: " + $VERSION)

####################################################
#CHECK IF MACHINE IS WINDOWS
[String]$OS = [System.Environment]::OSVersion.Platform
Write-Host "SO: $($OS)"

if (-not(($OS.Contains("Win"))))
{
    Write-Error "Only can be used on Windows Machines"
    Break
}
    

####################################################
#OTHER PARAMETERS
$DNSPublic = "8.8.8.8" #GoogleDNS
$TestPortConnectionTimeoutMs = 1000

####################################################
#ENDPOINTS
$SynapseSQLEndpoint = @{ NAME = "$($WorkspaceName).sql.azuresynapse.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$SynapseServelessEndpoint = @{ NAME = "$($WorkspaceName)-ondemand.sql.azuresynapse.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$SynapseDevEndpoint = @{ NAME = "$($WorkspaceName).dev.azuresynapse.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$SQLDatabaseEndpoint = @{ NAME = "$($WorkspaceName).database.windows.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$SynapseStudioEndpoint = @{ NAME = "web.azuresynapse.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$AzureManagementEndpoint = @{ NAME = "management.azure.com"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$AzureADLoginEndpoint1 = @{ NAME = "login.windows.net"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$AzureADLoginEndpoint2 = @{ NAME = "login.microsoftonline.com"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};

$AzureADLoginEndpoint3 = @{ NAME = "secure.aadcdn.microsoftonline-p.com"
ENDPOINT_CX = $null
ENDPOINT_PUBLICDNS = $null
};


####################################################

function Resolve-DnsName_Internal {
    param(
        [Parameter(Position = 0)] $Name,
        [string] $Server
    );
    process {
        try {
            if ($Server -ne $null -and $Server -ne "") {
                Write-Host " -Trying to resolve DNS for $($Name) with DNS Server $($Server)" -ForegroundColor DarkGray
                $DNSResults = (Resolve-DnsName -Name $Name -DnsOnly -Type A -QuickTimeout -Server $Server  -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            }
            else {
                Write-Host " -Trying to resolve DNS for $($Name) from Customer DNS" -ForegroundColor DarkGray
                $DNSResults = (Resolve-DnsName -Name $Name -DnsOnly -Type A -QuickTimeout -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            }

            return $DNSResults

            #return @{ IPAddress = [System.Net.DNS]::GetHostAddresses($Name).IPAddressToString };
        }
        catch {
            Write-Host " -Error at Resolve-DnsName_Internal: $($_.Exception.Message)" -ForegroundColor REd
        }
    }
}

#----------------------------------------------------------------------------------------------------------------------
#https://copdips.com/2019/09/fast-tcp-port-check-in-powershell.html
function Test-Port {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, HelpMessage = 'Could be suffixed by :Port')]
        [String[]]$ComputerName,

        [Parameter(HelpMessage = 'Will be ignored if the port is given in the param ComputerName')]
        [Int]$Port = 1433,

        [Parameter(HelpMessage = 'Timeout in millisecond. Increase the value if you want to test Internet resources.')]
        [Int]$Timeout = 1000
    )

    begin {
        $result = [System.Collections.ArrayList]::new()
    }

    process {
        foreach ($originalComputerName in $ComputerName) {
            $remoteInfo = $originalComputerName.Split(":")
            if ($remoteInfo.count -eq 1) {
                # In case $ComputerName in the form of 'host'
                $remoteHostname = $originalComputerName
                $remotePort = $Port
            } elseif ($remoteInfo.count -eq 2) {
                # In case $ComputerName in the form of 'host:port',
                # we often get host and port to check in this form.
                $remoteHostname = $remoteInfo[0]
                $remotePort = $remoteInfo[1]
            } else {
                $msg = "Got unknown format for the parameter ComputerName: " `
                    + "[$originalComputerName]. " `
                    + "The allowed formats is [hostname] or [hostname:port]."
                Write-Error $msg
                return
            }

            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $portOpened = $false
            try {
                $portOpened = $tcpClient.ConnectAsync($remoteHostname, $remotePort).Wait($Timeout)    
            }
            catch {
                if ($_.Exception.InnerException.InnerException -ne $null)
                {
                    if ($_.Exception.InnerException.InnerException.ErrorCode -eq 11001) { #11001 No such host is known                        
                        Write-Host " -Error at Test-Port: ($($remoteHostname):$($remotePort)) - $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor REd
                    }
                }
                else {
                    Write-Host " -Error at Test-Port: $($_.Exception.Message)" -ForegroundColor REd
                }                
            }           

            $null = $result.Add([PSCustomObject]@{
                RemoteHostname       = $remoteHostname
                RemotePort           = $remotePort
                PortOpened           = $portOpened
                TimeoutInMillisecond = $Timeout
                SourceHostname       = $env:COMPUTERNAME
                OriginalComputerName = $originalComputerName
                })
        }
    }

    end {
        return $result
    }
}

#----------------------------------------------------------------------------------------------------------------------
function Get-HostsFilesEntries {   
    $Pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'
    $File    = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"

    $result = [System.Collections.ArrayList]::new()

    (Get-Content -Path $File)  | ForEach-Object {
        If ($_ -match $Pattern) {
            $Entries += "$($Matches.IP),$($Matches.Host)"

            $null = $result.Add([PSCustomObject]@{
                IP   = $Matches.IP
                HOST = $Matches.Host
                })
        }
    }

    return @( $result )
}

#----------------------------------------------------------------------------------------------------------------------
function Get-DnsCxServerAddresses {   
    $AddressFamilyIPV4 = 2 #AddressFamily -eq 2 = "IPv4"

    $DNSServers = Get-DnsClientServerAddress | `
        Where-Object {$_.AddressFamily -eq $AddressFamilyIPV4 } | ` 
        Select-Object -ExpandProperty ServerAddresses -Unique

    return $DNSServers
}

#----------------------------------------------------------------------------------------------------------------------


####################################################
# COLLECTING DATA

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COLLECTING DATA" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################
# GET HOSTS FILE ENTRIES
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  GET HOSTS FILE ENTRIES"
$HostsFileEntries = @(Get-HostsFilesEntries)



####################################################
# GET DNS SERVERS
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  GET DNS SERVERS"
$DnsCxServerAddresses = @(Get-DnsCxServerAddresses)

Get-DnsClientServerAddress | ? serveraddresses


####################################################
# Resolve using current DNS
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  TEST NAME RESOLUTION - CX DNS"
$SynapseSQLEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $SynapseSQLEndpoint.NAME
$SynapseServelessEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $SynapseServelessEndpoint.NAME
$SynapseDevEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $SynapseDevEndpoint.NAME
$SQLDatabaseEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $SQLDatabaseEndpoint.NAME
$SynapseStudioEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $SynapseStudioEndpoint.NAME
$AzureManagementEndpoint.ENDPOINT_CX = Resolve-DnsName_Internal $AzureManagementEndpoint.NAME
$AzureADLoginEndpoint1.ENDPOINT_CX = Resolve-DnsName_Internal $AzureADLoginEndpoint1.NAME
$AzureADLoginEndpoint2.ENDPOINT_CX = Resolve-DnsName_Internal $AzureADLoginEndpoint2.NAME
$AzureADLoginEndpoint3.ENDPOINT_CX = Resolve-DnsName_Internal $AzureADLoginEndpoint3.NAME

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  TEST NAME RESOLUTION - PUBLIC DNS TEST - NOT A PROBLEM IF FAIL"
$SynapseSQLEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $SynapseSQLEndpoint.NAME -Server $DNSPublic
$SynapseServelessEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $SynapseServelessEndpoint.NAME -Server $DNSPublic
$SynapseDevEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $SynapseDevEndpoint.NAME -Server $DNSPublic
$SQLDatabaseEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $SQLDatabaseEndpoint.NAME -Server $DNSPublic
$SynapseStudioEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $SynapseStudioEndpoint.NAME -Server $DNSPublic
$AzureManagementEndpoint.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $AzureManagementEndpoint.NAME -Server $DNSPublic
$AzureADLoginEndpoint1.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $AzureADLoginEndpoint1.NAME -Server $DNSPublic
$AzureADLoginEndpoint2.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $AzureADLoginEndpoint2.NAME -Server $DNSPublic
$AzureADLoginEndpoint3.ENDPOINT_PUBLICDNS = Resolve-DnsName_Internal $AzureADLoginEndpoint3.NAME -Server $DNSPublic

####################################################
# Test Ports
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  TEST PORTS NEEDED"
#1433
$Results1433 = $SynapseSQLEndpoint.NAME, $SynapseServelessEndpoint.NAME, $SQLDatabaseEndpoint.NAME | Test-Port -Port 1433 -Timeout $TestPortConnectionTimeoutMs
#443
$Results443 = $SynapseSQLEndpoint.NAME, $SynapseServelessEndpoint.NAME, $SynapseDevEndpoint.NAME, $SynapseStudioEndpoint.NAME, $AzureManagementEndpoint.NAME, $AzureADLoginEndpoint1.NAME, $AzureADLoginEndpoint2.NAME, $AzureADLoginEndpoint3.NAME | Test-Port -Port 443 -Timeout $TestPortConnectionTimeoutMs
#1443
$Results1443 = $SynapseSQLEndpoint.NAME, $SynapseServelessEndpoint.NAME, $SQLDatabaseEndpoint.NAME | Test-Port -Port 1443 -Timeout $TestPortConnectionTimeoutMs

Write-Host "  ----------------------------------------------------------------------------"



####################################################
# RESULTS
####################################################



Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "RESULTS " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

$File    = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  HOSTS FILE [$($File)]"

if ($HostsFileEntries.Count -gt 0) {
    foreach ($HostsFileEntry in $HostsFileEntries)
    {
        if (
            $HostsFileEntry.HOST.Contains($WorkspaceName) -or `
            $HostsFileEntry.HOST.Contains($SynapseStudioEndpoint.NAME) -or `
            $HostsFileEntry.HOST.Contains($AzureManagementEndpoint.NAME)`
        ) {
            Write-Host "   - IP [$($HostsFileEntry.IP)] / NAME [$($HostsFileEntry.HOST)]" -ForegroundColor Red    
        }
        else {
            Write-Host "   - IP [$($HostsFileEntry.IP)] / NAME [$($HostsFileEntry.HOST)]"
        }    
    }     
}
else {
    Write-Host "   - NO RELATED ENTRY" -ForegroundColor Green
}




#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  DNS SERVERS"
foreach ($DnsCxServerAddress in $DnsCxServerAddresses)
{
    #https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
    if ($DnsCxServerAddress -eq "168.63.129.16") {
        Write-Host "   - DNS [$($DnsCxServerAddress)] AZURE DNS" -ForegroundColor Cyan
    }
    else {
        Write-Host "   - DNS [$($DnsCxServerAddress)] CUSTOM" -ForegroundColor Cyan
    } 
       
}

#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  Computer Internet Settings - LOOK FOR PROXY SETTINGS"

$IESettings = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

if ($IESettings.ProxyEnable -eq 0) {
    Write-Host "   - NO INTERNET PROXY ON SERVER / BROWSER"
}
else {
    Write-Host "   - PROXY ENABLED ON SERVER $($IESettings.ProxyServer)" -ForegroundColor Red
    Write-Host "   - PROXY EXCEPTIONS $($IESettings.ProxyOverride)" -ForegroundColor Red
}

#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  SHIR Proxy Settings - Will fail if this is not SHIR machine"

try {
    $ProxyEvents = Get-EventLog `
        -LogName "Integration Runtime" `
        -InstanceId "26" `
        -Message "Http Proxy is set to*" `
        -Newest 15

    $ProxyEvents | Select TimeGenerated, Message
}
catch{
    Write-Host "   - FAILED - NOT A PROBLEM IF NOT Self Hosted IR Machine" 
    Write-Host "     - $_.Exception"
}

Write-Host "  ----------------------------------------------------------------------------"

#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  NAME RESOLUTION "

<#
.SYNOPSIS
Just internal function to simplify tests and notes
#>
function Test-Endpoint {
    param(
        [Parameter(Position = 0)] $Endpoint
    );
    process {        
        Write-Host "   ----------------------------------------------------------------------------"
        Write-Host "   - DNS for ($($Endpoint.NAME))"
        Write-Host "      - INFO:: CX DNS:($($Endpoint.ENDPOINT_CX.IPAddress)) / NAME:($($Endpoint.ENDPOINT_CX.Name))"

        $_HaveHostsFileEntry = $false

        # CHECK ENTRY ON HOSTS

        if ($HostsFileEntries.Count -gt 0) {
            foreach ($HostsFileEntry in $HostsFileEntries)
            {
                if ($HostsFileEntry.HOST -eq $Endpoint.NAME) {
                    $_HaveHostsFileEntry = $true
                    Write-Host "      - INFO:: CX HOST FILE:($($HostsFileEntry.IP)) / NAME:($($HostsFileEntry.HOST))" -ForegroundColor Red
                    break
                }    
            }     
        }
        Write-Host "      - INFO:: Public DNS:($($Endpoint.ENDPOINT_PUBLICDNS.IPAddress)) / NAME:($($Endpoint.ENDPOINT_PUBLICDNS.Name)) - To be used as comparison"

        

        if ($Endpoint.ENDPOINT_PUBLICDNS.IPAddress -eq $null) 
        { Write-Host "      - INFO:: PUBLIC NAME RESOLUTION DIDN'T WORK - DOES NOT MEAN A PROBLEM - Just could not reach Public DNS ($($DNSPublic)) to compare" -ForegroundColor Yellow }

        if ($_HaveHostsFileEntry)
        {# HAVE HOST FILE ENTRY
            
            if ($HostsFileEntry.IP -eq $Endpoint.ENDPOINT_PUBLICDNS.IPAddress) 
            { Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE SAME" -ForegroundColor Green }
            else { Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE NOT SAME" -ForegroundColor Yellow }

            Write-Host "      - INFO:: AS USING HOSTS FILE ENTRY - CHECK IF USING PRIVATE LINK or PUBLIC ENDPOINT, COMPARE WITH PUBLIC GATEWAY IP" -ForegroundColor Yellow
        }
        else
        {# DOES NOT HAVE HOST FILE ENTRY
            if ($Endpoint.ENDPOINT_CX.IPAddress -eq $null) 
            { Write-Host "      - ERROR:: CX NAME RESOLUTION DIDN'T WORK" -ForegroundColor Red }
            else {
                if ($Endpoint.ENDPOINT_CX.IPAddress -eq $Endpoint.ENDPOINT_PUBLICDNS.IPAddress) 
                { Write-Host "      - INFO:: CX DNS SERVER AND PUBLIC DNS ARE SAME. That is not an issue. Just a notice that they are currently EQUAL" -ForegroundColor Green }
                else { Write-Host "      - INFO:: CX DNS SERVER AND PUBLIC DNS ARE NOT SAME. That is not an issue. Just a notice that they are currently DIFFERENT" -ForegroundColor Yellow }
    
                if ($Endpoint.ENDPOINT_CX.Name -like "*.cloudapp.*" -or $Endpoint.ENDPOINT_CX.Name -like "*.control.*") 
                { Write-Host "      - INFO:: CX USING PUBLIC ENDPOINT" -ForegroundColor Cyan }
                elseif ($Endpoint.ENDPOINT_CX.Name -like "*.privatelink.*") 
                { Write-Host "      - INFO:: CX USING PRIVATE ENDPOINT" -ForegroundColor Yellow }                   
            } 
        }
    }
}

Test-Endpoint $SynapseSQLEndpoint
Test-Endpoint $SynapseServelessEndpoint
Test-Endpoint $SynapseDevEndpoint
Test-Endpoint $SQLDatabaseEndpoint
Test-Endpoint $SynapseStudioEndpoint
Test-Endpoint $AzureManagementEndpoint




#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  PORTS OPEN (Used CX DNS or Host File entry listed above)"

<#
.SYNOPSIS
Just internal function to simplify tests and notes
#>
function Test-Ports {
    param(
        [Parameter(Position = 0)] $PortResults
    );
    process {
        foreach ($result in $PortResults)
        {
            if($result.PortOpened -eq $true)
            {Write-host "    - Port $($result.RemotePort) for $($result.RemoteHostname) is OPEN" -ForegroundColor Green }
            else
            {Write-host "    - Port $($result.RemotePort) for $($result.RemoteHostname) is CLOSED" -ForegroundColor Red } 
        }
    }
}

Write-Host "   - 1433 --------------------------------------------------------------------"
Test-Ports $Results1433
Write-Host "   - 443 ---------------------------------------------------------------------"
Test-Ports $Results443
Write-Host "   - 1443 ---------------------------------------------------------------------"
Test-Ports $Results1443

Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   NOTE on differences for Dedicated pool endpoint"
Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   SYNAPSE use endpoints below:"
Write-Host "    - XXXXXX.sql.azuresynapse.net <--"
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"
Write-Host ""
Write-Host "   FORMER SQL DW + WORKSPACE use endpoints below:"
Write-Host "    - XXXXXX.database.windows.net  <--"
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"

#Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
#Write-Host "END OF SCRIPT" -ForegroundColor Yellow
#Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow