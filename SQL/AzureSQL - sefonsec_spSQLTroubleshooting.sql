/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

DROP PROCEDURE IF EXISTS #spSQLTroubleshooting
GO

CREATE PROCEDURE #spSQLTroubleshooting
(
	 @DEBUG bit = 1
	,@only_user_process bit = 1
	,@only_active_requests bit = 1
	,@ignoreAzureSQLDBprocesses bit = 0
	,@ignoreThisSPID bit = 1
	,@spid int = 0
	,@troubleshooting_connection bit = 1
	,@troubleshooting_sessionperfcounters bit = 1
	,@troubleshooting_transaction bit = 1
	,@troubleshooting_requests bit = 1
)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	--SET STATISTICS TIME,IO ON

	/**********************************************************************************/
	SELECT * INTO #TEMP_dm_exec_connections 
	FROM sys.dm_exec_connections

	/**********************************************************************************/
	SELECT 
		 S.*
		,transaction_isolation_level_desc = CASE S.transaction_isolation_level
			WHEN 0 THEN 'Unspecified'
			WHEN 1 THEN 'ReadUncomitted'
			WHEN 2 THEN 'ReadCommitted'
			WHEN 3 THEN 'Repeatable'
			WHEN 4 THEN 'Serializable'
			WHEN 5 THEN 'Snapshot'
		END

	INTO #TEMP_dm_exec_sessions 
	FROM sys.dm_exec_sessions S

	/**********************************************************************************/
	SELECT 
		 R.*
		,request_duration_sec = DATEDIFF(SECOND, R.start_time, SYSDATETIME())

		,statement_text = 
			SUBSTRING(T.text, (R.statement_start_offset/2)+1,   
			((CASE R.statement_end_offset  
			WHEN -1 THEN DATALENGTH(T.text)  
			ELSE R.statement_end_offset  
			END - R.statement_start_offset)/2) + 1)  
		,batch_text = T.[text]
		,T.objectid
		,[object_name] = object_name(T.objectid)


	INTO #TEMP_dm_exec_requests 
	FROM sys.dm_exec_requests R
	OUTER APPLY sys.dm_exec_sql_text (R.sql_handle) T

	/**********************************************************************************/
	SELECT AT.*
		,transaction_type_desc = CASE AT.transaction_type
			WHEN 1 THEN 'Read/write transaction'
			WHEN 2 THEN 'Read-only transaction'
			WHEN 3 THEN 'System transaction'
			WHEN 4 THEN 'Distributed transaction'
		END

		,transaction_state_desc = CASE AT.transaction_state
			WHEN 0 THEN 'The transaction has not been completely initialized yet'
			WHEN 1 THEN 'The transaction has been initialized but has not started'
			WHEN 2 THEN 'The transaction is active'
			WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions'
			WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place'
			WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
			WHEN 6 THEN 'The transaction has been committed'
			WHEN 7 THEN 'The transaction is being rolled back'
			WHEN 8 THEN 'The transaction has been rolled back'
		END

		,dtc_state_desc = CASE AT.dtc_state
			WHEN 1 THEN 'ACTIVE'
			WHEN 2 THEN 'PREPARED'
			WHEN 3 THEN 'COMMITTED'
			WHEN 4 THEN 'ABORTED'
			WHEN 5 THEN 'RECOVERED'
		END

		,transaction_duration_sec = DATEDIFF(SECOND, AT.transaction_begin_time, SYSDATETIME())
		
	INTO #TEMP_dm_tran_active_transactions
	FROM sys.dm_tran_active_transactions AT

	/**********************************************************************************/
	SELECT * INTO #TEMP_dm_tran_session_transactions
	FROM sys.dm_tran_session_transactions

	/**********************************************************************************/
	SELECT 
		* 
		,transaction_type_desc = CASE database_transaction_type
			WHEN 1 THEN 'Read/write transaction'
			WHEN 2 THEN 'Read-only transaction'
			WHEN 3 THEN 'System transaction'
			WHEN 4 THEN 'Distributed transaction'
		END
		,transaction_state_desc = CASE database_transaction_state
			WHEN 0 THEN 'The transaction has not been completely initialized yet'
			WHEN 1 THEN 'The transaction has been initialized but has not started'
			WHEN 2 THEN 'The transaction is active'
			WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions'
			WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place'
			WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
			WHEN 6 THEN 'The transaction has been committed'
			WHEN 7 THEN 'The transaction is being rolled back'
			WHEN 8 THEN 'The transaction has been rolled back'
		END
	INTO #TEMP_dm_tran_database_transactions
	FROM sys.dm_tran_database_transactions




	/**********************************************************************************/
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_exec_connections ON #TEMP_dm_exec_connections (session_id)
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_exec_sessions ON #TEMP_dm_exec_sessions  (session_id)
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_exec_requests ON #TEMP_dm_exec_requests (session_id)
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_tran_active_transactions ON #TEMP_dm_tran_active_transactions (transaction_id)
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_tran_session_transactions ON #TEMP_dm_tran_session_transactions (session_id)
	--CREATE CLUSTERED INDEX #CIX_TEMP_dm_tran_database_transactions ON #TEMP_dm_tran_database_transactions (transaction_id,database_id)
	/**********************************************************************************/

	




	/**********************************************************************************/
	DECLARE @SQL_QUERY as NVARCHAR(MAX) = ''

	SET @SQL_QUERY += '' + CHAR(10)
	SET @SQL_QUERY += 'SELECT' + CHAR(10)
	
	/**********************************************************************************/
	SET @SQL_QUERY += '	 C.session_id' + CHAR(10)
	SET @SQL_QUERY += '	,[server_name] = '''+ @@SERVERNAME + '''' + CHAR(10)
	SET @SQL_QUERY += '	,S.database_id' + CHAR(10)
	SET @SQL_QUERY += '	,[database_name] = DB_NAME(S.database_id)' + CHAR(10)
	SET @SQL_QUERY += '	,session_status = S.status' + CHAR(10)

	/**********************************************************************************/
	/*ConnectionInfo*/
	IF (@troubleshooting_connection = 1)
	BEGIN
		SET @SQL_QUERY += '	,C.connect_time' + CHAR(10)
		SET @SQL_QUERY += '	,S.login_time' + CHAR(10)
		SET @SQL_QUERY += '	,C.net_transport' + CHAR(10)
		SET @SQL_QUERY += '	,C.protocol_type' + CHAR(10)
		SET @SQL_QUERY += '	,C.encrypt_option' + CHAR(10)
		SET @SQL_QUERY += '	,C.auth_scheme' + CHAR(10)
		SET @SQL_QUERY += '	,S.host_name' + CHAR(10)
		SET @SQL_QUERY += '	,C.client_net_address' + CHAR(10)
		SET @SQL_QUERY += '	,C.client_tcp_port' + CHAR(10)
		SET @SQL_QUERY += '	,C.local_tcp_port' + CHAR(10)
		SET @SQL_QUERY += '	,C.local_net_address' + CHAR(10)
		SET @SQL_QUERY += '	,C.connection_id' + CHAR(10)
		SET @SQL_QUERY += '	,C.parent_connection_id' + CHAR(10)
		SET @SQL_QUERY += '	,S.is_user_process' + CHAR(10)
		SET @SQL_QUERY += '	,S.language' + CHAR(10)
		SET @SQL_QUERY += '	,S.date_format' + CHAR(10)
		SET @SQL_QUERY += '	,S.lock_timeout' + CHAR(10)
		SET @SQL_QUERY += '	,S.prev_error' + CHAR(10)

		SET @SQL_QUERY += '	,S.program_name' + CHAR(10)
		SET @SQL_QUERY += '	,S.client_interface_name' + CHAR(10)
		SET @SQL_QUERY += '	,S.login_name' + CHAR(10)
		SET @SQL_QUERY += '	,S.original_login_name' + CHAR(10)
		SET @SQL_QUERY += '	,S.nt_domain' + CHAR(10)
		SET @SQL_QUERY += '	,S.nt_user_name' + CHAR(10)
		SET @SQL_QUERY += '	,S.authenticating_database_id' + CHAR(10)
		SET @SQL_QUERY += '	,[authenticating_database_name] = DB_NAME(S.authenticating_database_id)' + CHAR(10)

		SET @SQL_QUERY += '	,S.last_request_start_time' + CHAR(10)
		SET @SQL_QUERY += '	,S.last_request_end_time' + CHAR(10)

	END

	
	/**********************************************************************************/
	/*SESSION PERF*/
	IF (@troubleshooting_sessionperfcounters = 1)
	BEGIN
		SET @SQL_QUERY += '	,session_cpu_time = S.cpu_time' + CHAR(10)
		SET @SQL_QUERY += '	,session_memory_usage = S.memory_usage' + CHAR(10)
		SET @SQL_QUERY += '	,session_num_reads = C.num_reads' + CHAR(10)
		SET @SQL_QUERY += '	,session_num_writes = C.num_writes' + CHAR(10)
		SET @SQL_QUERY += '	,session_total_scheduled_time = S.total_scheduled_time' + CHAR(10)
		SET @SQL_QUERY += '	,session_total_elapsed_time = S.total_elapsed_time' + CHAR(10)
		SET @SQL_QUERY += '	,session_reads = S.reads' + CHAR(10)
		SET @SQL_QUERY += '	,session_writes = S.writes' + CHAR(10)
		SET @SQL_QUERY += '	,session_logical_reads = S.logical_reads' + CHAR(10)
		SET @SQL_QUERY += '	,session_row_count = S.row_count' + CHAR(10)

		SET @SQL_QUERY += '	,request_cpu_time = R.cpu_time' + CHAR(10)
		SET @SQL_QUERY += '	,request_reads = R.reads' + CHAR(10)
		SET @SQL_QUERY += '	,request_writes = R.writes' + CHAR(10)
		SET @SQL_QUERY += '	,request_logical_reads = R.logical_reads' + CHAR(10)
		SET @SQL_QUERY += '	,request_row_count = R.row_count' + CHAR(10)
		SET @SQL_QUERY += '	,request_page_server_reads = R.page_server_reads' + CHAR(10)

	END
	/**********************************************************************************/
	/*TRANSACTION*/
	IF (@troubleshooting_transaction = 1)
	BEGIN
		SET @SQL_QUERY += '	,transaction_id = COALESCE(R.transaction_id,ST.transaction_id)' + CHAR(10)
		SET @SQL_QUERY += '	,AT.name' + CHAR(10)
		SET @SQL_QUERY += '	,AT.transaction_begin_time' + CHAR(10)
		SET @SQL_QUERY += '	,AT.transaction_duration_sec' + CHAR(10)
		SET @SQL_QUERY += '	,S.transaction_isolation_level' + CHAR(10)
		SET @SQL_QUERY += '	,S.transaction_isolation_level_desc' + CHAR(10)
		SET @SQL_QUERY += '	,S.open_transaction_count' + CHAR(10)
		SET @SQL_QUERY += '	,AT.transaction_type' + CHAR(10)
		SET @SQL_QUERY += '	,transaction_type_desc' + CHAR(10)

		SET @SQL_QUERY += '	,transaction_using_tempdb = IIF(
			(SELECT COUNT(*)
			FROM #TEMP_dm_tran_database_transactions AuxDT
			WHERE AuxDT.database_id = 2 /*tempdb*/
			AND AuxDT.database_transaction_type = 1 /*Read/write transaction*/
			AND AuxDT.transaction_id = COALESCE(R.transaction_id,ST.transaction_id)
			) > 0,1,0)' + CHAR(10)

		SET @SQL_QUERY += '	,AT.transaction_state' + CHAR(10)
		SET @SQL_QUERY += '	,transaction_state_desc' + CHAR(10)

--		SET @SQL_QUERY += '	,AT.transaction_status' + CHAR(10)
--		SET @SQL_QUERY += '	,AT.transaction_status2' + CHAR(10)

		--SET @SQL_QUERY += '	,AT.dtc_state' + CHAR(10)
		--SET @SQL_QUERY += '	,dtc_state_desc' + CHAR(10)
		--SET @SQL_QUERY += '	,AT.dtc_status' + CHAR(10)
		--SET @SQL_QUERY += '	,AT.dtc_isolation_level' + CHAR(10)
		--SET @SQL_QUERY += '	,AT.transaction_uow' + CHAR(10)
		--SET @SQL_QUERY += '	,AT.filestream_transaction_id' + CHAR(10)
	END


	/**********************************************************************************/
	/*REQUESTS*/

	IF (@troubleshooting_requests = 1)
	BEGIN
		SET @SQL_QUERY += '	,request_start_time = R.start_time' + CHAR(10)
		SET @SQL_QUERY += '	,R.request_duration_sec' + CHAR(10)
		SET @SQL_QUERY += '	,request_status = R.status' + CHAR(10)
		SET @SQL_QUERY += '	,R.command' + CHAR(10)
		SET @SQL_QUERY += '	,R.objectid' + CHAR(10)
		SET @SQL_QUERY += '	,R.object_name' + CHAR(10)

		/**********************************************************************************/
		SET @SQL_QUERY += '	,C.most_recent_sql_handle' + CHAR(10)
		SET @SQL_QUERY += '	,[most_recent_sql_text] = T1.text' + CHAR(10)

		SET @SQL_QUERY += '	,R.query_hash' + CHAR(10)
		SET @SQL_QUERY += '	,R.sql_handle' + CHAR(10)
		SET @SQL_QUERY += '	,R.batch_text' + CHAR(10)
		SET @SQL_QUERY += '	,R.statement_text' + CHAR(10)


		/**********************************************************************************/
		SET @SQL_QUERY += '	,R.plan_handle' + CHAR(10)
		SET @SQL_QUERY += '	,R.query_plan_hash' + CHAR(10)
		SET @SQL_QUERY += '	,batch_query_plan = P.query_plan' + CHAR(10)
		SET @SQL_QUERY += '	,statement_query_plan = CONVERT(XML, P2.query_plan)' + CHAR(10)
		/**********************************************************************************/

		SET @SQL_QUERY += '	,R.wait_type' + CHAR(10)
		SET @SQL_QUERY += '	,R.wait_time' + CHAR(10)
		SET @SQL_QUERY += '	,R.last_wait_type' + CHAR(10)
		SET @SQL_QUERY += '	,R.wait_resource' + CHAR(10)
		SET @SQL_QUERY += '	,R.blocking_session_id' + CHAR(10)

		SET @SQL_QUERY += '	,R.percent_complete' + CHAR(10)
		SET @SQL_QUERY += '	,R.estimated_completion_time' + CHAR(10)
		SET @SQL_QUERY += '	,R.total_elapsed_time' + CHAR(10)
		--SET @SQL_QUERY += '	,R.scheduler_id' + CHAR(10)
		--SET @SQL_QUERY += '	,R.task_address' + CHAR(10)

		--SET @SQL_QUERY += '	,R.open_resultset_count' + CHAR(10)
		--SET @SQL_QUERY += '	,R.text_size' + CHAR(10)
		--SET @SQL_QUERY += '	,R.language' + CHAR(10)
		--SET @SQL_QUERY += '	,R.date_format' + CHAR(10)
		--SET @SQL_QUERY += '	,R.date_first' + CHAR(10)
		--SET @SQL_QUERY += '	,R.lock_timeout' + CHAR(10)
		--SET @SQL_QUERY += '	,R.deadlock_priority' + CHAR(10)


		----SET @SQL_QUERY += '	,R.nest_level' + CHAR(10)
		SET @SQL_QUERY += '	,R.granted_query_memory' + CHAR(10)
		SET @SQL_QUERY += '	,R.executing_managed_code' + CHAR(10)
		--SET @SQL_QUERY += '	,R.group_id' + CHAR(10)
		SET @SQL_QUERY += '	,R.dop' + CHAR(10)
		SET @SQL_QUERY += '	,R.parallel_worker_count' + CHAR(10)
		SET @SQL_QUERY += '	,R.external_script_request_id' + CHAR(10)
		SET @SQL_QUERY += '	,R.is_resumable' + CHAR(10)
		SET @SQL_QUERY += '	,R.page_resource' + CHAR(10)
	END



	SET @SQL_QUERY += 'FROM #TEMP_dm_exec_connections C' + CHAR(10)
	SET @SQL_QUERY += 'LEFT JOIN  #TEMP_dm_exec_sessions S' + CHAR(10)
	SET @SQL_QUERY += '	ON C.session_id = S.session_id' + CHAR(10)

	IF (@only_active_requests = 1)
	BEGIN
		SET @SQL_QUERY += 'INNER JOIN #TEMP_dm_exec_requests R' + CHAR(10)
		SET @SQL_QUERY += '	ON C.session_id = R.session_id' + CHAR(10)
	END
	ELSE
	BEGIN
		SET @SQL_QUERY += 'LEFT JOIN #TEMP_dm_exec_requests R' + CHAR(10)
		SET @SQL_QUERY += '	ON C.session_id = R.session_id' + CHAR(10)

	END

	SET @SQL_QUERY += 'LEFT JOIN #TEMP_dm_tran_session_transactions ST' + CHAR(10)
	SET @SQL_QUERY += '	ON C.session_id = ST.session_id' + CHAR(10)
	SET @SQL_QUERY += 'LEFT JOIN #TEMP_dm_tran_active_transactions AT' + CHAR(10)
	SET @SQL_QUERY += '	ON COALESCE(R.transaction_id,ST.transaction_id) = AT.transaction_id' + CHAR(10)

	SET @SQL_QUERY += 'OUTER APPLY sys.dm_exec_sql_text (C.most_recent_sql_handle) T1' + CHAR(10)
	SET @SQL_QUERY += 'OUTER APPLY sys.dm_exec_query_plan(R.plan_handle) P' + CHAR(10)
	SET @SQL_QUERY += 'OUTER APPLY sys.dm_exec_text_query_plan(R.plan_handle, R.statement_start_offset, R.statement_end_offset) P2' + CHAR(10)


	SET @SQL_QUERY += 'WHERE 1 = 1' + CHAR(10)
	--------------------------------------------------------------------------------------------------------
	IF @only_user_process != 0
	BEGIN
		SET @SQL_QUERY += CONCAT('	AND (S.is_user_process = ',@only_user_process, ')') + CHAR(10)
	END
	--------------------------------------------------------------------------------------------------------
	IF @ignoreAzureSQLDBprocesses != 0
	BEGIN
		SET @SQL_QUERY += '	AND (S.database_id = DB_ID())' + CHAR(10)
	END
	--------------------------------------------------------------------------------------------------------
	IF @spid != 0
	BEGIN
		SET @SQL_QUERY += CONCAT('	AND (C.session_id = ', @spid, ')') + CHAR(10)
	END

	--------------------------------------------------------------------------------------------------------
	IF @ignoreThisSPID = 0
	BEGIN
		SET @SQL_QUERY += '	AND (' + CHAR(10)
		SET @SQL_QUERY += '		(C.session_id != @@SPID) OR ' + CHAR(10)
		SET @SQL_QUERY += CONCAT('		', @spid, ' = @@SPID') + CHAR(10)
		SET @SQL_QUERY += '	)' + CHAR(10)
	END
	--------------------------------------------------------------------------------------------------------


	IF @DEBUG = 1
		PRINT @SQL_QUERY

	EXEC sp_executesql @SQL_QUERY
	--------------------------------------------------------------------------------------------------------
		
GO

EXEC #spSQLTroubleshooting

/*
EXEC #spSQLTroubleshooting 
	 @spid = 0
	,@only_user_process = 1
	,@only_active_requests = 1
	,@ignoreAzureSQLDBprocesses = 0
	,@ignoreThisSPID = 1
	,@troubleshooting_connection = 0
	,@troubleshooting_sessionperfcounters = 0
	,@troubleshooting_transaction = 1
	,@troubleshooting_requests = 1

EXEC #spSQLTroubleshooting @spid = @@SPID

EXEC #spSQLTroubleshooting 
	 @spid = 122
	,@only_user_process = 1
	,@only_active_requests = 0
	,@ignoreAzureSQLDBprocesses = 0
	,@ignoreThisSPID = 1
	,@troubleshooting_connection = 0
	,@troubleshooting_sessionperfcounters = 0
	,@troubleshooting_transaction = 0
	,@troubleshooting_requests = 1
*/