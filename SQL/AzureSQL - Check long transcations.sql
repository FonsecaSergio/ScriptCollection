/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

DECLARE @transaction_duration_sec INT = 0

SELECT
    trans.session_id AS [SESSION ID],
    ESes.host_name AS [HOST NAME],
	login_name AS [Login NAME],
    trans.transaction_id AS [TRANSACTION ID],
    tas.name AS [TRANSACTION NAME],
	tas.transaction_begin_time AS [TRANSACTION BEGIN TIME],
	tas.transaction_type,
	tas.transaction_state

	,transaction_type_desc = CASE tas.transaction_type
		WHEN 1 THEN 'Read/write transaction'
		WHEN 2 THEN 'Read-only transaction'
		WHEN 3 THEN 'System transaction'
		WHEN 4 THEN 'Distributed transaction'
	END

	,transaction_state_desc = CASE tas.transaction_state
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

	,dtc_state_desc = CASE tas.dtc_state
		WHEN 1 THEN 'ACTIVE'
		WHEN 2 THEN 'PREPARED'
		WHEN 3 THEN 'COMMITTED'
		WHEN 4 THEN 'ABORTED'
		WHEN 5 THEN 'RECOVERED'
	END

	,transaction_duration_sec = DATEDIFF(SECOND, tas.transaction_begin_time, SYSDATETIME())

FROM sys.dm_tran_active_transactions tas
JOIN sys.dm_tran_session_transactions trans
	ON (trans.transaction_id=tas.transaction_id)
LEFT OUTER JOIN sys.dm_tran_database_transactions tds
	ON (tas.transaction_id = tds.transaction_id )
LEFT OUTER JOIN sys.databases AS DBs
	ON tds.database_id = DBs.database_id
LEFT OUTER JOIN sys.dm_exec_sessions AS ESes
	ON trans.session_id = ESes.session_id
WHERE ESes.session_id IS NOT NULL
AND DATEDIFF(SECOND, tas.transaction_begin_time, SYSDATETIME()) >= @transaction_duration_sec