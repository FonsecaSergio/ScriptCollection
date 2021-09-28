/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2021-02-10
************************************************/

--LOOK FOR REQUESTS CURRENTLY RUNNING

SELECT TOP 1000 
     R.[Request_id]
    ,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[submit_time],R.[start_time]) / 1000.0)
    ,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[start_time],R.[end_compile_time]) / 1000.0)
    ,Request_execution_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[end_time]) / 1000.0)
    ,Total_Elapsed_time_sec = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0)
    ,Total_Elapsed_time_min = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0 / 60 )
    ,nbr_files
    ,gb_processed
    ,R.* 
FROM sys.dm_pdw_exec_requests R
LEFT JOIN (
    SELECT 
        request_id
        ,count(distinct input_name) as nbr_files
        ,sum(bytes_processed)/1024/1024/1024 as gb_processed
    FROM sys.dm_pdw_dms_external_work s
    GROUP BY s.request_id
) S
    ON r.request_id = s.request_id
WHERE R.session_id <> session_id()
--AND submit_time >= DATEADD(hour, -2, sysdatetime())
AND status = 'Running' -- ONLY RUNNING
AND R.resource_class IS NOT NULL -- REMOVE BATCH QIDs
ORDER BY submit_time DESC


SELECT * FROM sys.dm_pdw_request_steps 
WHERE request_id = 'QID35849'

SELECT 
     Total_Elapsed_time_sec = CONVERT(numeric(25,2),[total_Elapsed_time] / 1000.0)
    ,Total_Elapsed_time_min = CONVERT(numeric(25,2),[total_Elapsed_time] / 1000.0 / 60 )
    ,* 
FROM sys.dm_pdw_sql_requests 
WHERE request_id = 'QID35849'
ORDER BY [total_Elapsed_time] desc


SELECT * FROM sys.dm_pdw_waits 
WHERE request_id = 'QID35849'
WHERE blocked.state <> 'Granted' -- WAITING FOR SOMETHING

-- blocked session info
WITH blocked_sessions (login_name, blocked_session, state, type, command, object)
AS
(
SELECT 
    sessions.login_name,
    blocked.session_id as blocked_session, 
    blocked.state , 
    blocked.type,
    requests.command,
    blocked.object_name
    FROM sys.dm_pdw_waits blocked
    JOIN sys.dm_pdw_exec_requests requests
        ON blocked.request_id = requests.request_id
    JOIN sys.dm_pdw_exec_sessions sessions
        ON blocked.session_id = sessions.session_id
    WHERE blocked.state <> 'Granted'
    )
--merging with blocking session info
SELECT 
    blocked_sessions.login_name as blocked_user,
    blocked_sessions.blocked_session as blocked_session,
    blocked_sessions.state as blocked_state,
    blocked_sessions.type as blocked_type,
    blocked_sessions.command as blocked_command,
    sessions.login_name as blocking_user,
    blocking.session_id as blocking_session, 
    blocking.state as blocking_state, 
    blocking.type as blocking_type,
    requests.command as blocking_command
    FROM sys.dm_pdw_waits blocking
    JOIN blocked_sessions 
        ON blocked_sessions.object = blocking.object_name
    JOIN sys.dm_pdw_exec_requests requests
        ON blocking.request_id = requests.request_id
    JOIN sys.dm_pdw_exec_sessions sessions
        ON blocking.session_id = sessions.session_id
    WHERE blocking.state = 'Granted'