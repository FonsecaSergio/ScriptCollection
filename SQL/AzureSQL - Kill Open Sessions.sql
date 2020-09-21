/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-09-17
************************************************/

--ALTER DATABASE Sandbox
--SET SINGLE_USER
--WITH ROLLBACK IMMEDIATE;
GO
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL += CONCAT('KILL ', session_id, ' /*', login_name, ' / ' ,host_name ,'*/',  CHAR(10) )
FROM sys.dm_exec_sessions 
WHERE 
	session_id != @@SPID --Filter your session ID
	and is_user_process = 1 --Only User Process
	and login_name not like '##%' -- Filter system logins like ##MS_InstanceCertificate##
	and database_id = DB_ID()

PRINT @SQL

--EXEC (@SQL)

