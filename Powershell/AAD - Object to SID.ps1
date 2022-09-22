[string]$objectIdOrAppId = "33d3d39b-5cf5-4cb5-8bcd-408950de5361"

[guid]$guid = [System.Guid]::Parse($objectIdOrAppId)

$byteGuid = ""

foreach ($byte in $guid.ToByteArray())
{
    $byteGuid += [System.String]::Format("{0:X2}", $byte)
}

return "0x" + $byteGuid


<#

SID to OBJECTID

SELECT
	DP.name
	,DP.principal_id
	,DP.type
	,DP.type_desc
	,DP.SID
	,OBJECTID = CONVERT(uniqueidentifier, DP.SID)
FROM SYS.database_principals DP
WHERE DP.type IN ('S','X','E')


#>