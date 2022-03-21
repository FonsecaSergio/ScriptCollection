/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2022-03-21
- Queries to monitor TEMPDB usage on Synapse
************************************************/

-- Monitor tempdb per Database
SELECT  
	Tempdb_Space_Allocated_MB = CONVERT(numeric(25,2),
		(
			SUM((ssu.user_objects_alloc_page_count * 8)) + 
		    SUM((ssu.internal_objects_alloc_page_count * 8))
		) / 1024.0)
FROM sys.dm_pdw_nodes_db_session_space_usage AS ssu 
WHERE DB_NAME(ssu.database_id) = 'tempdb' 

-- Monitor tempdb per Node Id
SELECT  
	 ssu.pdw_node_id
	,Tempdb_Space_Allocated_MB = CONVERT(numeric(25,2),
		(
			SUM((ssu.user_objects_alloc_page_count * 8)) + 
		    SUM((ssu.internal_objects_alloc_page_count * 8))
		) / 1024.0)
FROM sys.dm_pdw_nodes_db_session_space_usage AS ssu 
WHERE DB_NAME(ssu.database_id) = 'tempdb' 
GROUP BY ssu.pdw_node_id
ORDER BY ssu.pdw_node_id


-- Monitor tempdb by request ID
   -- * Queries bigger than 1 min

SELECT
	exr.request_id
	,exr.session_id
	,[Request Command] = exr.command
	,exr.[label]
	,exr.[status]
	,exr.[submit_time]
	,exr.[start_time]
	,exr.[end_time]
	,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[submit_time],exr.[start_time]) / 1000.0)
	,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[start_time]) / 1000.0)
	,Request_execution_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[end_time]) / 1000.0)
	,Total_Elapsed_time_sec = CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0)
	,Total_Elapsed_time_min = CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0 / 60 )	
	,[LoginName] = exs.login_name
	,[MemoryUsage (in KB)] = SUM((es.memory_usage * 8))
	,[Space Allocated For User Objects (in MB)] = CONVERT(numeric(25,2),SUM((ssu.user_objects_alloc_page_count * 8)) / 1024.0)
	,[Space Allocated For Internal Objects (in MB)] = CONVERT(numeric(25,2),SUM((ssu.internal_objects_alloc_page_count * 8)) / 1024.0)
	,[RowCount] = SUM(es.row_count)
FROM sys.dm_pdw_nodes_db_session_space_usage AS ssu
INNER JOIN sys.dm_pdw_nodes_exec_sessions AS es ON ssu.session_id = es.session_id AND ssu.pdw_node_id = es.pdw_node_id
INNER JOIN sys.dm_pdw_nodes_exec_connections AS er ON ssu.session_id = er.session_id AND ssu.pdw_node_id = er.pdw_node_id
INNER JOIN (
	SELECT
		sr.request_id,
		sr.step_index,
		(CASE WHEN (sr.distribution_id = -1 ) THEN (SELECT pdw_node_id FROM sys.dm_pdw_nodes WHERE type = 'CONTROL') ELSE d.pdw_node_id END) AS pdw_node_id,
		sr.distribution_id,
		sr.status,
		sr.error_id,
		sr.start_time,
		sr.end_time,
		sr.total_elapsed_time,
		sr.row_count,
		sr.spid,
		sr.command
	FROM
	sys.pdw_distributions AS d
	RIGHT JOIN sys.dm_pdw_sql_requests AS sr ON d.distribution_id = sr.distribution_id
) AS sr ON ssu.session_id = sr.spid AND ssu.pdw_node_id = sr.pdw_node_id
LEFT JOIN sys.dm_pdw_exec_requests exr on exr.request_id = sr.request_id
    LEFT JOIN sys.dm_pdw_exec_sessions exs on exr.session_id = exs.session_id
WHERE 
	DB_NAME(ssu.database_id) = 'tempdb'
	AND es.session_id <> @@SPID
	AND es.login_name <> 'sa'
	AND exs.login_name <> 'System'
	AND es.is_user_process = 1
	AND (exr.[total_Elapsed_time] / 1000.0 / 60) > 1 /*Bigger than 1 min*/
	AND isnull(exr.[label], '') <> 'TEMPDBMONITOR'
GROUP BY
	exr.request_id
	,exr.session_id
	,exr.command
	,exr.[label]
	,exr.[status]
	,exr.[submit_time]
	,exr.[start_time]
	,exr.[end_time]
	,CONVERT(numeric(25,3),DATEDIFF(ms,exr.[submit_time],exr.[start_time]) / 1000.0)
	,CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[start_time]) / 1000.0)
	,CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[end_time]) / 1000.0)
	,CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0)
	,CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0 / 60 )	
	,exs.login_name
HAVING 
	(SUM((ssu.user_objects_alloc_page_count * 8)) > 64 
	or SUM((ssu.internal_objects_alloc_page_count * 8)) > 64)
ORDER BY exr.request_id
OPTION (LABEL = 'TEMPDBMONITOR')



-- Monitor tempdb, by distribution
   -- * Queries bigger than 1 min
SELECT
	exr.request_id
	,exr.session_id
	,[Step_session_id] = ssu.session_id
	,ssu.pdw_node_id
	,sr.distribution_id
	,sr.step_index
	,[Request Command] = exr.command
	,[Step Command] = sr.command
	,exr.[label]
	,[Step status] = sr.[status]
	,sr.total_elapsed_time
	,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[submit_time],exr.[start_time]) / 1000.0)
	,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[start_time]) / 1000.0)
	,Request_execution_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,exr.[end_compile_time],exr.[end_time]) / 1000.0)
	,Total_Elapsed_time_sec = CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0)
	,Total_Elapsed_time_min = CONVERT(numeric(25,2),exr.[total_Elapsed_time] / 1000.0 / 60 )	
	,[LoginName] = exs.login_name
	,[MemoryUsage (in MB)] = CONVERT(numeric(25,3),(es.memory_usage * 8 / 1024.0))
	,[Space Allocated For User Objects (in MB)] = CONVERT(numeric(25,3),(ssu.user_objects_alloc_page_count * 8 / 1024.0))
	,[Space Allocated For Internal Objects (in MB)] = CONVERT(numeric(25,3),(ssu.internal_objects_alloc_page_count * 8 / 1024.0))
	,[RowCount] = es.row_count
FROM sys.dm_pdw_nodes_db_session_space_usage AS ssu
INNER JOIN sys.dm_pdw_nodes_exec_sessions AS es ON ssu.session_id = es.session_id AND ssu.pdw_node_id = es.pdw_node_id
INNER JOIN sys.dm_pdw_nodes_exec_connections AS er ON ssu.session_id = er.session_id AND ssu.pdw_node_id = er.pdw_node_id
INNER JOIN (
	SELECT
		sr.request_id,
		sr.step_index,
		(CASE WHEN (sr.distribution_id = -1 ) THEN (SELECT pdw_node_id FROM sys.dm_pdw_nodes WHERE type = 'CONTROL') ELSE d.pdw_node_id END) AS pdw_node_id,
		sr.distribution_id,
		sr.status,
		sr.error_id,
		sr.start_time,
		sr.end_time,
		sr.total_elapsed_time,
		sr.row_count,
		sr.spid,
		sr.command
	FROM
	sys.pdw_distributions AS d
	RIGHT JOIN sys.dm_pdw_sql_requests AS sr ON d.distribution_id = sr.distribution_id
) AS sr ON ssu.session_id = sr.spid AND ssu.pdw_node_id = sr.pdw_node_id
LEFT JOIN sys.dm_pdw_exec_requests exr on exr.request_id = sr.request_id
LEFT JOIN sys.dm_pdw_exec_sessions exs on exr.session_id = exs.session_id
WHERE 
	DB_NAME(ssu.database_id) = 'tempdb'
	AND es.session_id <> @@SPID
	AND es.login_name <> 'sa'
	AND exs.login_name <> 'System'
	AND es.is_user_process = 1
	AND ((ssu.user_objects_alloc_page_count * 8) > 64
		OR (ssu.internal_objects_alloc_page_count * 8) > 64)
	AND (exr.[total_Elapsed_time] / 1000.0 / 60) > 1 /*Bigger than 1 min*/
	AND isnull(exr.[label], '') <> 'TEMPDBMONITOR'
ORDER BY sr.request_id
OPTION (LABEL = 'TEMPDBMONITOR')


