[string]$objectIdOrAppId = "70f02567-10f4-4def-8a46-07c9d1b267c2"

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