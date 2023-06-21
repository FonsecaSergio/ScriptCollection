#Requires -Version 5

<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-06-21

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
 - ** Anonymous telemetry can be captured **

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
    - 2023-05-04 - Anonymous telemetry capture
    - 2023-05-24 - Improved Browser Proxy detection (Added Proxy script option)
                 - Adding additional URLs from https://learn.microsoft.com/en-us/azure/synapse-analytics/security/how-to-connect-to-workspace-from-restricted-network#step-6-allow-url-through-firewall
                 - Small fixes and improvements
    - 2023-05-29 - Documented and improved using GitHub Copilot chatbot
    - 2023-06-21 - Some small fixes
                 - Removed public DNS check. Many CX have blocked internet and requestes were failing and causing confusion

#KNOW ISSUES / TO DO
    - Need to make / test on linux / Mac machines
    - Sign code
    - Add links and solution to errors
#> 


using namespace System.Net

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
New-Variable -Name VERSION -Value "2023-06-21" -Option Constant -ErrorAction Ignore
New-Variable -Name AnonymousRunId -Value ([guid]::NewGuid()).Guid -Option Constant -ErrorAction Ignore

Write-Host ("Current version: " + $VERSION)
Write-Host ("PS version: " + $psVersionTable.PSVersion)
Write-Host ("PS OS version: " + $psVersionTable.OS)
Write-Host ("System.Environment OS version: " + [System.Environment]::OSVersion.Platform)
Write-Host ("WorkspaceName: " + $WorkspaceName)
Write-Host ("SubscriptionID: " + $SubscriptionID)



####################################################################################################################################################
#CHECK IF MACHINE IS WINDOWS
<#
.SYNOPSIS
    Tests the connection on Windows machines.

.DESCRIPTION
    This function tests the connection on Windows machines by checking the operating system version. If the operating system is not Windows, it will throw an error and exit the function.

.PARAMETER None

.EXAMPLE
    Test-ConnectionOnWindows
#>
function Test-ConnectionOnWindows {
    [String]$OS = [System.Environment]::OSVersion.Platform
    Write-Host "SO: $($OS)"

    if (-not(($OS.Contains("Win"))))
    {
        Write-Error "Only can be used on Windows Machines"
        Break
    }
}
Test-ConnectionOnWindows

####################################################################################################################################################

if (-not(Get-Module -Name DnsClient -ListAvailable)) {
    try {
        Import-Module DnsClient -ErrorAction Stop
    }
    catch {
        Write-Host "   - ERROR::Import-Module DnsClient"  -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    }
}


####################################################################################################################################################
#region OTHER PARAMETERS / CONSTANTS

New-Variable -Name TestPortConnectionTimeoutMs -Value 1000 -Option Constant -ErrorAction Ignore
New-Variable -Name SQLConnectionTimeout -Value 15 -Option Constant -ErrorAction Ignore
New-Variable -Name SQLQueryTimeout -Value 15 -Option Constant -ErrorAction Ignore
New-Variable -Name HostsFile -Value "$env:SystemDrive\Windows\System32\Drivers\etc\hosts" -Option Constant -ErrorAction Ignore
New-Variable -Name DebugConnectToEndpoints -Value $true -Option Constant -ErrorAction Ignore #Used for debug. Will not make real connection test to endpoints

#endregion OTHER PARAMETERS / CONSTANTS
$Summary = New-Object System.Text.StringBuilder

####################################################################################################################################################
#Telemetry

<#
.SYNOPSIS
Sends a ANONYMOUS TELEMETRY event to Azure Application Insights.

.DESCRIPTION
The logEvent function sends a custom event to Azure Application Insights. The event contains a message and an anonymous run ID. If the anonymous run ID is not provided, a new GUID is generated.

.PARAMETER Message
The message to be included in the event.

.PARAMETER AnonymousRunId
The anonymous run ID to be included in the event. If not provided, a new GUID is generated.

.EXAMPLE
logEvent -Message "This is a test message" -AnonymousRunId "12345"

#>
function logEvent {
    param (
        [String]$Message,
        [String]$AnonymousRunId = ([guid]::NewGuid()).Guid
    )
    try {
        $InstrumentationKey = "d94ff6ec-feda-4cc9-8d0c-0a5e6049b581"        
        $body = New-Object PSObject `
        | Add-Member -PassThru NoteProperty name 'Microsoft.ApplicationInsights.Event' `
        | Add-Member -PassThru NoteProperty time $([System.dateTime]::UtcNow.ToString('o')) `
        | Add-Member -PassThru NoteProperty iKey $InstrumentationKey `
        | Add-Member -PassThru NoteProperty tags (New-Object PSObject | Add-Member -PassThru NoteProperty 'ai.user.id' $AnonymousRunId) `
        | Add-Member -PassThru NoteProperty data (New-Object PSObject `
            | Add-Member -PassThru NoteProperty baseType 'EventData' `
            | Add-Member -PassThru NoteProperty baseData (New-Object PSObject `
                | Add-Member -PassThru NoteProperty ver 2 `
                | Add-Member -PassThru NoteProperty name $Message));
        $body = $body | ConvertTo-JSON -depth 5;
        Invoke-WebRequest -Uri 'https://dc.services.visualstudio.com/v2/track' -ErrorAction SilentlyContinue -Method 'POST' -UseBasicParsing -body $body > $null
    }
    catch {
        #Do nothing

        #Write-Host "ERROR ($($_.Exception))"
    }        
}

$Message = "Version: " + $VERSION
logEvent -Message $Message -AnonymousRunId $AnonymousRunId


<#
.SYNOPSIS
Sends a ANONYMOUS TELEMETRY event to Azure Application Insights.

.DESCRIPTION
The logEvent function sends a custom event to Azure Application Insights. The event contains a message and an anonymous run ID. If the anonymous run ID is not provided, a new GUID is generated.

.PARAMETER Message
The message to be included in the event.

.PARAMETER AnonymousRunId
The anonymous run ID to be included in the event. If not provided, a new GUID is generated.

.EXAMPLE
logEvent -Message "This is a test message" -AnonymousRunId "12345"

#>

#NEED TO BE DONE
function logException
{
    param (
        [String]$Message,
        [String]$AnonymousRunId = ([guid]::NewGuid()).Guid
    )
    try {
        $InstrumentationKey = "d94ff6ec-feda-4cc9-8d0c-0a5e6049b581"        
        $body = New-Object PSObject `
        | Add-Member -PassThru NoteProperty name 'Microsoft.ApplicationInsights.Event' `
        | Add-Member -PassThru NoteProperty time $([System.dateTime]::UtcNow.ToString('o')) `
        | Add-Member -PassThru NoteProperty iKey $InstrumentationKey `
        | Add-Member -PassThru NoteProperty tags (New-Object PSObject | Add-Member -PassThru NoteProperty 'ai.user.id' $AnonymousRunId) `
        | Add-Member -PassThru NoteProperty data (New-Object PSObject `
            | Add-Member -PassThru NoteProperty baseType 'EventData' `
            | Add-Member -PassThru NoteProperty baseData (New-Object PSObject `
                | Add-Member -PassThru NoteProperty ver 2 `
                | Add-Member -PassThru NoteProperty name $Message));
        $body = $body | ConvertTo-JSON -depth 5;
        Invoke-WebRequest -Uri 'https://dc.services.visualstudio.com/v2/track' -ErrorAction SilentlyContinue -Method 'POST' -UseBasicParsing -body $body > $null
    }
    catch {
        #Do nothing

        #Write-Host "ERROR ($($_.Exception))"
    }        
}



####################################################################################################################################################
#region Class

#----------------------------------------------------------------------------------------------------------------------
Class Port
{
    [int]$Port
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

    Endpoint ([string]$Name, [int[]]$PortsNeeded) 
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
    [String]$CXHostFileIP
    [String]$CXResolvedCNAME

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
            if ($DNSResults.NameHost.Count -gt 0 -and $null -ne $this.CXResolvedIP -and $this.CXResolvedIP -ne "") 
            {
                $this.CXResolvedCNAME = @($DNSResults.NameHost)[$DNSResults.NameHost.Count - 1]
            }
        }
        catch 
        {
            Write-Host "   - ERROR:: Trying to resolve DNS for $($this.Endpoint.Name) from Customer DNS" -ForegroundColor DarkGray
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    #https://copdips.com/2019/09/fast-tcp-port-check-in-powershell.html
    [void] Test_Ports ([Int]$Timeout = 1000)
    {
        $IPtoTest = $this.CXResolvedIP

        #Check what IP will be used for test
        if($null -ne $this.CXHostFileIP -and $this.CXHostFileIP -ne "")
        {
            $IPtoTest = $this.CXHostFileIP
        } 

        # Loop through each port needed by the endpoint
        foreach ($Port in $this.Endpoint.PortsNeeded)
        {
            try 
            {
                # Create a new TCP client object
                $tcpClient = New-Object System.Net.Sockets.TcpClient

                # Check if the CX endpoint IP address has been resolved
                if($null -eq $IPtoTest -or $IPtoTest -eq "")
                {                    
                    # If the IP address is not valid, set the result to "NOT VALID IP - NAME NOT RESOLVED"
                    #Write-Host " -INFO:: NOT Testing Port / IP NOT VALID - $($this.Endpoint.Name) / IP($($this.CXResolvedIP)):PORT($($Port.Port))" -ForegroundColor Yellow
                    $Port.Result = "CANNOT RESOLVE NAME - DNS ISSUE"
                }
                else
                {
                    $portOpened = $false

                    # Attempt to connect to the port asynchronously
                    $portOpened = $tcpClient.ConnectAsync($IPtoTest, $Port.Port).Wait($Timeout)

                    # If the port is open, set the result to "CONNECTED"
                    if($portOpened -eq $true) {
                        $Port.Result = "CONNECTED"
                    }
                    # If the port is closed, set the result to "CLOSED"
                    else{
                        $Port.Result = "CLOSED"
                    }                   
                } 


                # Close the TCP client object
                $tcpClient.Close()
            }
            catch 
            {
                # If an error occurs, set the result to "CLOSED"
                $Port.Result = "CLOSED"
                Write-Host " -ERROR:: Testing Port $($this.Endpoint.Name) / IP($($IPtoTest)):PORT($($Port.Port))" -ForegroundColor DarkGray

                # Check if the error is due to a non-existent host
                if ($null -ne $_.Exception.InnerException.InnerException)
                {
                    if ($_.Exception.InnerException.InnerException.ErrorCode -eq 11001) { #11001 No such host is known                        
                        Write-Host "  -ERROR:: Test-Port: ($($this.Endpoint.Name) / $($IPtoTest) : $($Port.Port)) - $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "  -ERROR:: Test-Port: $($_.Exception.Message)" -ForegroundColor Red
                }                
            }          
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] PrintTest_Endpoint ($HostsFileEntries) 
    {
        # Print the DNS information for the endpoint
        Write-Host "   ----------------------------------------------------------------------------"
        Write-Host "   - DNS for ($($this.Endpoint.Name))"
        Write-Host "      - CX DNS:($($this.CXResolvedIP)) / NAME:($($this.CXResolvedCNAME))"

        $HostsFileEntry = $null
        $_HaveHostsFileEntry = $false

        # Check if the endpoint has an entry in the hosts file
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

        if ($_HaveHostsFileEntry)
        {# HAVE HOST FILE ENTRY           
            if ($HostsFileEntry.IP -ne $this.PublicIP) 
            { 
                #Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE NOT SAME" -ForegroundColor Yellow 
            }

            Write-Host "      - INFO:: ENDPOINT FIXED ON HOSTS FILE" -ForegroundColor Yellow
        }
        else
        {# DOES NOT HAVE HOST FILE ENTRY
            if ($null -eq $this.CXResolvedIP) 
            { 
                # If the CX resolved IP is null, log an error message to the console
                Write-Host "      - ERROR:: CX NAME RESOLUTION DIDN'T WORK" -ForegroundColor Red 
            }
            else 
            {
                # Check if the CX endpoint is using a public or private endpoint
                if (
                    $this.CXResolvedCNAME -like "*.cloudapp.*" -or `
                    $this.CXResolvedCNAME -like "*.control.*" -or `
                    $this.CXResolvedCNAME -like "*.trafficmanager.net*" -or `
                    $this.CXResolvedCNAME -like "*msedge.net" -or `
                    $this.CXResolvedCNAME -like "*.akadns.net") 
                { 
                    Write-Host "      - INFO:: CX USING PUBLIC ENDPOINT" -ForegroundColor Cyan 
                }
                elseif ($this.CXResolvedCNAME -like "*.privatelink.*") 
                { 
                    Write-Host "      - INFO:: CX USING PRIVATE ENDPOINT" -ForegroundColor Yellow 
                }                   
            } 
        }
    }

    #----------------------------------------------------------------------------------------------------------------------
    [void] PrintTest_Ports ()
    {
        

        if ($null -eq $this.CXHostFileIP -or $this.CXHostFileIP -eq "")
        {
            Write-host "    - TESTS FOR ENDPOINT - $($this.Endpoint.Name) - CX DNS IP ($($this.CXResolvedIP))"
        }
        else
        {
            Write-host "    - TESTS FOR ENDPOINT - $($this.Endpoint.Name) - CX HOSTFILE IP ($($this.CXHostFileIP))"
        }

        foreach ($Port in $this.Endpoint.PortsNeeded)
        {
            if($Port.Result -eq "CONNECTED")
                {
                    Write-host "      - PORT $(($Port.Port).ToString().PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Green 
                }
            elseif($Port.Result -eq "CLOSED" -or $Port.Result -contains "NOT VALID IP")
                { 
                    $this.isAnyPortClosed = $true;
                    Write-host "      - PORT $(($Port.Port).ToString().PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Red
                }
            else
                {
                    $this.isAnyPortClosed = $true; 
                    Write-host "      - PORT $(($Port.Port).ToString().PadRight(4," ")) - RESULT: $($Port.Result)"  -ForegroundColor Yellow
                }
        }       
    }
}

#endregion Class



####################################################################################################################################################
#region Endpoints to be tested

$EndpointTestList = @()

$Endpoints = [ordered]@{
    "$($WorkspaceName).sql.azuresynapse.net" = @(1433, 1443, 443)
    "$($WorkspaceName)-ondemand.sql.azuresynapse.net" = @(1433, 1443, 443)
    "$($WorkspaceName).database.windows.net" = @(1433, 1443, 443)
    "$($WorkspaceName).dev.azuresynapse.net" = @(443)
    "web.azuresynapse.net" = @(443)
    "management.azure.com" = @(443)
    "login.windows.net" = @(443)
    "login.microsoftonline.com" = @(443)
    "aadcdn.msauth.net" = @(443)
    "graph.microsoft.com" = @(443)
}

foreach ($Endpoint in $Endpoints.Keys) 
{
    $Ports = $Endpoints[$Endpoint]
    $EndpointTestList += [EndpointTest]::new([Endpoint]::new($Endpoint, @($Ports)))
}

#endregion Endpoints to be tested



####################################################################################################################################################
#region COLLECTING DATA

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COLLECTING DATA" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################################################################################################################
#region - HostsFile

#----------------------------------------------------------------------------------------------------------------------
<#
.SYNOPSIS
Reads the hosts file and returns the IP and Host entries as custom objects.

.DESCRIPTION
This function reads the hosts file and returns the IP and Host entries as custom objects. It uses a regular expression pattern to match IP and Host entries in the hosts file.

.PARAMETER None

.INPUTS
None

.OUTPUTS
Custom objects with the IP and Host properties.

.EXAMPLE
Get-HostsFilesEntries

This command reads the hosts file and returns the IP and Host entries as custom objects.
#>
function Get-HostsFilesEntries 
{
    try {
        # This regular expression pattern matches IP and Host entries in the hosts file
        $Pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'

        # Read the hosts file and parse each line using a regular expression
        Get-Content -Path $HostsFile | ForEach-Object {
            if ($_ -match $Pattern) {
                # Create a custom object with the IP and Host properties
                [PSCustomObject]@{
                    IP = $Matches.IP
                    Host = $Matches.Host
                }
            }
        }
    }
    catch {
        # Handle any errors that occur during the execution of the function
        Write-Host "   - ERROR:: Get-HostsFilesEntries" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red   
    }
}

$HostsFileEntries = @(Get-HostsFilesEntries)


Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  HOSTS FILE [$($HostsFile)]"

if ($HostsFileEntries.Count -gt 0) {
    foreach ($HostsFileEntry in $HostsFileEntries)
    {
        $isFoundOnList = $false

        #Write-Host "HostsFileEntry = $($HostsFileEntry)"
        foreach ($EndpointTest in $EndpointTestList)
        {
            #Write-Host "EndpointTest = $($EndpointTest.Endpoint.Name)"
            
            if ($HostsFileEntry.HOST.Contains($EndpointTest.Endpoint.Name)) 
            {
                Write-Host "   - IP [$($HostsFileEntry.IP)] / NAME [$($HostsFileEntry.HOST)]" -ForegroundColor Red    
                $isFoundOnList = $true

                #Document the IP found on the HostsFile
                $EndpointTestList[$EndpointTestList.IndexOf($EndpointTest)].CXHostFileIP = ($HostsFileEntry.IP)
            }
        }
        if ($isFoundOnList -eq $false)
        {
            Write-Host "   - IP [$($HostsFileEntry.IP)] / NAME [$($HostsFileEntry.HOST)]"
        }
    }     
}
else {
    Write-Host "   - NO RELATED ENTRY" -ForegroundColor Green
}

#----------------------------------------------------------------------------------------------------------------------
<#
.SYNOPSIS
Retrieves the DNS server addresses from the local machine.

.DESCRIPTION
This function retrieves the DNS server addresses from the local machine. It first calls the `Get-DnsClientServerAddress` cmdlet to get the DNS client server addresses. It then filters out loopback and Bluetooth interfaces, as well as empty server addresses. It selects unique server addresses and expands the property. Finally, it returns the DNS server addresses.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
PS C:\> Get-DnsCxServerAddresses
Returns a list of DNS server addresses from the local machine.

#>
function Get-DnsCxServerAddresses 
{   
    try {
        # Get the DNS client server addresses
        $DNSServers = Get-DnsClientServerAddress -ErrorAction Stop

        # Filter out loopback and Bluetooth interfaces, and empty server addresses
        $DNSServers = $DNSServers | Where-Object {
            (!($_.InterfaceAlias).contains("Loopback")) -and 
            (!($_.InterfaceAlias).contains("Bluetooth")) -and
            ("" -ne $_.ServerAddresses)
        }

        # Select unique server addresses and expand the property
        $DNSServers = $DNSServers | Select-Object -Unique ServerAddresses -ExpandProperty ServerAddresses
    
        # Return the DNS server addresses
        return @($DNSServers)
    }
    catch {
        # If an error occurs, write an error message to the console
        Write-Host "   - ERROR:: Get-DnsCxServerAddresses" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    }
}

$DnsCxServerAddresses = Get-DnsCxServerAddresses

#Get-DnsClientServerAddress | Where-Object ServerAddresses

#----------------------------------------------------------------------------------------------------------------------
# Test name resolution against CX DNS and Public DNS
foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.Resolve_DnsName_CXDNS()
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
Write-Host "  ----------------------------------------------------------------------------"
Get-DnsClientServerAddress | Where-Object ServerAddresses
Write-Host "  ----------------------------------------------------------------------------"
#endregion RESULTS - DNS SERVERS

####################################################################################################################################################
#region RESULTS - PROXY SETTINGS
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  Computer Internet Settings - LOOK FOR PROXY SETTINGS"

<#
.SYNOPSIS
Retrieves and displays the browser proxy settings for the current user.

.DESCRIPTION
This function retrieves and displays the Internet Explorer proxy settings from the registry for the current user. It displays an info message if there is no proxy enabled and no auto-config URL, a warning message with the proxy server and exceptions if a proxy is enabled, and a warning message with the auto-config URL if there is one. If there is an error retrieving the settings, it displays an error message with the exception message.

.EXAMPLE
Get-BrowserProxySettings

#>
function Get-BrowserProxySettings 
{
    try {
        # Retrieve the Internet Explorer settings from the registry
        $IESettings = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop

        # If there is no proxy enabled and no auto-config URL, display an info message
        if (($IESettings.ProxyEnable -eq 0) -and ($null -eq $IESettings.AutoConfigURL)) 
        {
            Write-Host "   - INFO:: NO INTERNET PROXY ON SERVER / BROWSER" -ForegroundColor Green
        }

        # If a proxy is enabled, display a warning message with the proxy server and exceptions
        if ($IESettings.ProxyEnable -eq 1)
        {
            Write-Host "   - WARN:: PROXY ENABLED ON SERVER $($IESettings.ProxyServer)" -ForegroundColor Red
            Write-Host "   - WARN:: PROXY EXCEPTIONS $($IESettings.ProxyOverride)" -ForegroundColor Red
        }    

        # If there is an auto-config URL, display a warning message with the URL
        if ($null -ne $IESettings.AutoConfigURL)
        {
            Write-Host "   - WARN:: PROXY SCRIPT $($IESettings.AutoConfigURL)" -ForegroundColor Red
        }    

    }
    catch {
        # If there is an error retrieving the settings, display an error message with the exception message
        Write-Host "   - ERROR:: Not able to check Proxy settings" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Get-BrowserProxySettings

####################################################################################################################################################
<#
.SYNOPSIS
Retrieves and displays the SHIR proxy settings.

.DESCRIPTION
This function retrieves the SHIR (Self-Hosted Integration Runtime) proxy settings by searching the Integration Runtime event log for the most recent 15 instances of event ID 26 with a message containing "Http Proxy is set to". It then displays the results in the console.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Get-SHIRProxySettings
#>
function Get-SHIRProxySettings 
{
    try {
        $ProxyEvents = Get-EventLog `
            -LogName "Integration Runtime" `
            -InstanceId "26" `
            -Message "Http Proxy is set to*" `
            -Newest 15 `
            -ErrorAction Stop

        Write-Host "  ----------------------------------------------------------------------------"
        Write-Host "  SHIR Proxy Settings" 
            $ProxyEvents | Select-Object TimeGenerated, Message


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
}

Get-SHIRProxySettings

Write-Host "  ----------------------------------------------------------------------------"
#endregion RESULTS - PROXY SETTINGS

####################################################################################################################################################
#region RESULTS - NAME RESOLUTIONS

Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  NAME RESOLUTION "

foreach ($EndpointTest in $EndpointTestList)
{
    $EndpointTest.PrintTest_Endpoint($HostsFileEntries)
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
    [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
    [void]$Summary.Append(">>ALERT:: IF ANY PORT IS")
    [void]$Summary.Append(" CLOSED ")
    [void]$Summary.Append("NEED TO MAKE SURE YOUR")
    [void]$Summary.Append(" CLIENT SIDE FIREWALL ")
    [void]$Summary.Append("IS")
    [void]$Summary.AppendLine(" OPEN")
    [void]$Summary.AppendLine(">>CHECK")
    [void]$Summary.AppendLine(">> - https://learn.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network")
    [void]$Summary.AppendLine(">> - https://techcommunity.microsoft.com/t5/azure-synapse-analytics-blog/synapse-connectivity-series-part-1-inbound-sql-dw-connections-on/ba-p/3589170")
    [void]$Summary.AppendLine(">> - https://techcommunity.microsoft.com/t5/azure-synapse-analytics-blog/synapse-connectivity-series-part-2-inbound-synapse-private/ba-p/3705160")
    [void]$Summary.AppendLine(">>")
    [void]$Summary.AppendLine(">>CAN ALSO TEST MANUALLY LIKE BELOW")
    [void]$Summary.AppendLine(">> NAME RESOLUTION")
    [void]$Summary.AppendLine(">> - NSLOOKUP SERVERNAME.sql.azuresynapse.net")
    [void]$Summary.AppendLine(">> - NSLOOKUP SERVERNAME-ondemand.sql.azuresynapse.net")
    [void]$Summary.AppendLine(">> - NSLOOKUP SERVERNAME.dev.azuresynapse.net")
    [void]$Summary.AppendLine(">> PORT IS OPEN")
    [void]$Summary.AppendLine(">> - Test-NetConnection -Port XXXX -ComputerName XXXENDPOINTXXX")
    [void]$Summary.AppendLine(">> - Test-NetConnection -Port 443  -ComputerName SERVERNAME.dev.azuresynapse.net")
    [void]$Summary.AppendLine(">> - Test-NetConnection -Port 1433 -ComputerName SERVERNAME.sql.azuresynapse.net")
    [void]$Summary.AppendLine(">> - Test-NetConnection -Port 1433 -ComputerName SERVERNAME-ondemand.sql.azuresynapse.net")
    [void]$Summary.AppendLine(">> - Test-NetConnection -Port 1443 -ComputerName SERVERNAME-ondemand.sql.azuresynapse.net")
    [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
    [void]$Summary.AppendLine("")

}


#endregion RESULTS - PORTS OPEN


if ($DebugConnectToEndpoints)
{
    ####################################################################################################################################################
    #region TEST API CALLs

    Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "TEST API CALLs" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

    ####################################################################################################################################################
    <#
    .SYNOPSIS
    Tests a SQL connection to a specified server.

    .DESCRIPTION
    Tests a SQL connection to a specified server using either a SQL token or a SQL user and password.

    .PARAMETER ServerName
    The name of the SQL server to test the connection to.

    .PARAMETER DatabaseName
    The name of the database to connect to. Default is "master".

    .PARAMETER SQL_token
    The SQL token to use for authentication. If not provided, a SQL user and password will be used.

    .PARAMETER SQL_user
    The SQL user to use for authentication. Default is "TestUser".

    .PARAMETER SQL_password
    The SQL password to use for authentication. Default is "TestUser123".

    .PARAMETER SQLConnectionTimeout
    The timeout for the SQL connection in seconds. Default is 15.

    .PARAMETER SQLQueryTimeout
    The timeout for the SQL query in seconds. Default is 15.

    .EXAMPLE
    TestSQLConnection -ServerName "localhost" -DatabaseName "master" -SQL_user "myuser" -SQL_password "mypassword"

    .NOTES
    #>
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
            if ( ($null -eq $SQL_token) -or ("" -eq $SQL_token))
            {
                Write-Host "   - WARN:: SQL TOKEN NOT VALID. TESTING CONNECTION WITH FAKE SQL USER + PASSWORD, it will fail but we can check if can reach server"  -ForegroundColor Yellow
                
                $maxRetries = 3
                $retryCount = 0
                $retryDelay = 5 # seconds

                do {
                    try {
                        $result = Invoke-Sqlcmd `
                            -ServerInstance $ServerName `
                            -Database $DatabaseName `
                            -Username $SQL_user `
                            -Password $SQL_password `
                            -Query $Query `
                            -ConnectionTimeout $SQLConnectionTimeout `
                            -QueryTimeout $SQLQueryTimeout `
                            -ErrorAction Stop

                        Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))" -ForegroundColor Green
                        break # exit the loop if the command succeeds
                    } catch {

                        $retryCount++
                        if ($retryCount -lt $maxRetries) {
                            Write-Host "Retrying in $retryDelay seconds..."
                            Start-Sleep -Seconds $retryDelay
                        } else {
                            Write-Host "Maximum retries reached. Aborting."
                            throw # re-throw the exception if the maximum retries are reached
                        }
                    }
                } while ($retryCount -lt $maxRetries)
                
            }
            else
            {
                $maxRetries = 3
                $retryCount = 0
                $retryDelay = 5 # seconds

                do {
                    try {
                        $result = Invoke-Sqlcmd `
                            -ServerInstance $ServerName `
                            -Database $DatabaseName `
                            -AccessToken $SQL_token `
                            -Query $Query `
                            -ConnectionTimeout $SQLConnectionTimeout `
                            -QueryTimeout $SQLQueryTimeout `
                            -ErrorAction Stop

                        Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))" -ForegroundColor Green
                        break # exit the loop if the command succeeds
                    } catch {

                        $retryCount++
                        if ($retryCount -lt $maxRetries) {
                            Write-Host "Retrying in $retryDelay seconds..."
                            Start-Sleep -Seconds $retryDelay
                        } else {
                            Write-Host "Maximum retries reached. Aborting."
                            throw # re-throw the exception if the maximum retries are reached
                        }
                    }
                } while ($retryCount -lt $maxRetries)
                
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
                System.Data.SqlClient.SqlException
                {
                    Write-Host "   - ERROR:: ($($theError.Exception.GetType().FullName)):: TEST SQL ($($ServerName)) ENDPOINT"  -ForegroundColor Red
                    Write-Host "     - Error: ($(@($theError.Exception.Errors)[0].Number)) / State: ($(@($theError.Exception.Errors)[0].State)) / Message: ($($theError.Exception.Message))" -ForegroundColor Red
                    Write-Host "     - ClientConnectionId: $($theError.Exception.ClientConnectionId)" -ForegroundColor Red

                    if ($theError.Exception.Message -like "*Login failed for user '<token-identified principal>'*")
                    {
                        [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
                        [void]$Summary.AppendLine(">> - ERROR::($($ServerName)) Login failed for user '<token-identified principal>")
                        [void]$Summary.AppendLine(">>   - CHECK")
                        [void]$Summary.AppendLine(">>     - https://techcommunity.microsoft.com/t5/azure-database-support-blog/aad-auth-error-login-failed-for-user-lt-token-identified/ba-p/1417535")
                        [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
                        [void]$Summary.AppendLine("")   
                    }

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
        # Attempt to import the Az.Accounts module with a minimum version of 2.2.0
        Import-Module Az.Accounts -MinimumVersion 2.2.0 -ErrorAction Stop
    }
    catch {
        # If the import fails, display an error message with the exception message
        Write-Host "   - ERROR::Import-Module Az.Accounts -MinimumVersion 2.2.0"  -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   - INSTALL AZ MODULE AND TRY AGAIN OR ELSE CANNOT PROCESS LOGIN TO TEST APIs" -ForegroundColor Yellow
        Write-Host "     - https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows" -ForegroundColor Yellow
        Write-Host "     - Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor Yellow

        # Break out of the try-catch block
        break
    }

    #----------------------------------------------------------------------------------------------------------------------
    # Try Connect AAD
    try {
        Write-Host " > Check your browser for authentication form ..." -ForegroundColor Yellow

        # Attempt to connect to the Azure account using the specified subscription ID
        $null = Connect-AzAccount -Subscription $SubscriptionID -ErrorAction Stop
    }
    catch {
        # If the connection attempt fails, display an error message with the exception message
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
        # If the access token retrieval fails, display an error message with the exception message
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
        # Construct the URI for the Synapse Workspace API call
        $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)"
        $uri += "/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01"

        # Make the API call to retrieve the Synapse Workspace object
        $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Management_headers

        # Loop through each workspace object returned by the API call
        foreach ($WorkspaceObject in $result.value)
        {
            # Check if the current workspace object matches the specified workspace name
            if ($WorkspaceObject.name -eq $WorkspaceName)
            {
                $SQLOndemandEndpoint = $WorkspaceObject.properties.connectivityEndpoints.sqlOnDemand
                $DevEndpoint = $WorkspaceObject.properties.connectivityEndpoints.dev    

                # If the workspace is a Synapse workspace, set the appropriate endpoints
                if ($WorkspaceObject.properties.extraProperties.WorkspaceType -eq "Normal") {
                    $SQLEndpoint = $WorkspaceObject.properties.connectivityEndpoints.sql
                    $isSynapseWorkspace = $true
                }

                # If the workspace is a former SQL DW, set the appropriate endpoint
                if ($WorkspaceObject.properties.extraProperties.WorkspaceType -eq "Connected") {
                    $SQLEndpoint = "$WorkspaceName.database.windows.net"
                }
                
                break
            }
        }

        # If a DevEndpoint was found, output the endpoints
        if ($null -ne $DevEndpoint) 
        {
            Write-Host "     - SQLEndpoint: ($($SQLEndpoint))"
            Write-Host "     - SQLOndemandEndpoint: ($($SQLOndemandEndpoint))"
            Write-Host "     - DevEndpoint: ($($DevEndpoint))"
        }
        else #former SQL DW
        {
            
            $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)"
            $uri += "/providers/Microsoft.SQL/servers?api-version=2022-05-01-preview"

            $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Management_headers

            foreach ($SQLObject in $result.value)
            {
                # Check if the current SQL object matches the specified workspace name
                if ($SQLObject.name -eq $WorkspaceName)
                {
                    # Set the SQL endpoint
                    $SQLEndpoint = "$WorkspaceName.database.windows.net"
                    Write-Host "      - SQLEndpoint: ($($SQLEndpoint))"
                    break
                }
            }
        }
        Write-Host "   - SUCESS:: Connection Management ENDPOINT"  -ForegroundColor Green        
    }
    catch {
        # Handle any errors that occur during the API calls
        Write-Host "   - ERROR:: TEST Management ENDPOINT" -ForegroundColor Red
        Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red

        if ($_.Exception.Response.StatusCode -eq "Forbidden") 
        {
            [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
            [void]$Summary.AppendLine(">> - ERROR:: Calling management endpoint (management.azure.com) on Port 443 failed")
            [void]$Summary.AppendLine(">>   - You do not have permission to reach management.azure.com API")
            [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
            [void]$Summary.AppendLine("")
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
            [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
            [void]$Summary.AppendLine(">> - ERROR:: Calling Synapse DEV API ($($DevEndpoint)) on Port 443 failed")
            [void]$Summary.AppendLine(">>   - You do not have permission to reach Synapse DEV API ($($DevEndpoint))")
            [void]$Summary.AppendLine(">>----------------------------------------------------------------------------")
            [void]$Summary.AppendLine("")
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
    if ($null -eq $SQLEndpoint)
    {
        $SQLEndpoint = "$($WorkspaceName).sql.azuresynapse.net"
    }

    Write-Host "  -Testing SQL connection ($($SQLEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray

    if ($null -ne $SQLEndpoint)
    {
        TestSQLConnection `
            -ServerName $SQLEndpoint `
            -DatabaseName "master" `
            -SQLConnectionTimeout $SQLConnectionTimeout `
            -SQLQueryTimeout $SQLQueryTimeout `
            -SQL_token $SQL_token
    }

    #----------------------------------------------------------------------------------------------------------------------
    #Testing SQL Ondemand connection
    $SQLOndemandEndpoint = "$($WorkspaceName)-ondemand.sql.azuresynapse.net"
    Write-Host "  ----------------------------------------------------------------------------"
    Write-Host "  -Testing SQL Ondemand connection ($($SQLOndemandEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray

    if ($null -ne $SQLOndemandEndpoint) 
    {
        TestSQLConnection `
            -ServerName $SQLOndemandEndpoint `
            -DatabaseName "master" `
            -SQLConnectionTimeout $SQLConnectionTimeout `
            -SQLQueryTimeout $SQLQueryTimeout `
            -SQL_token $SQL_token
    }

    #endregion TEST API CALLs
}


####################################################################################################################################################
# Summary
####################################################################################################################################################
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Summary " -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

Write-Host $Summary.ToString() -ForegroundColor Cyan

####################################################################################################################################################
# Just a note
Write-Host "   ----------------------------------------------------------------------------"-ForegroundColor Cyan
Write-Host "   NOTE on differences for Dedicated pool endpoint"-ForegroundColor Cyan
Write-Host "   ----------------------------------------------------------------------------"-ForegroundColor Cyan
Write-Host "   SYNAPSE use endpoints below:"-ForegroundColor Cyan
Write-Host "    - XXXXXX.sql.azuresynapse.net <--" -ForegroundColor Yellow
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"-ForegroundColor Cyan
Write-Host "    - XXXXXX.dev.azuresynapse.net"-ForegroundColor Cyan
Write-Host ""
Write-Host "   FORMER SQL DW + SYNAPSE WORKSPACE use endpoints below:"-ForegroundColor Cyan
Write-Host "    - XXXXXX.database.windows.net  <--" -ForegroundColor Yellow
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"-ForegroundColor Cyan
Write-Host "    - XXXXXX.dev.azuresynapse.net"-ForegroundColor Cyan


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
 
