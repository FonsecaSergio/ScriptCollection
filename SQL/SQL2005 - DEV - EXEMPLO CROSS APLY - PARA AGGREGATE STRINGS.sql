SELECT 
	CS.ResourceID, 
	CS.GroupID, 
	CS.Model0, 
	CS.Name0, 
	LEFT (IP.IP_Addresses0, LEN(IP.IP_Addresses0) - 1), 
	SUBSTRING(CS.Name0, 8, 3) AS HOSTCOMP, 
	v_GS_WORKSTATION_STATUS.LastHWScan
FROM v_GS_COMPUTER_SYSTEM AS CS 
--INNER JOIN v_RA_System_IPAddresses AS IP ON CS.ResourceID = IP.ResourceID 
CROSS APPLY (
	SELECT IP_Addresses0 + ', '
	FROM v_RA_System_IPAddresses IPS
	WHERE CS.ResourceID = IPS.ResourceID 
	FOR XML PATH ('')
) IP (IP_Addresses0)
INNER JOIN v_GS_WORKSTATION_STATUS ON CS.ResourceID = v_GS_WORKSTATION_STATUS.ResourceID
