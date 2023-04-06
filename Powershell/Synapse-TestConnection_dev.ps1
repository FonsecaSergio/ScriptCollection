#Requires -Version 5

<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2023-04-06

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
    - 2022-10-31 - 1433 added again. Still needed in some regions for Synapse Studio
                   - https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall#connect-to-azure-synapse-from-your-own-network
                   - https://github.com/MicrosoftDocs/azure-docs/issues/69090
                 - Added Import-Module DnsClient just in case is not there by default - BUGFIX
                 - When name resolution fails. Test port shows CLOSED
                 - Check if machine is windows before executing. Not tested on Linux or Mac
    - 2023-03-08 - Test AAD Login endpoints ("login.windows.net" / "login.microsoftonline.com" / "secure.aadcdn.microsoftonline-p.com")
    - 2023-04-06 - Code organization
                 - Make API test calls
                 - Improved Parameter request
                 - Requires Powershell 7
#KNOW ISSUES / TO DO
    - Need to improve / test on linux / Mac machines
    - Sign code https://codesigningstore.com/how-to-sign-a-powershell-script
    - Print IPV6 DNS on show results

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
    $SubscriptionID,
    [Parameter(Mandatory = $true, HelpMessage = "Try to connect to Synapse APIs (Will you your AAD auth) - Answer Y or N")]
    [ValidatePattern("^[YN]$")]
    [string]
    $TryToConnect_YorN
)

Clear-Host

####################################################
#LOG VERSIONS
$VERSION = "2023-04-06"
Write-Host ("Current version: " + $VERSION)
Write-Host ("PS version: " + $psVersionTable.PSVersion)
Write-Host ("OS version: " + $psVersionTable.OS)
Write-Host ("PLATFORM version: " + $psVersionTable.Platform)

####################################################
Import-Module DnsClient
Import-Module SqlServer
Import-Module Az.Accounts -MinimumVersion 2.2.0


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

    EndpointTest () {}
    EndpointTest ([Endpoint]$EndpointToBeTested) 
    {
        $this.Endpoint = $EndpointToBeTested
    }

    [void] Resolve_DnsName_CXDNS ()
    {
        try 
        {
            Write-Host " -INFO:: Trying to resolve DNS for $($this.Endpoint.Name) from Customer DNS" -ForegroundColor DarkGray
            $DNSResults = (Resolve-DnsName -Name $this.Endpoint.Name -DnsOnly -Type A -QuickTimeout -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            $this.CXResolvedIP = $DNSResults[0].IPAddress
            $this.CXResolvedCNAME = $DNSResults[0].Name

        }
        catch 
        {
            Write-Host " -ERROR:: Resolve_DnsName_CXDNS: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void] Resolve_DnsName_PublicDNS ([string]$DNSServer)
    {
        try 
        {
            Write-Host " -INFO:: Trying to resolve DNS for $($this.Endpoint.Name) with DNS Server $($DNSServer)" -ForegroundColor DarkGray
            $DNSResults = (Resolve-DnsName -Name $this.Endpoint.Name -DnsOnly -Type A -QuickTimeout -Server $DNSServer  -ErrorAction Stop) | Where-Object {$_.QueryType -eq 'A'}
            $this.PublicIP = $DNSResults[0].IPAddress
            $this.PublicCNAME = $DNSResults[0].Name
        }
        catch 
        {
            Write-Host " -ERROR:: Resolve_DnsName_PublicDNS: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    #https://copdips.com/2019/09/fast-tcp-port-check-in-powershell.html
    [void] Test_Ports ([Int]$Timeout = 1000)
    {
        foreach ($Port in $this.Endpoint.PortsNeeded)
        {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient

                if($this.CXResolvedIP -ne $null) 
                {
                    Write-Host " -INFO:: Testing Port $($this.Endpoint.Name) / IP($($this.CXResolvedIP)):PORT($($Port.Port))" -ForegroundColor DarkGray

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
                if ($_.Exception.InnerException.InnerException -ne $null)
                {
                    if ($_.Exception.InnerException.InnerException.ErrorCode -eq 11001) { #11001 No such host is known                        
                        Write-Host " -Error at Test-Port: ($($this.Endpoint.Name) / $($this.CXResolvedIP) : $($Port.Port)) - $($_.Exception.InnerException.InnerException.Message)" -ForegroundColor REd
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
        Write-Host "   - DNS for ($($this.Endpoint.Name))"
        Write-Host "      - CX DNS:($($this.CXResolvedIP)) / NAME:($($this.CXResolvedCNAME))"

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

        Write-Host "      - Public DNS:($($this.PublicIP)) / NAME:($($this.PublicCNAME))"              

        if ($this.PublicIP -eq $null) 
        { Write-Host "      - INFO:: PUBLIC NAME RESOLUTION DIDN'T WORK - DOES NOT MEAN A PROBLEM - Just could not reach Public DNS ($($DNSPublic)) to compare" -ForegroundColor Yellow }

        if ($_HaveHostsFileEntry)
        {# HAVE HOST FILE ENTRY           
            if ($HostsFileEntry.IP -eq $this.EndPointPublic.IP) 
            { Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE SAME" -ForegroundColor Green }
            else { Write-Host "      - INFO:: VM HOST FILE ENTRY AND PUBLIC DNS ARE NOT SAME" -ForegroundColor Yellow }

            Write-Host "      - INFO:: CHECK HOSTS FILE ENTRY TO CHECK IF USING PRIVATE LINK or PUBLIC ENDPOINT" -ForegroundColor Yellow
        }
        else
        {# DOES NOT HAVE HOST FILE ENTRY
            if ($this.CXResolvedIP -eq $null) 
            { Write-Host "      - ERROR:: CX NAME RESOLUTION DIDN'T WORK" -ForegroundColor Red }
            else {
                if ($this.CXResolvedIP -eq $this.EndPointPublic.IP) 
                { Write-Host "      - INFO:: CX DNS SERVER AND PUBLIC DNS ARE SAME. That is not an issue. Just a notice that they are currently EQUAL" -ForegroundColor Green }
                else { Write-Host "      - INFO:: CX DNS SERVER AND PUBLIC DNS ARE NOT SAME. That is not an issue. Just a notice that they are currently DIFFERENT" -ForegroundColor Yellow }
    
                if ($this.CXResolvedCNAME -like "*.cloudapp.*" -or $this.CXResolvedCNAME -like "*.control.*") 
                { Write-Host "      - INFO:: CX USING PUBLIC ENDPOINT" -ForegroundColor Cyan }
                elseif ($this.CXResolvedCNAME -like "*.privatelink.*") 
                { Write-Host "      - INFO:: CX USING PRIVATE ENDPOINT" -ForegroundColor Yellow }                   
            } 
        }
    }

    [void] PrintTest_Ports ()
    {
        Write-host "    - TESTS FOR ENDPOINT - $($this.Endpoint.Name) - IP ($($this.CXResolvedIP))"

        foreach ($Port in $this.Endpoint.PortsNeeded)
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
        Select-Object -ExpandProperty ServerAddresses -Unique

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
    $EndpointTest.Resolve_DnsName_CXDNS()
    $EndpointTest.Resolve_DnsName_PublicDNS($DNSPublic)
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

try {
    $IESettings = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop

    if ($IESettings.ProxyEnable -eq 0) {
        Write-Host "   - INFO:: NO INTERNET PROXY ON SERVER / BROWSER"
    }
    else {
        Write-Host "   - WARN:: PROXY ENABLED ON SERVER $($IESettings.ProxyServer)" -ForegroundColor Red
        Write-Host "   - WARN:: PROXY EXCEPTIONS $($IESettings.ProxyOverride)" -ForegroundColor Red
    }    
}
catch {
    Write-Host "   - ERROR:: Not able to check Proxy settings" 
    Write-Host "     - $_.Exception"
}


#####################################################################################
Write-Host "  ----------------------------------------------------------------------------"
Write-Host "  SHIR Proxy Settings" 

try {
    $ProxyEvents = Get-EventLog `
        -LogName "Integration Runtime" `
        -InstanceId "26" `
        -Message "Http Proxy is set to*" `
        -Newest 15 `
        -ErrorAction Stop

    $ProxyEvents | Select TimeGenerated, Message
}
catch{
    Write-Host "   - WARN:: NOT A PROBLEM IF NOT Self Hosted IR Machine" -ForegroundColor Yellow
    Write-Host "     - $_.Exception" -ForegroundColor Yellow
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




####################################################
# TEST API CALLs

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "TEST API CALLs" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow

####################################################
#region TestEndpoints

if ($TryToConnect_YorN -eq "Y") {

    $null = Connect-AzAccount -Subscription $SubscriptionID

    $Management_token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
    $Management_headers = @{ Authorization = "Bearer $Management_token" }

    $Dev_token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
    $Dev_headers = @{ Authorization = "Bearer $Dev_token" }

    $SQL_token = (Get-AzAccessToken -Resource "https://database.windows.net").Token


    $WorkspaceObject = $null
    $SQLEndpoint = $null
    $SQLOndemandEndpoint = $null
    $DevEndpoint = $null
    [bool]$isSynapseWorkspace = $false

    try {

        ####################################################################################################################################################
        Write-Host "  ----------------------------------------------------------------------------"
        Write-Host "  -Testing API call to management endpoint (management.azure.com) on Port 443" -ForegroundColor DarkGray
        
        try {
            #https://learn.microsoft.com/en-us/rest/api/synapse/workspaces/list?tabs=HTTP
            #GET https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01

            $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)"
            $uri += "/providers/Microsoft.Synapse/workspaces?api-version=2021-06-01"
        
            Write-Host "   > API CALL ($($uri))"
        
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
            Write-Host "   - ERROR:: TEST Management ENDPOINT"  -ForegroundColor Red
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }


        ####################################################################################################################################################
        #Testing SQL connection
        try {
            if ($SQLEndpoint -ne $null) {
                Write-Host "  ----------------------------------------------------------------------------"
                Write-Host "  -Testing SQL connection ($($SQLEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray
                $result = Invoke-Sqlcmd -ServerInstance $SQLEndpoint -Database master -AccessToken $SQL_token -query 'select TOP 1 connection_id, GETUTCDATE() as DATE from sys.dm_exec_connections where session_id = @@SPID' -ErrorAction Stop
                if (!$result.HasErrors)
                {
                    Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))" -ForegroundColor Green
                }       
            }else {
                Write-Host "   - ERROR:: CANNOT TEST SQL connection"  -ForegroundColor Red
            }        
        }
        catch {
            Write-Host "   - ERROR:: TEST SQL ENDPOINT"  -ForegroundColor Red
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }


        ####################################################################################################################################################
        #Testing SQL Ondemand connection
        try {
            if ($SQLOndemandEndpoint -ne $null) {
                Write-Host "  ----------------------------------------------------------------------------"
                Write-Host "  -Testing SQL Ondemand connection ($($SQLOndemandEndpoint)) / [MASTER] DB on Port 1433" -ForegroundColor DarkGray
                $result = Invoke-Sqlcmd -ServerInstance $SQLOndemandEndpoint -Database master -AccessToken $SQL_token -query 'select TOP 1 connection_id, GETUTCDATE() as DATE from sys.dm_exec_connections where session_id = @@SPID' -ErrorAction Stop
                if (!$result.HasErrors)
                {
                    Write-Host "   - SUCESS:: Connection connection_id($($result.connection_id)) / UTC date($($result.DATE))"  -ForegroundColor Green
                }       
            }else {
                if ($isSynapseWorkspace) {
                    Write-Host "   - ERROR:: CANNOT TEST SQL Ondemand connection"  -ForegroundColor Red
                }
                
            }          
        }
        catch {
            Write-Host "   - ERROR:: TEST SQL ONDEMAND ENDPOINT"  -ForegroundColor Red
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }

        ####################################################################################################################################################
        #Testing SQL DEV API
        try 
        {
            if ($DevEndpoint -ne $null) 
            {
                Write-Host "  ----------------------------------------------------------------------------"
                Write-Host "  -Testing SQL DEV API ($($DevEndpoint)) on Port 443" -ForegroundColor DarkGray

                #https://learn.microsoft.com/en-us/rest/api/synapse/data-plane/workspace/get?tabs=HTTP
                #GET {endpoint}/workspace?api-version=2020-12-01         
                
                    $uri = "$($DevEndpoint)/workspace?api-version=2020-12-01"
            
                    Write-Host "   > API CALL ($($uri))"
            
                    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $Dev_headers
                    Write-Host "   - SUCESS:: Connection DEV ENDPOINT"  -ForegroundColor Green
                        
            }
            else {
                if ($isSynapseWorkspace) {
                    Write-Host "   - ERROR:: CANNOT TEST SQL DEV API connection"  -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "   - ERROR:: TEST DEV ENDPOINT"  -ForegroundColor Red
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }
    

        ####################################################################################################################################################
        <# NOT WORKING YET
        try 
        {
            if ($SQLOndemandEndpoint -ne $null) 
            {
                Write-Host "  ----------------------------------------------------------------------------"
                Write-Host "  -Testing SQL ONDEMAND API ($($DevEndpoint)) on Port 443" -ForegroundColor DarkGray

                #NO DOCUMENTATION
                #https://XXXXXXX-ondemand.sql.azuresynapse.net/databases/master/query?api-version=2018-08-01-preview&application=listSqlOnDemandDatabases&topRows=5000&queryTimeoutInMinutes=59&allResultSets=true
                #https://<workspace-name>-ondemand.sql.azuresynapse.net/list
                
                    $uri = "https://$($WorkspaceName)-ondemand.sql.azuresynapse.net/list"
            
                    $Headers = $Dev_headers


                    Write-Host "   > API CALL ($($uri))"
            
                    $result = Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $Dev_headers
                    Write-Host "   - SUCESS:: Connection SQL ONDEMAND API"  -ForegroundColor Green
                        
            }
            else {
                if ($isSynapseWorkspace) {
                    Write-Host "   - ERROR:: CANNOT TEST SQL ONDEMAND API connection"  -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "   - ERROR:: TEST SQL ONDEMAND API"  -ForegroundColor Red
            Write-Host "     - $($_.Exception.Message)" -ForegroundColor Red
        }

        #>


    }
    catch {
        Write-Host "   - ERROR::"  -ForegroundColor Red
        Write-Host "     - $_.Exception" -ForegroundColor Red
        Write-Host "     - $_.Exception.Message" -ForegroundColor Red
    }
}else {
    Write-Host "   - INFO:: NO API REQUESTS MADE AS REQUESTED ON PARAMETER TryToConnect_YorN"  -ForegroundColor Yellow
}




Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   NOTE on differences for Dedicated pool endpoint"
Write-Host "   ----------------------------------------------------------------------------"
Write-Host "   SYNAPSE use endpoints below:"
Write-Host "    - XXXXXX.sql.azuresynapse.net <--"
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"
Write-Host ""
Write-Host "   FORMER SQL DW + SYNAPSE WORKSPACE use endpoints below:"
Write-Host "    - XXXXXX.database.windows.net  <--"
Write-Host "    - XXXXXX-ondemand.sql.azuresynapse.net"
Write-Host "    - XXXXXX.dev.azuresynapse.net"


Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "END OF SCRIPT" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Yellow
 
