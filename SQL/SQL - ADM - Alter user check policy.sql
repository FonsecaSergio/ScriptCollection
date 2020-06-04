/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

USE master

GO

SELECT 
    'ALTER LOGIN [' + [name] + '] WITH CHECK_POLICY=ON --, CHECK_EXPIRATION=ON',
	serverproperty('machinename') AS 'Server Name',
    isnull(serverproperty('instancename'),
    serverproperty('machinename')) AS 'Instance Name', 
    [name] AS Login_name, [is_policy_checked], [is_expiration_checked] 
FROM master.sys.sql_logins 
WHERE 
      ( [is_policy_checked] = 0 OR [is_expiration_checked] = 0 ) 
      AND name NOT LIKE '##MS_%';

GO

ALTER LOGIN [sa] WITH CHECK_POLICY=ON --, CHECK_EXPIRATION=ON	SEFONSECNOTE	SEFONSECNOTE	sa	1	0
ALTER LOGIN [TESTE123] WITH CHECK_POLICY=ON --, CHECK_EXPIRATION=ON	SEFONSECNOTE	SEFONSECNOTE	TESTE123	0	0
