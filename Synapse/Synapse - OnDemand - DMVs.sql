/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-11-09
************************************************/
SELECT * FROM sys.dm_exec_connections
SELECT * FROM sys.dm_exec_sessions
SELECT * FROM sys.dm_exec_requests
SELECT * FROM sys.dm_exec_requests_history ORDER BY start_time desc


SELECT 
    'Running' as [Status],
    Transaction_id as [Request ID],
    'SQL On-demand' as [SQL Resource],
    s.login_name as [Submitter],
    s.Session_Id as [Session ID],
    req.start_time as [Submit time],
    req.start_time as [Start time],
    'N/A' as [End time],
    req.command as [Request Type],
    SUBSTRING(
        sqltext.text, 
        (req.statement_start_offset/2)+1,   
        (
            (
                CASE req.statement_end_offset  
                    WHEN -1 THEN DATALENGTH(sqltext.text)  
                    ELSE req.statement_end_offset  
                END - req.statement_start_offset
            )/2
        ) + 1
    ) as [Query Text],
    req.total_elapsed_time as [Duration],
    'N/A' as [Queued Duration],
    req.total_elapsed_time as [Running Duration],
    'N/A' as [Data processed in bytes],
    'N/A' as [Workload group],
    'N/A' as [Source],
    'N/A' as [Pipeline],
    'N/A' as [Importance],
    'N/A' as [Classifier],
	'N/A' as [Error]
FROM 
    sys.dm_exec_requests req
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) sqltext
    JOIN sys.dm_exec_sessions s ON req.session_id = s.session_id 

SELECT 
    [Status],
    Transaction_id as [Request ID],
    'SQL On-demand' as [SQL Resource],
    login_name as [Submitter],
    'N/A' as [Session ID],
    start_time as [Submit time],
    start_time as [Start time],
    end_time as [End time],
    command as [Request Type],
    query_text as [Query Text],
    total_elapsed_time_ms as [Duration],
    'N/A' as [Queued Duration],
    data_processed_mb as [Data processed in MB],
    'N/A' as [Workload group],
    'N/A' as [Source],
    'N/A' as [Pipeline],
    'N/A' as [Importance],
    'N/A' as [Classifier],
    [Error]
FROM
    sys.dm_exec_requests_history