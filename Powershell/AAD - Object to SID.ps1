[string]$objectIdOrAppId = "1d0e6f2f-7be2-4113-bd76-42343fb59f66"

[guid]$guid = [System.Guid]::Parse($objectIdOrAppId)

foreach ($byte in $guid.ToByteArray())
{
    $byteGuid += [System.String]::Format("{0:X2}", $byte)
}

Remove-Variable -Name byteGuid

return "0x" + $byteGuid