 #Requires -Version 5

<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2022-06-30

.SYNOPSIS   
    TEST SYNAPSE ENDPOINTS AND PORTS NEEDED

    - Check all Windows HOST File entries
    - Check DNS configuration
    - Check name resolution for all possible endpoints used by Synapse and compare it with public DNS
    - Check if ports needed are open (1433 / 443)
    - Check Internet and Self Hosted IR proxy that change name resolution from local machine to proxy
    
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
    - 2022-06-25 - 1443 port added back to document (we use this port in certain regions) - https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network
                 - ADDED AAD login endpoints (login.windows.net / login.microsoftonline.com / secure.aadcdn.microsoftonline-p.com). took from https://github.com/Azure/SQL-Connectivity-Checker/blob/master/AzureSQLConnectivityChecker.ps1
                 - Change code to Classes
    - 2022-06-30 - Fixed error "The output stream for this command is already redirected"
					Error caused by write output + char > causing redirect of output

#KNOW ISSUES / TO DO
    - Need to improve / test on linux / Mac machines
#> 

if($PSVersionTable.Platform)


using namespace System.Net

param (
    [string]$WorkspaceName = "SERVERNAME"
)

Clear-Host

####################################################
#region OTHER PARAMETERS / CONSTANTS

[string]$DNSPublic = "8.8.8.8" #GoogleDNS
$TestPortConnectionTimeoutMs = 1000

#endregion OTHER PARAMETERS / CONSTANTS

####################################################
#region Class

#----------------------------------------------------------------------------------------------------------------------
Class Port
{
    [string]$Port
    [string]$Result = "NOT TESTED"

    Port () {}
    Port ([string]$PortInput) {$this.Port = $PortInput}
}

#----------------------------------------------------------------------------------------------------------------------
Class Endpoint
{
    [String]$Name
    [String]$IP
    [String]$CNAME
    [Port[]]$PortsNeeded

    Endpoint () {}
    Endpoint ([string]$Name, [Port[]]$PortsNeeded) 
    {
        $this.Name = $Name
        $this.PortsNeeded = $PortsNeeded
    }

    [void] Resolve_DnsName_CXDNS ()
    {
        try 
        {
            Write-Host " -Trying to resolve DNS for $($this.Name) from Customer DNS" -ForegroundColor DarkGray
            $DNSResults = (Resolve-DnsName -Name $this.Name -DnsOnly -Type A -QuickTimeout -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            $this.IP = $DNSResults[0].IPAddress
            $this.CNAME = $DNSResults[0].Name

        }
        catch 
        {
            Write-Host " -Error at Resolve_DnsName_CXDNS: $($_.Exception.Message)" -ForegroundColor REd
        }
    }

    [void] Resolve_DnsName_PublicDNS ([string]$DNSServer)
    {
        try 
        {
            Write-Host " -Trying to resolve DNS for $($this.Name) with DNS Server $($DNSServer)" -ForegroundColor DarkGray
            $DNSResults = (Resolve-DnsName -Name $this.Name -DnsOnly -Type A -QuickTimeout -Server $DNSServer  -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            $this.IP = $DNSResults[0].IPAddress
            $this.CNAME = $DNSResults[0].Name
        }
        catch 
        {
            Write-Host " -Error at Resolve_DnsName_PublicDNS: $($_.Exception.Message)" -ForegroundColor REd
        }
    }

}

#----------------------------------------------------------------------------------------------------------------------
Class EndpointTest
{
    [Endpoint]$EndpointCX
    [Endpoint]$EndPointPublic

    EndpointTest () {}
    EndpointTest ([Endpoint]$EndpointToBeTested) 
    {
        $this.EndpointCX = $EndpointToBeTested
        $this.EndPointPublic = $EndpointToBeTested
    }

    #https://copdips.com/2019/09/fast-tcp-port-check-in-powershell.html
    [void] Test_Ports ([Int]$Timeout = 1000)
    {
        foreach ($Port in $this.EndpointCX.PortsNeeded)
        {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient

                if($this.EndpointCX.IP -ne $null) 
                {
                    Write-Host " -Testing Port $($this.EndpointCX.Name) / IP($($this.EndpointCX.IP)):PORT($($Port.Port))" -ForegroundColor DarkGray

                    $portOpened = $false

                    $portOpened = $tcpClient.ConnectAsync($this.EndpointCX.IP, $Port.Port).Wait($Timeout)

                    if($portOpened -eq $true) {
                        $Port.Result = "CONNECTED"
                    }
                    else{
                        $Port.Result = "CLOSED"
                    }                   
                } 
                else 
                {
                    Write-Host " -NOT Testing Port / IP NOT VALID - $($this.EndpointCX.Name) / IP($($this.EndpointCX.IP)):PORT($($Port.Port))" -ForegroundColor Yellow
                    $Port.Result = "NOT VALID IP - NAME NOT RESOLVED"
                }

                $tcpClient.Close()
            }
            catch {
                $Port.Result = "CLOSED"
                if ($_.Exception.InnerException.InnerException -ne $null)
                {
                    if ($_.Exception.InnerException.InnerException.ErrorCode -eq 11001) { #11001 No such host is known                        
                        Write-Host " -Error at Test-Port: ($($this.EndpointCX.Name) / $($this.EndpointCX.IP) : $($Port.Port)) - $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor REd
                    }
                }
                else {
                    Write-Host " -Error at Test-Port: $($_.Exception.Message)" -ForegroundColor REd
                }                
            }          
        }
    }

    [void] PrintTest_Endpoint ($HostsFileEntries, [string]$DNSPublic) 
    {
        Write-Host "   ----------------------------------------------------------------------------"
        Write-Host "   - DNS for ($($this.EndpointCX.Name))"
        Write-Host "      - CX DNS:($($this.EndpointCX.IP)) / NAME:($($this.EndpointCX.CNAME))"

        $HostsFileEntry = $null
        $_HaveHostsFileEntry = $false

        # CHECK ENTRY ON HOSTS

        if ($HostsFileEntries.Count -gt 0) {
            foreach ($HostsFileEntry in $HostsFileEntries)
            {
                if ($HostsFileEntry.HOST -eq $this.EndpointCX.Name) {
                    $_HaveHostsFileEntry = $true
                    Write-Host "      - CX HOST FILE:($($HostsFileEntry.IP)) / NAME:($($HostsFileEntry.HOST))" -ForegroundColor Red
                    break
                }    
            }     
        }

        Write-Host "      - Public DNS:($($this.EndPointPublic.IP)) / NAME:($($this.EndPointPublic.CNAME))"              

        if ($this.EndPointPublic.IP -eq $null) 
        { Write-Host "      - PUBLIC NAME RESOLUTION DIDN'T WORK - DOES NOT MEAN A PROBLEM - Just could not reach Public DNS ($($DNSPublic)) to compare" -ForegroundColor Yellow }

        if ($_HaveHostsFileEntry)
        {# HAVE HOST FILE ENTRY           
            if ($HostsFileEntry.IP -eq $this.EndPointPublic.IP) 
            { Write-Host "      - VM HOST FILE ENTRY AND PUBLIC DNS ARE SAME" -ForegroundColor Green }
            else { Write-Host "      - VM HOST FILE ENTRY AND PUBLIC DNS ARE NOT SAME" -ForegroundColor Yellow }

            Write-Host "      - CHECK HOSTS FILE ENTRY TO CHECK IF USING PRIVATE LINK or PUBLIC ENDPOINT" -ForegroundColor Yellow
        }
        else
        {# DOES NOT HAVE HOST FILE ENTRY
            if ($this.EndpointCX.IP -eq $null) 
            { Write-Host "      - CX NAME RESOLUTION DIDN'T WORK" -ForegroundColor Red }
            else {
                if ($this.EndpointCX.IP -eq $this.EndPointPublic.IP) 
                { Write-Host "      - INFO: CX DNS SERVER AND PUBLIC DNS ARE SAME. That is not an issue. Just a notice that they are currently EQUAL" -ForegroundColor Green }
                else { Write-Host "      - INFO: CX DNS SERVER AND PUBLIC DNS ARE NOT SAME. That is not an issue. Just a notice that they are currently DIFFERENT" -ForegroundColor Yellow }
    
                if ($this.EndpointCX.Name -like "*.cloudapp.*" -or $this.EndpointCX.Name -like "*.control.*") 
                { Write-Host "      - CX USING PUBLIC ENDPOINT" -ForegroundColor Cyan }
                elseif ($this.EndpointCX.Name -like "*.privatelink.*") 
                { Write-Host "      - CX USING PRIVATE ENDPOINT" -ForegroundColor Yellow }                   
            } 
        }
    }

    [void] PrintTest_Ports ()
    {
        Write-host "    - TESTS FOR ENDPOINT - $($this.EndpointCX.Name) - IP ($($this.EndpointCX.IP))"

        foreach ($Port in $this.EndpointCX.PortsNeeded)
        {
            if($Port.Result -eq "CONNECTED")
            { Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Green}
            elseif($Port.Result -eq "CLOSED" -or $Port.Result -contains "NOT VALID IP")
            { Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Red}
            else
            { Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Yellow}
        }       
    }
}
#----------------------------------------------------------------------------------------------------------------------

#endregion Class

####################################################
#region Endpoints

$EndpointTestList = New-Object Collections.Generic.List[EndpointTest]

$SynapseSQLEndpoint = [Endpoint]::new(
    "$($WorkspaceName).sql.azuresynapse.net", 
    @([Port]::new(1433), [Port]::new(1443), [Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($SynapseSQLEndpoint))

$SynapseServelessEndpoint = [Endpoint]::new(
    "$($WorkspaceName)-ondemand.sql.azuresynapse.net",
    @([Port]::new(1433), [Port]::new(1443), [Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($SynapseServelessEndpoint))

$SQLDatabaseEndpoint = [Endpoint]::new(
    "$($WorkspaceName).database.windows.net",
    @([Port]::new(1433), [Port]::new(1443), [Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($SQLDatabaseEndpoint))

$SynapseDevEndpoint = [Endpoint]::new(
    "$($WorkspaceName).dev.azuresynapse.net",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($SynapseDevEndpoint))

$SynapseStudioEndpoint = [Endpoint]::new(
    "web.azuresynapse.net",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($SynapseStudioEndpoint))

$AzureManagementEndpoint = [Endpoint]::new(
    "management.azure.com",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($AzureManagementEndpoint))

$AADEndpoint1 = [Endpoint]::new(
    "login.windows.net",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($AADEndpoint1))

$AADEndpoint2 = [Endpoint]::new(
    "login.microsoftonline.com",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($AADEndpoint2))

$AADEndpoint3 = [Endpoint]::new(
    "secure.aadcdn.microsoftonline-p.com",
    @([Port]::new(443))
)
$EndpointTestList.Add([EndpointTest]::new($AADEndpoint3))

#endregion Endpoints

####################################################


#----------------------------------------------------------------------------------------------------------------------

#region RESERVED FOR FUTURE USE
<#
#http://www.padisetty.com/2014/05/powershell-bit-manipulation-and-network.html
#checkSubnet "20.36.105.32/29" "20.36.104.6" #FALSE
#checkSubnet "20.36.105.0/24" "20.36.105.10" #TRUE

function checkSubnet ([string]$cidr, [string]$ip) {
    $network, [int]$subnetlen = $cidr.Split('/')
    $a = [uint32[]]$network.split('.')
    [uint32] $unetwork = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    $mask = (-bnot [uint32]0) -shl (32 - $subnetlen)

    $a = [uint32[]]$ip.split('.')
    [uint32] $uip = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    $unetwork -eq ($mask -band $uip)
}
#>

#endregion RESERVED FOR FUTURE USE

#----------------------------------------------------------------------------------------------------------------------


####################################################
# COLLECTING DATA

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COLLECTING DATA" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################
#region GET HOSTS FILE ENTRIES

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

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  GET HOSTS FILE ENTRIES"
$HostsFileEntries = @(Get-HostsFilesEntries)

#endregion GET HOSTS FILE ENTRIES

####################################################
#region GET DNS SERVERS

function Get-DnsCxServerAddresses {   
    $AddressFamilyIPV4 = 2 #AddressFamily -eq 2 = "IPv4"

    $DNSServers = Get-DnsClientServerAddress | `
        Where-Object {$_.AddressFamily -eq $AddressFamilyIPV4 } | ` 
        Select-Object –ExpandProperty ServerAddresses -Unique

    return $DNSServers
}

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  GET DNS SERVERS"
$DnsCxServerAddresses = @(Get-DnsCxServerAddresses)

Get-DnsClientServerAddress | ? serveraddresses

#endregion GET DNS SERVERS

####################################################
#region  Resolve using current DNS

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  TEST NAME RESOLUTION"

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.EndpointCX.Resolve_DnsName_CXDNS()
    $EndpointTest.EndPointPublic.Resolve_DnsName_PublicDNS($DNSPublic)
}

#endregion  Resolve using current DNS

####################################################
#region Test Ports

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  TEST PORTS NEEDED"

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.Test_Ports($TestPortConnectionTimeoutMs)
}

#endregion Test Ports

####################################################
# RESULTS
####################################################

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "RESULTS " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################
#region RESULTS - HostsFile
$HostsFile    = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  HOSTS FILE [$($HostsFile)]"

if ($HostsFileEntries.Count -gt 0) {
    foreach ($HostsFileEntry in $HostsFileEntries)
    {
        if (
            $HostsFileEntry.HOST.Contains($WorkspaceName) -or `
            $HostsFileEntry.HOST.Contains($SynapseStudioEndpoint.Name) -or `
            $HostsFileEntry.HOST.Contains($AzureManagementEndpoint.Name) -or `
            $HostsFileEntry.HOST.Contains($AADEndpoint1.Name) -or `
            $HostsFileEntry.HOST.Contains($AADEndpoint2.Name) -or `
            $HostsFileEntry.HOST.Contains($AADEndpoint3.Name)`
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

#endregion RESULTS - HostsFile

#####################################################################################
#region RESULTS - DNS SERVERS

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
#endregion RESULTS - DNS SERVERS

#####################################################################################
#region RESULTS - PROXY SETTINGS
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
Write-Host "  SHIR Proxy Settings" 

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
#endregion RESULTS - PROXY SETTINGS

#####################################################################################
#region RESULTS - NAME RESOLUTIONS

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  NAME RESOLUTION "

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.PrintTest_Endpoint($HostsFileEntries, $DNSPublic)
}

#endregion RESULTS - NAME RESOLUTIONS


#####################################################################################
#region RESULTS - PORTS OPEN

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  PORTS OPEN (Used CX DNS or Host File entry listed above)"

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.PrintTest_Ports()
}




#endregion RESULTS - PORTS OPEN


Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "END OF SCRIPT" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
 
