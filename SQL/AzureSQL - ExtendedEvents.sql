/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-09-21
************************************************/

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'x4565465xxxxx!';

---------------------------------------------------------------------------------------------------------
IF EXISTS
(
	SELECT * FROM sys.database_scoped_credentials 
	WHERE name = 'https://NAMEstorage.blob.core.windows.net/extendedevents'
)
BEGIN
	--DROP DATABASE SCOPED CREDENTIAL [https://NAMEstorage.blob.core.windows.net/extendedevents]
	ALTER DATABASE SCOPED CREDENTIAL [https://NAMEstorage.blob.core.windows.net/extendedevents]
	WITH IDENTITY='SHARED ACCESS SIGNATURE',
	SECRET = 'sp=rwl&st=2018-03-09T16%3A45%3A00Z&se=2024-03-10T1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxWM0%3D&sr=c'
END
ELSE
BEGIN
	CREATE DATABASE SCOPED CREDENTIAL [https://NAMEstorage.blob.core.windows.net/extendedevents]
	WITH IDENTITY='SHARED ACCESS SIGNATURE',
	SECRET = 'sp=rwl&st=2018-03-09T16%3A45%3A00Z&se=2024-03-10T1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxWM0%3D&sr=c'
END
---------------------------------------------------------------------------------------------------------

DROP EVENT SESSION [ExtendedEventsTrace] ON DATABASE 
GO

CREATE EVENT SESSION [ExtendedEventsTrace] ON DATABASE 
ADD EVENT sqlos.wait_completed(
    ACTION(
		sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.database_id,sqlserver.database_name,
		sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),

ADD EVENT sqlserver.rpc_completed(
    ACTION(
		sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.database_id,sqlserver.database_name,
		sqlserver.query_hash,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.rpc_starting(
    ACTION(
		sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.database_id,sqlserver.database_name,
		sqlserver.query_hash,sqlserver.session_id,sqlserver.username)),

ADD EVENT sqlserver.sql_batch_completed(
    ACTION(
		sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.database_id,sqlserver.database_name,
		sqlserver.query_hash,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(
		sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.database_id,sqlserver.database_name,
		sqlserver.query_hash,sqlserver.session_id,sqlserver.username))

ADD TARGET package0.event_file(SET filename=N'https://NAMEstorage.blob.core.windows.net/extendedevents/XETrace.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


