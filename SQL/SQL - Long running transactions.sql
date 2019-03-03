SELECT 
	 stran.session_id
	,atran.transaction_id
	,atran.transaction_begin_time
	,[Duration] = datediff(minute, atran.transaction_begin_time, GETDATE())
	,[Log Records] = dtran.[database_transaction_log_record_count]
	,[Log Bytes_Used] = dtran.[database_transaction_log_bytes_used] 
	,stran.open_transaction_count
	,dtran.database_id
	,[database_name] = DB_NAME(dtran.database_id)
	,[Last T-SQL Text] = stext.[text]
	,[Last Plan] = splan.[query_plan]
	,ses.host_name
	,ses.program_name
	,ses.login_name
	,ses.status
	,req.blocking_session_id
	,req.wait_type
	,req.wait_time
FROM sys.dm_tran_active_transactions atran
INNER JOIN sys.dm_tran_session_transactions stran
	ON atran.transaction_id = stran.transaction_id
INNER JOIN sys.dm_tran_database_transactions dtran 
	ON atran.transaction_id = dtran.transaction_id
LEFT JOIN sys.dm_exec_requests req ON stran.session_id = req.session_id
INNER JOIN sys.dm_exec_sessions ses ON stran.session_id = ses.session_id
INNER JOIN sys.dm_exec_connections con ON stran.session_id = con.session_id
CROSS APPLY sys.dm_exec_sql_text(con.[most_recent_sql_handle]) AS stext
OUTER APPLY sys.dm_exec_query_plan(req.[plan_handle]) AS splan
WHERE 
	datediff(minute, atran.transaction_begin_time, GETDATE()) >= 5 --bigger than 5 minutes
	AND dtran.database_transaction_state != 3 --3 = The transaction has been initialized but has not generated any log records.
ORDER BY [Duration] DESC