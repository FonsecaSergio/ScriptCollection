/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
conditions contained within the Premier Customer Services Description.

*/

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CAPTURA CUSTOMIZADA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [MASTER]

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AdHoc_Analisys')
    DROP EVENT SESSION [AdHoc_Analisys] ON SERVER
GO

CREATE EVENT SESSION [AdHoc_Analisys] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.session_id,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'C:\TEMP\AdHoc_Analisys.xel',max_rollover_files=(10))
WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Para capturar algo como do exemplo abaixo somente usando o evento [sp_statement_completed]

Declare @P1 int;
Exec sp_prepare @P1 output, 
    N'@P1 nvarchar(128), @P2 nvarchar(100)',
    N'SELECT database_id, name FROM sys.databases WHERE name=@P1 AND state_desc = @P2';
Exec sp_execute @P1, N'tempdb', N'ONLINE';
EXEC sp_unprepare @P1;

*/
USE [MASTER]

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AdHoc_Analisys_Complex')
    DROP EVENT SESSION [AdHoc_Analisys_Complex] ON SERVER
GO

CREATE EVENT SESSION [AdHoc_Analisys_Complex] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.session_id,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'C:\TEMP\AdHoc_Analisys_Complex.xel',max_rollover_files=(10))
WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--PEGANDO COMANDOS DISTINTOS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;WITH AUX_EVENT_FILE as
(
	SELECT object_name, CAST(event_data AS XML) as event_data
	FROM sys.fn_xe_file_target_read_file('C:\TEMP\AdHoc\*.xel', NULL, NULL, NULL)
)
SELECT 
	DISTINCT
	'event_file' as SOURCE
--	,event_data
	,event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name
	,event_data.value('(event/action[@name="session_id"]/value)[1]', 'varchar(MAX)') AS [session_id]
	,event_data.value('(event/action[@name="username"]/value)[1]', 'varchar(MAX)') AS [username]
	,TSQL = COALESCE(
		event_data.value('(event/data[@name="batch_text"]/value)[1]', 'varchar(MAX)')
		,event_data.value('(event/data[@name="statement"]/value)[1]', 'varchar(MAX)')
	)
FROM AUX_EVENT_FILE



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Usando READTRACE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [MASTER]

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='Perf_MS_XEvents')
    DROP EVENT SESSION [Perf_MS_XEvents] ON SERVER
GO

CREATE EVENT SESSION [Perf_MS_XEvents] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
    ACTION(package0.collect_cpu_cycle_time,package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)) 
ADD TARGET package0.event_file(SET filename=N'C:\TEMP\Perf_MS_XEvents.xel',max_file_size=(500),max_rollover_files=(30))
WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--READTRACE importa para DB XELStage
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
"C:\Program Files\Microsoft Corporation\RMLUtils\ReadTrace.exe" -f -T166 -T167 -T168 -T28 -T29 -I"C:\TEMP\AdHoc\Perf_MS_XEvents_*.xel" -Slocalhost -E -dXELStage -o"C:\TEMP\BreakOut"