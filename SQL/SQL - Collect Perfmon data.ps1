<#
    .SYNOPSIS
    Collect counters required for DTU Calculator and log as CSV.

    .DESCRIPTION
    Collect counters required for DTU Calculator and log as CSV. 
    Default disk drive parameters is F:. Default log file location is C:\sql-perfmon-log.csv.
    Counters are collected at 1 second intervals for 1 hour or 3600 seconds.
    No support or warranty is supplied or inferred. 
    Use at your own risk.

    .PARAMETER DatabaseName
    The name of the SQL Server database to monitor.

    .INPUTS
    Parameters above.
    
    .OUTPUTS
    None.

    .NOTES
    Version: 1.0
    Creation Date: May 1, 2015
    Author: Justin Henriksen ( http://justinhenriksen.wordpress.com )
    Change: Initial function development
#>

[CmdletBinding()]
param (

    [Parameter(Mandatory = $true)]
    [String]
    $DatabaseName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

cls

Write-Output "Collecting counters..."
Write-Output "Press Ctrl+C to exit."

$counters = @("\Processor(_Total)\% Processor Time", "\LogicalDisk(C:)\Disk Reads/sec", "\LogicalDisk(C:)\Disk Writes/sec", 
    "\LogicalDisk(C:)\Disk Read Bytes/sec", "\LogicalDisk(C:)\Disk Write Bytes/sec", "\SQLServer:Databases($DatabaseName)\Log Bytes Flushed/sec") 

Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples 3600 | 
    Export-Counter -FileFormat csv -Path "C:\TEMP\sql-perfmon\sql-perfmon-log.csv" -Force