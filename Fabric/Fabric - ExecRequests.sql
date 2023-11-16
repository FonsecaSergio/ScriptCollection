SELECT 
exec_req.session_id AS session_id,
DB_NAME(exec_req.database_id) AS [database],
exec_con.connect_time,
exec_ses.program_name,
exec_con.connection_id,
exec_req.start_time,
exec_req.dist_statement_id,
exec_req.query_hash,
exec_req.command,
most_recent_sql_command.text,
exec_req.total_elapsed_time,
exec_req.blocking_session_id,
exec_req.wait_time,
exec_req.wait_resource,
exec_req.open_transaction_count,
exec_req.status,
exec_ses.login_name,
exec_ses.nt_domain,
exec_ses.nt_user_name,
exec_ses.original_login_name
FROM sys.dm_exec_requests exec_req 
JOIN sys.dm_exec_connections exec_con ON exec_req.session_id = exec_con.session_id 
JOIN sys.dm_exec_sessions exec_ses ON (exec_req.session_id = exec_ses.session_id) AND exec_req.session_id <> @@SPID AND LEN(exec_ses.host_name) = 0
CROSS APPLY sys.dm_exec_sql_text(exec_req.sql_handle) AS most_recent_sql_command
WHERE DB_NAME(exec_req.database_id) = DB_NAME()