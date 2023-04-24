#Requires -Version 5

<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-04-20

    ## Copyright (c) Microsoft Corporation.
    #Licensed under the MIT license.

    #Azure Synapse Test Connection

    #THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    #FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    #WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.SYNOPSIS   
    TEST SYNAPSE ENDPOINTS AND PORTS NEEDED

    - Check all Windows HOST File entries
    - Check DNS configuration
    - Check name resolution for all possible endpoints used by Synapse and compare it with public DNS
    - Check if ports needed are open (1433 / 1443 / 443)
    - Check Internet and Self Hosted IR proxy that change name resolution from local machine to proxy
    - Make API test calls to apis like management.azure.com / https://WORKSPACE.dev.azuresynapse.net
    - Try to connect to SQL and SQLOndemand APIs using port 1433
    
    REQUIRES
        IF want to run as script
            - Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
        -Import-Module DnsClient
        -Import-Module Az.Accounts -MinimumVersion 2.2.0
            - Install-Module -Name Az -Repository PSGallery -Force
        -Import-Module SQLServer
            - Install-Module -Name SqlServer -Repository PSGallery -Force" -ForegroundColor Yellow


.PARAMETER WorkspaceName

.PARAMETER SubscriptionID

.DESCRIPTION
ADDITIONAL INFO
 - You can also check
   - https://docs.microsoft.com/en-us/azure/synapse-analytics/troubleshoot/troubleshoot-synapse-studio-powershell

 - For full SQL connectivity test use
  - https://github.com/Azure/SQL-Connectivity-Checker/

- Script available at
  - https://github.com/Azure-Samples/Synapse/blob/main/PowerShell/Synapse-TestConnection.ps1
 - Last dev version from
  - https://github.com/FonsecaSergio/ScriptCollection/blob/master/Powershell/Synapse-TestConnection.ps1

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
    - 2022-10-31 - 1433 added again. Still needed in some regions for Synapse Studio
                   - https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network
                   - https://github.com/MicrosoftDocs/azure-docs/issues/69090
                 - Added Import-Module DnsClient just in case is not there by default - BUGFIX
                 - When name resolution fails. Test port shows CLOSED
                 - Check if machine is windows before executing. Not tested on Linux or Mac
    - 2023-03-08 - Test AAD Login endpoints ("login.windows.net" / "login.microsoftonline.com" / "secure.aadcdn.microsoftonline-p.com")
    - 2023-04-20 - Code organization
                 - Make API test calls
                 - Improved Parameter request
                 - Add links and solution to errors


#KNOW ISSUES / TO DO
    - Need to make / test on linux / Mac machines
    - Sign code
    - Print IPV6 DNS on show results
    - Add links and solution to errors
#> 


using namespace System.Net
using namespace Microsoft.ApplicationInsights

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter your Synapse Workspace name.")]
    [ValidateLength(1, 1024)]
    [ValidatePattern("[\w-_]+")]
    [string]
    $WorkspaceName,
    [Parameter(Mandatory = $true, HelpMessage = "Subscription ID")]
    [ValidatePattern("[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")]    
    [string]
    $SubscriptionID
)

Clear-Host

####################################################################################################################################################
#LOG VERSIONS
New-Variable -Name VERSION -Value "2023-04-20" -Option Constant -ErrorAction Ignore

Write-Host ("Current version: " + $VERSION)
Write-Host ("PS version: " + $psVersionTable.PSVersion)
Write-Host ("PS OS version: " + $psVersionTable.OS)
Write-Host ("System.Environment OS version: " + [System.Environment]::OSVersion.Platform)
Write-Host ("WorkspaceName: " + $WorkspaceName)
Write-Host ("SubscriptionID: " + $SubscriptionID)


####################################################################################################################################################
#CHECK IF MACHINE IS WINDOWS
[String]$OS = [System.Environment]::OSVersion.Platform
Write-Host "SO: $($OS)"

if (-not(($OS.Contains("Win"))))
{
    Write-Error "Only can be used on Windows Machines"
    Break
}

####################################################################################################################################################
try {
    Import-Module DnsClient -ErrorAction Stop
}
catch {
    Write-Host "   - ERROR::Import-Module DnsClient"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}


####################################################################################################################################################
#region OTHER PARAMETERS / CONSTANTS

[string]$DNSPublic = "8.8.8.8" #GoogleDNS
[int]$TestPortConnectionTimeoutMs = 2000
[int]$SQLConnectionTimeout = 15
[int]$SQLQueryTimeout = 15

#endregion OTHER PARAMETERS / CONSTANTS


####################################################################################################################################################
#Telemetry

function logEvent {
    param (
        [String]$Message
    )
    try {  
        $TelemetryClient = [Microsoft.ApplicationInsights.TelemetryClient]::new("4d27873c-cae7-4df0-aad0-d66a7b1cf94b")
        $TelemetryClient.TrackTrace($Message)
    }
    catch {
        #Do nothing

        #Write-Host "ERROR ($($_.Exception))"
    }        
}

logEvent("Execution - Version: " + $VERSION)



####################################################################################################################################################
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
    [Port[]]$PortsNeeded
 
    Endpoint () {}
    Endpoint ([string]$Name, [Port[]]$PortsNeeded) 
    {
        $this.Name = $Name
        $this.PortsNeeded = $PortsNeeded
    }
}

#----------------------------------------------------------------------------------------------------------------------
Class EndpointTest
{
    [Endpoint]$Endpoint
    [String]$CXResolvedIP
    [String]$CXResolvedCNAME
    [String]$PublicIP
    [String]$PublicCNAME

    [bool]$isAnyPortClosed = $false

    EndpointTest () {}
    EndpointTest ([Endpoint]$EndpointToBeTested) 
    {
        $this.Endpoint = $EndpointToBeTested
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] Resolve_DnsName_CXDNS ()
    {
        try 
        {
            $DNSResults = (Resolve-DnsName -Name $this.Endpoint.Name -DnsOnly -Type A -QuickTimeout -ErrorAction Stop)
            $this.CXResolvedIP = @($DNSResults.IP4Address)[0]
            $this.CXResolvedCNAME = $DNSResults.NameHost[$DNSResults.NameHost.Count - 1]
        }
        catch 
        {
            Write-Host "   - ERROR:: Trying to resolve DNS for $($this.Endpoint.Name) from Customer DNS" -ForegroundColor DarkGray
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] Resolve_DnsName_PublicDNS ([string]$DNSServer)
    {
        try 
        {
            $DNSResults = (Resolve-DnsName -Name $this.Endpoint.Name -DnsOnly -Type A -QuickTimeout -Server $DNSServer  -ErrorAction Stop)
            $this.PublicIP = @($DNSResults.IP4Address)[0]
            $this.PublicCNAME = $DNSResults.NameHost[$DNSResults.NameHost.Count - 1]
        }
        catch 
        {
            Write-Host "   - ERROR:: Trying to resolve DNS for $($this.Endpoint.Name) with DNS Server $($DNSServer) - NOT AN ISSUE IF FAIL. Used just for comparison" -ForegroundColor DarkGray
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    #https://copdips.com/2019/09/fast-tcp-port-check-in-powershell.html
    [void] Test_Ports ([Int]$Timeout = 2000)
    {
        foreach ($Port in $this.Endpoint.PortsNeeded)
        {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient

                if($this.CXResolvedIP -ne $null) 
                {
                    $portOpened = $false

                    $portOpened = $tcpClient.ConnectAsync($this.CXResolvedIP, $Port.Port).Wait($Timeout)

                    if($portOpened -eq $true) {
                        $Port.Result = "CONNECTED"
                    }
                    else{
                        $Port.Result = "CLOSED"
                    }                   
                } 
                else 
                {                    
                    Write-Host " -INFO:: NOT Testing Port / IP NOT VALID - $($this.Endpoint.Name) / IP($($this.CXResolvedIP)):PORT($($Port.Port))" -ForegroundColor Yellow
                    $Port.Result = "NOT VALID IP - NAME NOT RESOLVED"
                }

                $tcpClient.Close()
            }
            catch {
                $Port.Result = "CLOSED"
                Write-Host " -ERROR:: Testing Port $($this.Endpoint.Name) / IP($($this.CXResolvedIP)):PORT($($Port.Port))" -ForegroundColor DarkGray

                if ($_.Exception.InnerException.InnerException -ne $null)
                {
                    if ($_.Exception.InnerException.InnerException.ErrorCode -eq 11001) { #11001 No such host is known                        
                        Write-Host "  -ERROR:: Test-Port: ($($this.Endpoint.Name) / $($this.CXResolvedIP) : $($Port.Port)) - $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor REd
                    }
                }
                else {
                    Write-Host "  -ERROR:: Test-Port: $($_.Exception.Message)" -ForegroundColor REd
                }                
            }          
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] PrintTest_Endpoint ($HostsFileEntries, [string]$DNSPublic) 
    {
        Write-Host "   ----------------------------------------------------------------------------"
        Write-Host "   - DNS for ($($this.Endpoint.Name))"
        Write-Host "      - CX DNS:($($this.CXResolvedIP)) / NAME:($($this.CXResolvedCNAME))"

        $HostsFileEntry = $null
        $_HaveHostsFileEntry = $false

        # CHECK ENTRY ON HOSTS

        if ($HostsFileEntries.Count -gt 0) {
            foreach ($HostsFileEntry in $HostsFileEntries)
            {
                if ($HostsFileEntry.HOST -eq $this.Endpoint.Name) {
                    $_HaveHostsFileEntry = $true
                    Write-Host "      - CX HOST FILE:($($HostsFileEntry.IP)) / NAME:($($HostsFileEntry.HOST))" -ForegroundColor Red
                    break
                }    
            }     
        }

        Write-Host "      - Public DNS:($($this.PublicIP)) / NAME:($($this.PublicCNAME))"              

        if ($this.PublicIP -eq $null) 
        { Write-Host "      - INFO:: PUBLIC NAME RESOLUTION DIDN'T WORK - DOES NOT MEAN A PROBLEM - Just could not reach Public DNS ($($DNSPublic)) to compare" -ForegroundColor Yellow }

        if ($_HaveHostsFileEntry)
        {# HAVE HOST FILE ENTRY           
            if ($HostsFileEntry.IP -ne $this.PublicIP) 
                { Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE NOT SAME" -ForegroundColor Yellow }

            Write-Host "      - INFO:: ENDPOINT CHANGED ON HOSTS FILE. NEED TO MANUALLY CHECK IF USING PRIVATE LINK or PUBLIC ENDPOINT" -ForegroundColor Yellow
        }
        else
        {# DOES NOT HAVE HOST FILE ENTRY
            if ($this.CXResolvedIP -eq $null) 
            { Write-Host "      - ERROR:: CX NAME RESOLUTION DIDN'T WORK" -ForegroundColor Red }
            else 
            {
                if ($this.CXResolvedIP -eq $this.PublicIP) 
                { Write-Host "      - INFO:: That is not an issue :: CX DNS SERVER AND PUBLIC DNS ARE SAME. Just a notice that they are currently EQUAL" -ForegroundColor Green }
                else { Write-Host "      - INFO:: That is not an issue :: CX DNS SERVER AND PUBLIC DNS ARE NOT SAME. Just a notice that they are currently DIFFERENT" -ForegroundColor Yellow }
    
                if ($this.CXResolvedCNAME -like "*.cloudapp.*" -or $this.CXResolvedCNAME -like "*.control.*" -or $this.CXResolvedCNAME -like "*.trafficmanager.net*" -or $this.CXResolvedCNAME -like "*.prd.aadg.akadns.net" -or $this.CXResolvedCNAME -like "*.dscg.akamaiedge.net") 
                { Write-Host "      - INFO:: CX USING PUBLIC ENDPOINT" -ForegroundColor Cyan }
                elseif ($this.CXResolvedCNAME -like "*.privatelink.*") 
                { Write-Host "      - INFO:: CX USING PRIVATE ENDPOINT" -ForegroundColor Yellow }                   
            } 
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] PrintTest_Ports ()
    {
        Write-host "    - TESTS FOR ENDPOINT - $($this.Endpoint.Name) - IP ($($this.CXResolvedIP))"

        foreach ($Port in $this.Endpoint.PortsNeeded)
        {
            if($Port.Result -eq "CONNECTED")
                {
                    Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Green 
                }
            elseif($Port.Result -eq "CLOSED" -or $Port.Result -contains "NOT VALID IP")
                { 
                    $this.isAnyPortClosed = $true;
                    Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Red
                }
            else
                {
                    $this.isAnyPortClosed = $true; 
                    Write-host "      - PORT $($Port.Port.PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Yellow
                }
        }       
    }
}

#endregion Class



####################################################################################################################################################
#region Endpoints to be tested
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

#endregion Endpoints to be tested



####################################################################################################################################################
#region COLLECTING DATA

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COLLECTING DATA" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "..."

#----------------------------------------------------------------------------------------------------------------------
#Get Host File entries
function Get-HostsFilesEntries 
{
    try {
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
    catch {
        Write-Host "   - ERROR:: Get-HostsFilesEntries" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red   
    }

}
$HostsFileEntries = @(Get-HostsFilesEntries)


#----------------------------------------------------------------------------------------------------------------------
# Get DNSs used by CX
function Get-DnsCxServerAddresses {   
    try {
        $AddressFamilyIPV4 = 2 #AddressFamily -eq 2 = "IPv4"

        $DNSServers = Get-DnsClientServerAddress -ErrorAction Stop | `
            Where-Object {$_.AddressFamily -eq $AddressFamilyIPV4 } | ` 
            Select-Object -ExpandProperty ServerAddresses -Unique
    
        return $DNSServers        
    }
    catch {
        Write-Host "   - ERROR:: Get-DnsCxServerAddresses" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    }

}

$DnsCxServerAddresses = @(Get-DnsCxServerAddresses)

Get-DnsClientServerAddress | ? serveraddresses

#----------------------------------------------------------------------------------------------------------------------
# Test name resolution against CX DNS and Public DNS
foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.Resolve_DnsName_CXDNS()
    $EndpointTest.Resolve_DnsName_PublicDNS($DNSPublic)
}

#----------------------------------------------------------------------------------------------------------------------
# Checking Ports
foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.Test_Ports($TestPortConnectionTimeoutMs)
}


#endregion COLLECTING DATA



####################################################################################################################################################
# RESULTS
####################################################################################################################################################
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "RESULTS " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow


####################################################################################################################################################
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

####################################################################################################################################################
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

####################################################################################################################################################
#region RESULTS - PROXY SETTINGS
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  Computer Internet Settings - LOOK FOR PROXY SETTINGS"

try {
    $IESettings = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop

    if ($IESettings.ProxyEnable -eq 0) {
        Write-Host "   - INFO:: NO INTERNET PROXY ON SERVER / BROWSER" -ForegroundColor Green
    }
    else {
        Write-Host "   - WARN:: PROXY ENABLED ON SERVER $($IESettings.ProxyServer)" -ForegroundColor Red
        Write-Host "   - WARN:: PROXY EXCEPTIONS $($IESettings.ProxyOverride)" -ForegroundColor Red
    }    
}
catch {
    Write-Host "   - ERROR:: Not able to check Proxy settings" -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}


####################################################################################################################################################
try {
    $ProxyEvents = Get-EventLog `
        -LogName "Integration Runtime" `
        -InstanceId "26" `
        -Message "Http Proxy is set to*" `
        -Newest 15 `
        -ErrorAction Stop

    Write-Host "  ----------------------------------------------------------------------------"
    Write-Host "  SHIR Proxy Settings" 
        $ProxyEvents | Select TimeGenerated, Message


}
Catch [Exception]
{
    #DO NOTHING, BELOW JUST DEBUG

    <#
    $theError = $_
    
    Switch($theError.Exception.GetType().FullName)
    {
        System.Management.Automation.CmdletInvocationException
        {
            Write-Host "   - WARN:: NOT A PROBLEM IF NOT Self Hosted IR Machine" -ForegroundColor Yellow
            Write-Host "     - $($theError)" -ForegroundColor DarkGray
        }        
        default{
            Write-Host "   - ERROR:: ($($theError.Exception.GetType().FullName)) - NOT A PROBLEM IF NOT Self Hosted IR Machine" -ForegroundColor Yellow
            Write-Host "     - $($theError)" -ForegroundColor Yellow      
        }
    }
    #>
}

Write-Host "  ----------------------------------------------------------------------------"
#endregion RESULTS - PROXY SETTINGS

####################################################################################################################################################
#region RESULTS - NAME RESOLUTIONS

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  NAME RESOLUTION "

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.PrintTest_Endpoint($HostsFileEntries, $DNSPublic)
}

#endregion RESULTS - NAME RESOLUTIONS

####################################################################################################################################################
#region RESULTS - PORTS OPEN

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  PORTS OPEN (Used CX DNS or Host File entry listed above)"

$isAnyPortClosed = $false
foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.PrintTest_Ports()

    if ($EndpointTest.isAnyPortClosed) 
        { $isAnyPortClosed = $true }
}

if ($isAnyPortClosed) {
    Write-Host ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" -ForegroundColor Cyan
    Write-Host ">>ALERT:: IF ANY PORT IS" -ForegroundColor Cyan -NoNewline
    Write-Host " CLOSED " -ForegroundColor Red -NoNewline
    Write-Host "NEED TO MAKE SURE YOUR" -ForegroundColor Cyan -NoNewline
    Write-Host " CLIENT SIDE FIREWALL " -ForegroundColor Yellow -NoNewline
    Write-Host "IS" -ForegroundColor Cyan -NoNewline
    Write-Host " OPEN" -ForegroundColor Green
    Write-Host ">>CHECK" -ForegroundColor Cyan
    Write-Host ">> - https://learn.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network" -ForegroundColor Cyan
    Write-Host ">> - https://techcommunity.microsoft.com/t5/azure-synapse-analytics-blog/synapse-connectivity-series-part-1-inbound-sql-dw-connections-on/ba-p/3589170" -ForegroundColor Cyan
    Write-Host ">> - https://techcommunity.microsoft.com/t5/azure-synapse-analytics-blog/synapse-connectivity-series-part-2-inbound-synapse-private/ba-p/3705160" -ForegroundColor Cyan
    Write-Host ">>" -ForegroundColor Cyan
    Write-Host ">>CAN ALSO TEST MANUALLY LIKE BELOW" -ForegroundColor Cyan
    Write-Host ">> NAME RESOLUTION" -ForegroundColor Cyan
    Write-Host ">> - NSLOOKUP SERVERNAME.sql.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> - NSLOOKUP SERVERNAME-ondemand.sql.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> - NSLOOKUP SERVERNAME.dev.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> PORT IS OPEN" -ForegroundColor Cyan
    Write-Host ">> - Test-NetConnection -Port XXXX -ComputerName XXXENDPOINTXXX" -ForegroundColor Cyan
    Write-Host ">> - Test-NetConnection -Port 443  -ComputerName SERVERNAME.dev.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> - Test-NetConnection -Port 1433 -ComputerName SERVERNAME.sql.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> - Test-NetConnection -Port 1433 -ComputerName SERVERNAME-ondemand.sql.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">> - Test-NetConnection -Port 1443 -ComputerName SERVERNAME-ondemand.sql.azuresynapse.net" -ForegroundColor Cyan
    Write-Host ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" -ForegroundColor Cyan
}





#endregion RESULTS - PORTS OPEN

####################################################################################################################################################
#region TEST API CALLs

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "TEST API CALLs" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################################################################################################################
function TestSQLConnection 
{
    param (
        [string]$ServerName,
        [string]$DatabaseName="master",
        [string]$SQL_token=$null,
        [string]$SQL_user="TestUser",
        [string]$SQL_password="TestUser123",
        [int]$SQLConnectionTimeout = 15,
        [int]$SQLQueryTimeout = 15
    )
    
    $Query = "select TOP 1 connection_id, GETUTCDATE() as DATE from sys.dm_exec_connections where session_id = @@SPID"
    
    Try
    {
        if ($SQL_token -eq $null -or $SQL_token -eq "")
        {
            Write-Host "   - WARN:: SQL TOKEN NOT VALID. TESTING CONNECTION WITH FAKE SQL USER + PASSWORD, it will fail but we can check if can reach server"  -ForegroundColor Yellow
            $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Username $SQL_user -Password $SQL_password -Query $Query -ConnectionTimeout $SQLConnectionTimeout -QueryTimeout $SQLQueryTimeout -ErrorAction Stop
            Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))" -ForegroundColor Green
        }
        else
        {
            $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -AccessToken $SQL_token -Query $Query -ConnectionTimeout $SQLConnectionTimeout -QueryTimeout $SQLQueryTimeout -ErrorAction Stop
            Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))" -ForegroundColor Green
        }
    }
    Catch [Exception]
    {
        $theError = $_

        Switch($theError.Exception.GetType().FullName)
        {
            System.Management.Automation.ValidationMetadataException
            {
                Write-Host "   - ERROR:: ($($theError.Exception.GetType().FullName)):: TEST SQL ($($ServerName)) ENDPOINT" -ForegroundColor Red
                $theError
            }        
            default{
                Write-Host "   - ERROR:: ($($theError.Exception.GetType().FullName)):: TEST SQL ($($ServerName)) ENDPOINT"  -ForegroundColor Red
                Write-Host "     - Error: ($(@($theError.Exception.Errors)[0].Number)) / State: ($(@($theError.Exception.Errors)[0].State)) / Message: ($($theError.Exception.Message))" -ForegroundColor Red
                Write-Host "     - ClientConnectionId: $($theError.Exception.ClientConnectionId)" -ForegroundColor Red
            }
        }
    }
}





#----------------------------------------------------------------------------------------------------------------------
# Import Az.Account module
try {
    Import-Module Az.Accounts -MinimumVersion 2.2.0 -ErrorAction Stop
}
catch {
    Write-Host "   - ERROR::Import-Module Az.Accounts -MinimumVersion 2.2.0"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   - INSTALL AZ MODULE AND TRY AGAIN OR ELSE CANNOT PROCESS LOGIN TO TEST APIs" -ForegroundColor Yellow
    Write-Host "     - https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows" -ForegroundColor Yellow
    Write-Host "     - Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor Yellow
    break
}

#----------------------------------------------------------------------------------------------------------------------
# Try Connect
try {
    Write-Host " > Check your browser for authentication form ..." -ForegroundColor Yellow
    $null = Connect-AzAccount -Subscription $SubscriptionID -ErrorAction Stop
}
catch {
    Write-Host "   - ERROR::Connect-AzAccount"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}

#----------------------------------------------------------------------------------------------------------------------
# Get Management token - Control Plane operations
try {
    $Management_token = (Get-AzAccessToken -Resource "https://management.azure.com" -ErrorAction Stop).Token
    $Management_headers = @{ Authorization = "Bearer $Management_token" }   
}
catch {
    Write-Host "   - ERROR::Get-AzAccessToken (Management)"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}

#----------------------------------------------------------------------------------------------------------------------
# Get Dev Token - Data Plane Operations
try {
    $Dev_token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net" -ErrorAction Stop).Token
    $Dev_headers = @{ Authorization = "Bearer $Dev_token" }    
}
catch {
    Write-Host "   - ERROR::Get-AzAccessToken (dev synapse)"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}

#----------------------------------------------------------------------------------------------------------------------
# Get SQL Token - Test SQL Connectivity
try {
    $SQL_token = (Get-AzAccessToken -Resource "https://database.windows.net" -ErrorAction Stop).Token
}
catch {
    Write-Host "   - ERROR::Get-AzAccessToken (database)"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
}


#----------------------------------------------------------------------------------------------------------------------
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  -Testing API call to management endpoint (management.azure.com) on Port 443" -ForegroundColor DarkGray

$WorkspaceObject = $null
$SQLEndpoint = $null
$SQLOndemandEndpoint = $null
$DevEndpoint = $null
[bool]$isSynapseWorkspace = $false

try {
    #https://learn.microsoft.com/en-us/rest/api/synapse/workspaces/list?tabs=HTTP
    #GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)"
    $uri += "/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01"

    Write-Host "   > API CALL ($($uri))" -ForegroundColor Yellow

    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Management_headers

    foreach ($WorkspaceObject in $result.value)
    {
        if ($WorkspaceObject.name -eq $WorkspaceName)
        {
            Write-Host "   - Workspace ($($WorkspaceObject.name)) Found"
            
            $SQLOndemandEndpoint = $WorkspaceObject.properties.connectivityEndpoints.sqlOnDemand
            $DevEndpoint = $WorkspaceObject.properties.connectivityEndpoints.dev    

            if ($WorkspaceObject.properties.extraProperties.WorkspaceType -eq "Normal") {
                Write-Host "     - This is a Synapse workspace (Not a former SQL DW)"
                $SQLEndpoint = $WorkspaceObject.properties.connectivityEndpoints.sql
                $isSynapseWorkspace = $true
            }

            if ($WorkspaceObject.properties.extraProperties.WorkspaceType -eq "Connected") {
                Write-Host "     - Former SQL DW + Workspace experience"
                $SQLEndpoint = "$WorkspaceName.database.windows.net"
            }
            break
        }
    }

    if ($DevEndpoint -ne $null) 
    {
        Write-Host "     - SQLEndpoint: ($($SQLEndpoint))"
        Write-Host "     - SQLOndemandEndpoint: ($($SQLOndemandEndpoint))"
        Write-Host "     - DevEndpoint: ($($DevEndpoint))"
    }
    else {
        Write-Host "    - No Synapse Workspace found" -ForegroundColor Yellow

        #https://learn.microsoft.com/en-us/rest/api/sql/2022-05-01-preview/servers/list?tabs=HTTP
        #GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Sql/servers?api-version=2022-05-01-preview
        $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)"
        $uri += "/providers/Microsoft.SQL/servers?api-version=2022-05-01-preview"

        Write-Host "   > API CALL ($($uri))"

        $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Management_headers

        foreach ($SQLObject in $result.value)
        {
            if ($SQLObject.name -eq $WorkspaceName)
            {
                Write-Host "    - Logical SQL Server ($($SQLObject.name)) Found"            

                $SQLEndpoint = "$WorkspaceName.database.windows.net"
                Write-Host "      - SQLEndpoint: ($($SQLEndpoint))"
                break
            }
        }
    }
    Write-Host "   - SUCESS:: Connection Management ENDPOINT"  -ForegroundColor Green        
}
catch {
    Write-Host "   - ERROR:: TEST Management ENDPOINT" -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq "Forbidden") {
        Write-Host "   - ERROR:: You do not have permission to reach management.azure.com API" -ForegroundColor Red
    }

}


#----------------------------------------------------------------------------------------------------------------------
#Testing SQL DEV API
$DevEndpoint = "$($WorkspaceName).dev.azuresynapse.net"
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  -Testing SQL DEV API ($($DevEndpoint)) on Port 443" -ForegroundColor DarkGray

try 
{
    #https://learn.microsoft.com/en-us/rest/api/synapse/data-plane/workspace/get?tabs=HTTP
    #GET {endpoint}/workspace?api-version=2020-12-01         
    
    $uri = "https://$($DevEndpoint)/workspace?api-version=2020-12-01"

    Write-Host "   > API CALL ($($uri))"

    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Dev_headers
    Write-Host "   - SUCESS:: Connection DEV ENDPOINT"  -ForegroundColor Green
}
catch {
    Write-Host "   - ERROR:: TEST DEV ENDPOINT"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq "Forbidden") {
        Write-Host "   - ERROR:: You do not have permission to reach Synapse DEV API" -ForegroundColor Red
    }
}


#----------------------------------------------------------------------------------------------------------------------
# Import SQLServer module
try {
    Import-Module SQLServer -ErrorAction Stop
}
catch {
    Write-Host "   - ERROR::Import-Module SqlServer"  -ForegroundColor Red
    Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   - INSTALL SQL Server MODULE AND TRY AGAIN OR ELSE CANNOT PROCESS TEST SQL LOGIN" -ForegroundColor Yellow
    Write-Host "     - https://learn.microsoft.com/en-us/sql/powershell/sql-server-powershell" -ForegroundColor Yellow
    Write-Host "     - Install-Module -Name SqlServer -Repository PSGallery -Force" -ForegroundColor Yellow
    break
}

#----------------------------------------------------------------------------------------------------------------------
#Testing SQL connection
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  -Testing SQL connection ($($SQLEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray

if ($SQLEndpoint -eq $null)
{
    Write-Host "   - ERROR:: CANNOT TEST SQL connection"  -ForegroundColor Red
}
else 
{
    TestSQLConnection -ServerName $SQLEndpoint -DatabaseName "master" -SQLConnectionTimeout $SQLConnectionTimeout -SQLQueryTimeout $SQLQueryTimeout -SQL_token $SQL_token
}

#----------------------------------------------------------------------------------------------------------------------
#Testing SQL Ondemand connection
$SQLOndemandEndpoint = "$($WorkspaceName)-ondemand.sql.azuresynapse.net"
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  -Testing SQL Ondemand connection ($($SQLOndemandEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray

if ($SQLOndemandEndpoint -eq $null) 
{
    Write-Host "   - ERROR:: CANNOT TEST SQL Ondemand connection"  -ForegroundColor Red
}
else 
{
    TestSQLConnection -ServerName $SQLOndemandEndpoint -DatabaseName "master" -SQLConnectionTimeout $SQLConnectionTimeout -SQLQueryTimeout $SQLQueryTimeout -SQL_token $SQL_token
}

#endregion TEST API CALLs

####################################################################################################################################################
# Just a note
Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   NOTE on differences for Dedicated pool endpoint"
Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   SYNAPSE use endpoints below:"
Write-Host "    - XXXXXX.sql.azuresynapse.net <--" -ForegroundColor Yellow
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"
Write-Host ""
Write-Host "   FORMER SQL DW + SYNAPSE WORKSPACE use endpoints below:"
Write-Host "    - XXXXXX.database.windows.net  <--" -ForegroundColor Yellow
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"


####################################################################################################################################################
#CLEANUP
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "CLEAN UP" -ForegroundColor Yellow

Get-PSSession | Remove-PSSession | Out-Null
[System.GC]::Collect()         
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
####################################################################################################################################################

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "END OF SCRIPT" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
 
