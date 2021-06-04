<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-06-04

.SYNOPSIS   
   TEST SYNAPSE ENDPOINTS AND PORTS NEEDED

.DESCRIPTION
    
#> 
using namespace System.Net

Clear-Host
####################################################

$WorkspaceName = "FonsecanetSynapse"

####################################################
#ENDPOINTS
$SynapseSQLEndpoint = "$($WorkspaceName).sql.azuresynapse.net"
$SynapseServelessEndpoint = "$($WorkspaceName)-ondemand.sql.azuresynapse.net"
$SynapseDevEndpoint = "$($WorkspaceName).dev.azuresynapse.net"
$SynapseDatabaseEndpoint = "$($WorkspaceName).database.windows.net"
$SynapseStudioEndpoint = "web.azuresynapse.net"

$OpenDNS = "208.67.222.222" #OpenDNS
#$OpenDNS = "8.8.8.8" #GoogleDNS

$TestPortConnectionTimeoutMs = 1000


####################################################


#----------------------------------------------------------------------------------------------------------------------
#https://github.com/Azure/SQL-Connectivity-Checker/blob/master/AzureSQLConnectivityChecker.ps1
function Resolve-DnsName {
    param(
        [Parameter(Position = 0)] $Name,
        [Parameter()] $Server,
        [switch] $CacheOnly,
        [switch] $DnsOnly,
        [switch] $NoHostsFile
    );
    process {
        try {
            if ($Server -ne $null) {
                Write-Host " -Trying to resolve DNS for $($Name) with DNS Server $($Server)" -ForegroundColor DarkGray
            }
            else {
                Write-Host " -Trying to resolve DNS for $($Name) from Customer DNS" -ForegroundColor DarkGray
            }
            
            return @{ IPAddress = [System.Net.DNS]::GetHostAddresses($Name).IPAddressToString };
        }
        catch {
            Write-Host " -Error at Resolve-DnsName: $($_.Exception.Message)" -ForegroundColor REd
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
            $portOpened = $tcpClient.ConnectAsync($remoteHostname, $remotePort).Wait($Timeout)

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





####################################################
# Resolve using current DNS
Write-Host "---------------------------------------------------"
Write-Host "TEST NAME RESOLUTION"

$DNSreturn1 = Resolve-DnsName $SynapseSQLEndpoint 
$DNSreturn2 = Resolve-DnsName $SynapseSQLEndpoint -Server $OpenDNS

$DNSreturn3 = Resolve-DnsName $SynapseServelessEndpoint
$DNSreturn4 = Resolve-DnsName $SynapseServelessEndpoint -Server $OpenDNS

$DNSreturn5 = Resolve-DnsName $SynapseDevEndpoint
$DNSreturn6 = Resolve-DnsName $SynapseDevEndpoint -Server $OpenDNS

$DNSreturn7 = Resolve-DnsName $SynapseDatabaseEndpoint
$DNSreturn8 = Resolve-DnsName $SynapseDatabaseEndpoint -Server $OpenDNS

$DNSreturn9 = Resolve-DnsName $SynapseStudioEndpoint
$DNSreturn10 = Resolve-DnsName $SynapseStudioEndpoint -Server $OpenDNS


Write-Host "---------------------------------------------------"
if ($DNSreturn1.IPAddress -eq $DNSreturn2.IPAddress)
    {Write-Host "  > DNS for ($($SynapseSQLEndpoint)) / CX:($($DNSreturn1.IPAddress)) / OpenDNS($($DNSreturn2.IPAddress)) -> EQUAL" -ForegroundColor Green }
else
    {Write-Host "  > DNS for ($($SynapseSQLEndpoint)) / CX:($($DNSreturn1.IPAddress)) / OpenDNS($($DNSreturn2.IPAddress)) -> NOT EQUAL" -ForegroundColor Yellow } 

if ($DNSreturn3.IPAddress -eq $DNSreturn4.IPAddress)
    {Write-Host "  > DNS for ($($SynapseServelessEndpoint)) / CX:($($DNSreturn3.IPAddress)) / OpenDNS($($DNSreturn4.IPAddress)) -> EQUAL" -ForegroundColor Green }
else
    {Write-Host "  > DNS for ($($SynapseServelessEndpoint)) / CX:($($DNSreturn3.IPAddress)) / OpenDNS($($DNSreturn4.IPAddress)) -> NOT EQUAL" -ForegroundColor Yellow } 

if ($DNSreturn5.IPAddress -eq $DNSreturn6.IPAddress)
    {Write-Host "  > DNS for ($($SynapseDevEndpoint)) / CX:($($DNSreturn5.IPAddress)) / OpenDNS($($DNSreturn6.IPAddress)) -> EQUAL" -ForegroundColor Green }
else
    {Write-Host "  > DNS for ($($SynapseDevEndpoint)) / CX:($($DNSreturn5.IPAddress)) / OpenDNS($($DNSreturn6.IPAddress)) -> NOT EQUAL" -ForegroundColor Yellow } 

if ($DNSreturn7.IPAddress -eq $DNSreturn8.IPAddress)
    {Write-Host "  > DNS for ($($SynapseDatabaseEndpoint)) / CX:($($DNSreturn7.IPAddress)) / OpenDNS($($DNSreturn8.IPAddress)) -> EQUAL" -ForegroundColor Green }
else
    {Write-Host "  > DNS for ($($SynapseDatabaseEndpoint)) / CX:($($DNSreturn7.IPAddress)) / OpenDNS($($DNSreturn8.IPAddress)) -> NOT EQUAL" -ForegroundColor Yellow } 

if ($DNSreturn9.IPAddress -eq $DNSreturn10.IPAddress)
    {Write-Host "  > DNS for ($($SynapseStudioEndpoint)) / CX:($($DNSreturn9.IPAddress)) / OpenDNS($($DNSreturn10.IPAddress)) -> EQUAL" -ForegroundColor Green }
else
    {Write-Host "  > DNS for ($($SynapseStudioEndpoint)) / CX:($($DNSreturn9.IPAddress)) / OpenDNS($($DNSreturn10.IPAddress)) -> NOT EQUAL" -ForegroundColor Yellow } 


####################################################
# Test Ports
Write-Host "---------------------------------------------------"
Write-Host "TEST PORTS NEEDED"
#1433
$Results1433 = $SynapseSQLEndpoint, $SynapseServelessEndpoint, $SynapseDatabaseEndpoint | Test-Port -Port 1433 -Timeout $TestPortConnectionTimeoutMs

#1443
$Results1443 = $SynapseSQLEndpoint, $SynapseServelessEndpoint | Test-Port -Port 1443 -Timeout $TestPortConnectionTimeoutMs

#443
$Results443 = $SynapseSQLEndpoint, $SynapseServelessEndpoint, $SynapseDevEndpoint, $SynapseStudioEndpoint | Test-Port -Port 443 -Timeout $TestPortConnectionTimeoutMs

Write-Host "  ---------------------------------------------------"
foreach ($result in $Results1433)
{
    if($result.PortOpened -eq $true)
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is OPEN" -ForegroundColor Green }
    else
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is CLOSED" -ForegroundColor Red } 
}
Write-Host "  ---------------------------------------------------"
foreach ($result in $Results1443)
{
    if($result.PortOpened -eq $true)
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is OPEN" -ForegroundColor Green }
    else
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is CLOSED" -ForegroundColor Red } 
}
Write-Host "  ---------------------------------------------------"
foreach ($result in $Results443)
{
    if($result.PortOpened -eq $true)
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is OPEN" -ForegroundColor Green }
    else
    {Write-host "  > Port $($result.RemotePort) for $($result.RemoteHostname) is CLOSED" -ForegroundColor Red } 
}
Write-Host "  ---------------------------------------------------"