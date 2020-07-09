DROP PROCEDURE IF EXISTS #TEMP_MONITOR
GO

CREATE PROCEDURE #TEMP_MONITOR
(
	@DELAY VARCHAR(10) = '00:00:05'
)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	PRINT SYSDATETIME()

	SELECT 
		 TIME = SYSDATETIME()
		,C.session_id
		,C.client_net_address
		,C.connection_id
		,S.host_name
		,S.program_name
		,S.login_name
		,[transaction_isolation_level] = COALESCE(r.transaction_isolation_level, s.transaction_isolation_level)
		,S.database_id
		,[DB_NAME] = DB_NAME(S.database_id)
		,S.open_transaction_count
		,S.is_user_process
		,[Session_Status] = S.status
		,[Request_Status] = R.status
		,R.blocking_session_id
		,R.wait_type
		,R.wait_time
		,R.wait_resource
		,R.transaction_id
		,R.cpu_time
		,R.total_elapsed_time
		,R.logical_reads
		,R.query_hash
		,R.query_plan_hash
		,text = REPLACE (
					REPLACE (T.text,CHAR(10),' '),
					CHAR(13),' ')
	FROM sys.dm_exec_connections C
	LEFT JOIN sys.dm_exec_sessions S
		ON C.session_id = S.session_id
	LEFT JOIN sys.dm_exec_requests R
		ON C.session_id = R.session_id
	OUTER APPLY sys.dm_exec_sql_text (COALESCE(r.sql_handle, C.most_recent_sql_handle)) T
	WHERE 
		program_name not in ('TdService','MetricsDownloader','BackupService','DmvCollector','Microsoft SQL Server Management Studio - Transact-SQL IntelliSense')
		AND C.session_id != @@SPID
	ORDER BY C.session_id

	WAITFOR DELAY @DELAY
GO

WHILE (1=1)
BEGIN
	EXEC #TEMP_MONITOR
END