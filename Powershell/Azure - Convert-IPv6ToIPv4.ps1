<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2024-04-26

.SYNOPSIS
    This script converts an IPv6 address to an IPv4 address.
   
.DESCRIPTION
    This script takes an IPv6 address as input and converts it to an IPv4 address. 
    It assumes that the IPv6 address is an IPv4-mapped address, which means that the last 32 bits of the IPv6 address represent an IPv4 address.
    The script extracts the last 32 bits of the IPv6 address, converts them to binary, and then converts them to an IPv4 address.
 
    # Example usage:
    $IPv6Address = "fd40:c286:12:9fbc:7412:200:ade:85bc"
    $IPv4Address = Convert-IPv6ToIPv4 -ipv6 $IPv6Address
    Write-Host "The IPv4 address is: $IPv4Address"

    The IPv4 address is: 10.222.133.188

    # Example usage:
    $IPv6Address = "fd40:30ef:12:250c:6f12:100:a00:105"
    $IPv4Address = Convert-IPv6ToIPv4 -ipv6 $IPv6Address
    Write-Host "The IPv4 address is: $IPv4Address"

    The IPv4 address is: 10.0.1.5

    * Created this script based on idea from: https://ipworld.info/ipv6-to-ipv4/fd40:c286:12:9fbc:7412:200:ade:85bc
    * Not sure if same logic is used in the website, but it was a good reference to start.


.PARAMETER ipv6
    The IPv6 address to convert to IPv4.
       
#> 
function Convert-IPv6ToIPv4 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ipv6
    )

    # Initialize IPv4 variable
    $ipv4 = $null

    # Extract the last 32 bits of the IPv6 address (assuming it's an IPv4-mapped address)
    $ipv6Parts = $ipv6 -split ":"
    $lastGroup = $ipv6Parts[-1]
    $secondLastGroup = $ipv6Parts[-2]

    # Convert hex groups to binary strings
    $binaryLastGroup = [Convert]::ToString([Convert]::ToInt32($lastGroup, 16), 2).PadLeft(16, '0')
    $binarySecondLastGroup = [Convert]::ToString([Convert]::ToInt32($secondLastGroup, 16), 2).PadLeft(16, '0')

    # Combine binary strings and convert to IPv4 parts
    $binaryIPv4 = $binarySecondLastGroup + $binaryLastGroup
    $ipv4Parts = @()
    for ($i = 0; $i -lt 32; $i += 8) {
        $ipv4Parts += [Convert]::ToInt32($binaryIPv4.Substring($i, 8), 2)
    }

    # Join the parts to form the final IPv4 address
    $ipv4 = $ipv4Parts -join "."

    return $ipv4
}

