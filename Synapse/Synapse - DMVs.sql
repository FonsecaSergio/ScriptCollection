/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2022-06-09
************************************************/


SELECT TOP 1000
	R.[Request_id]
	,R.[session_id]
	,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[submit_time],R.[start_time]) / 1000.0)
	,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[start_time]) / 1000.0)
	,Request_execution_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[end_time]) / 1000.0)
	,Total_Elapsed_time_sec = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0)
	,Total_Elapsed_time_min = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0 / 60 )
	,[row_count] = RS.[row_count]
	,R.*
	,S.*
FROM sys.dm_pdw_exec_requests R
LEFT JOIN (SELECT request_id, row_count = MAX(row_count) FROM sys.dm_pdw_request_steps WHERE operation_type = 'ReturnOperation' GROUP BY request_id) RS
	ON R.request_id = RS.request_id
INNER JOIN sys.dm_pdw_exec_sessions S
	ON R.session_id = S.session_id
WHERE R.session_id <> session_id()
AND submit_time >= DATEADD(hour, -2, sysdatetime())
ORDER BY R.[total_Elapsed_time] DESC


SELECT TOP 1000 
     R.[Request_id]
	,R.[session_id]
    ,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[submit_time],R.[start_time]) / 1000.0)
    ,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[start_time]) / 1000.0)
    ,Request_execution_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[end_time]) / 1000.0)
    ,Total_Elapsed_time_sec = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0)
    ,Total_Elapsed_time_min = CONVERT(numeric(25,2),R.[total_Elapsed_time] / 1000.0 / 60 )
    ,R.* 
FROM sys.dm_pdw_exec_requests R
WHERE R.session_id <> session_id()
AND submit_time >= DATEADD(hour, -2, sysdatetime()) 
ORDER BY R.[total_Elapsed_time] DESC


SELECT TOP 1000 
     R.[Request_id]
	,R.[session_id]
    ,Request_queue_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[submit_time],R.[start_time]) / 1000.0)
    ,Request_compile_time_sec = CONVERT(numeric(25,3),DATEDIFF(ms,R.[end_compile_time],R.[start_time]) / 1000.0)
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
AND submit_time >= DATEADD(hour, -2, sysdatetime()) 
--AND R.request_id >= 'QID657016'
--AND [label] = 'xxxxxx'
--AND [label] like 'perf%'
--AND status = 'Running'
ORDER BY submit_time DESC

GO

SELECT * FROM sys.dm_pdw_exec_requests WHERE request_id = 'QID73849'
SELECT * FROM sys.dm_pdw_request_steps WHERE request_id = 'QID73849'
SELECT * FROM sys.dm_pdw_sql_requests WHERE request_id = 'QID73849' AND step_index = 2
SELECT * FROM sys.dm_pdw_dms_workers WHERE request_id = 'QID73849' AND step_index = 2
SELECT * FROM sys.dm_pdw_waits WHERE request_id = 'QID73849'

select type,pdw_node_id,sum(length) as file_size,sum(bytes_processed) as bytes_processed , count(*) as total_file_split 
from sys.dm_pdw_dms_external_work where request_id ='QID73849' group by type,pdw_node_id

select type ,count(*) as cnt from [sys].[dm_pdw_dms_workers] 
where request_id='QID73849' and step_index=2 group by type

--Node perf issue
SELECT pdw_node_id, distribution_id, avg_total_elapsed_time_sec = avg(total_elapsed_time) / 1000
FROM sys.dm_pdw_sql_requests 
WHERE request_id = 'QID24421'
GROUP BY pdw_node_id, distribution_id
ORDER BY avg_total_elapsed_time_sec desc




SELECT * FROM sys.dm_pdw_exec_sessions where status <> 'Closed' and session_id <> session_id();

SELECT * 
FROM sys.dm_pdw_exec_sessions S 
INNER JOIN sys.dm_pdw_exec_requests R
	ON S.session_id = R.session_id
INNER JOIN sys.dm_pdw_exec_connections C
	ON S.session_id = C.session_id
WHERE S.sql_spid = @@spid



SELECT * FROM sys.dm_pdw_dms_external_work
SELECT * FROM sys.dm_pdw_resource_waits
SELECT * FROM sys.dm_pdw_hadoop_operations
SELECT * FROM sys.pdw_nodes_column_store_row_groups
SELECT * FROM sys.external_tables
SELECT * FROM sys.external_data_sources
SELECT * FROM sys.external_file_formats


--InFlight query
SELECT * FROM sys.dm_pdw_nodes_exec_sql_text
SELECT * FROM sys.dm_pdw_nodes_exec_query_plan
SELECT * FROM sys.dm_pdw_nodes_exec_query_profiles
SELECT * FROM sys.dm_pdw_nodes_exec_query_statistics_xml
SELECT * FROM sys.dm_pdw_nodes_exec_text_query_plan

select * from sys.pdw_replicated_table_cache_state



SELECT * 
FROM sys.dm_pdw_exec_requests r
JOIN sys.dm_pdw_waits w
	ON r.request_id = w.request_id
--WHERE w.request_id = 'QID####'

SELECT * 
FROM sys.dm_pdw_exec_requests r
JOIN sys.dm_pdw_dms_external_work e
	ON r.request_id = e.request_id


---------------------------------------------------------------
-- User Roles

SELECT  r.name AS [Resource Class]
,       m.name AS membername
FROM    sys.database_role_members rm
JOIN    sys.database_principals AS r ON rm.role_principal_id = r.principal_id
JOIN    sys.database_principals AS m ON rm.member_principal_id = m.principal_id
WHERE   r.name IN ('mediumrc','largerc','xlargerc','staticrc10','staticrc20','staticrc30','staticrc40','staticrc50','staticrc60','staticrc70','staticrc80');
---------------------------------------------------------------
--for each row returned run
sp_droprolemember '[Resource Class]', membername
---------------------------------------------------------------

DBCC PDW_SHOWSPACEUSED('[dbo].[FactFinance]');
---------------------------------------------------------------


SELECT session_id, login_name, client_id, app_name, sql_spid 
FROM sys.dm_pdw_exec_sessions

--KILL 'SID6842'


---------------------------------------------------------------


--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/analyze-your-workload
SELECT  ro.[name]           AS [db_role_name]
FROM    sys.database_principals ro
WHERE   ro.[type_desc]      = 'DATABASE_ROLE'
AND     ro.[is_fixed_role]  = 0
;

SELECT  r.name AS role_principal_name
,       m.name AS member_principal_name
FROM    sys.database_role_members rm
JOIN    sys.database_principals AS r            ON rm.role_principal_id      = r.principal_id
JOIN    sys.database_principals AS m            ON rm.member_principal_id    = m.principal_id
WHERE   r.name IN ('mediumrc','largerc','xlargerc')
;

--EXEC sp_addrolemember 'largerc', 'loaduser';
--EXEC sp_droprolemember 'largerc', 'loaduser';

SELECT  w.[wait_id]
,       w.[session_id]
,       w.[type]                                           AS Wait_type
,       w.[object_type]
,       w.[object_name]
,       w.[request_id]
,       w.[request_time]
,       w.[acquire_time]
,       w.[state]
,       w.[priority]
,       SESSION_ID()                                       AS Current_session
,       s.[status]                                         AS Session_status
,       s.[login_name]
,       s.[query_count]
,       s.[client_id]
,       s.[sql_spid]
,       r.[command]                                        AS Request_command
,       r.[label]
,       r.[status]                                         AS Request_status
,       r.[submit_time]
,       r.[start_time]
,       r.[end_compile_time]
,       r.[end_time]
,       DATEDIFF(ms,r.[submit_time],r.[start_time])        AS Request_queue_time_ms
,       DATEDIFF(ms,r.[start_time],r.[end_compile_time])   AS Request_compile_time_ms
,       DATEDIFF(ms,r.[end_compile_time],r.[end_time])     AS Request_execution_time_ms
,       r.[total_elapsed_time]
FROM    sys.dm_pdw_waits w
JOIN    sys.dm_pdw_exec_sessions s  ON w.[session_id] = s.[session_id]
JOIN    sys.dm_pdw_exec_requests r  ON w.[request_id] = r.[request_id]
WHERE    w.[session_id] <> SESSION_ID()
;

SELECT  [session_id]
,       [type]
,       [object_type]
,       [object_name]
,       [request_id]
,       [request_time]
,       [acquire_time]
,       DATEDIFF(ms,[request_time],[acquire_time])  AS acquire_duration_ms
,       [concurrency_slots_used]                    AS concurrency_slots_reserved
,       [resource_class]
,       [wait_id]                                   AS queue_position
FROM    sys.dm_pdw_resource_waits
WHERE    [session_id] <> SESSION_ID()
;




---------------------------------------------------------------
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-manage-monitor#monitor-query-execution

-- Find top 10 queries longest running queries
SELECT TOP 10 *
FROM sys.dm_pdw_exec_requests
ORDER BY total_elapsed_time DESC;

-- Find the SQL Server execution plan for a query running on a specific SQL pool or control node.
-- Replace distribution_id and spid with values from previous query.

DBCC PDW_SHOWEXECUTIONPLAN(1, 78);

SELECT waits.session_id,
      waits.request_id,  
      requests.command,
      requests.status,
      requests.start_time,  
      waits.type,
      waits.state,
      waits.object_type,
      waits.object_name
FROM   sys.dm_pdw_waits waits
   JOIN  sys.dm_pdw_exec_requests requests
   ON waits.request_id=requests.request_id
WHERE waits.request_id = 'QID####'
ORDER BY waits.object_name, waits.object_type, waits.state;

---------------------------------------------------------------


---------------------------------------------------------------
-- Memory consumption
SELECT
  pc1.cntr_value as Curr_Mem_KB,
  pc1.cntr_value/1024.0 as Curr_Mem_MB,
  (pc1.cntr_value/1048576.0) as Curr_Mem_GB,
  pc2.cntr_value as Max_Mem_KB,
  pc2.cntr_value/1024.0 as Max_Mem_MB,
  (pc2.cntr_value/1048576.0) as Max_Mem_GB,
  pc1.cntr_value * 100.0/pc2.cntr_value AS Memory_Utilization_Percentage,
  pc1.pdw_node_id
FROM
-- pc1: current memory
sys.dm_pdw_nodes_os_performance_counters AS pc1
-- pc2: total memory allowed for this SQL instance
JOIN sys.dm_pdw_nodes_os_performance_counters AS pc2
ON pc1.object_name = pc2.object_name AND pc1.pdw_node_id = pc2.pdw_node_id
WHERE
pc1.counter_name = 'Total Server Memory (KB)'
AND pc2.counter_name = 'Target Server Memory (KB)'
---------------------------------------------------------------
-- Transaction log size
SELECT
  instance_name as distribution_db,
  cntr_value*1.0/1048576 as log_file_size_used_GB,
  pdw_node_id
FROM sys.dm_pdw_nodes_os_performance_counters
WHERE
instance_name like 'Distribution_%'
AND counter_name = 'Log File(s) Used Size (KB)'
---------------------------------------------------------------
-- Monitor rollback
SELECT
    SUM(CASE WHEN t.database_transaction_next_undo_lsn IS NOT NULL THEN 1 ELSE 0 END),
    t.pdw_node_id,
    nod.[type]
FROM sys.dm_pdw_nodes_tran_database_transactions t
JOIN sys.dm_pdw_nodes nod ON t.pdw_node_id = nod.pdw_node_id
GROUP BY t.pdw_node_id, nod.[type]

---------------------------------------------------------------
GO

CREATE VIEW dbo.vTableSizes
AS
WITH base
AS
(
SELECT
 GETDATE()                                                             AS  [execution_time]
, DB_NAME()                                                            AS  [database_name]
, s.name                                                               AS  [schema_name]
, t.name                                                               AS  [table_name]
, QUOTENAME(s.name)+'.'+QUOTENAME(t.name)                              AS  [two_part_name]
, nt.[name]                                                            AS  [node_table_name]
, ROW_NUMBER() OVER(PARTITION BY nt.[name] ORDER BY (SELECT NULL))     AS  [node_table_name_seq]
, tp.[distribution_policy_desc]                                        AS  [distribution_policy_name]
, c.[name]                                                             AS  [distribution_column]
, nt.[distribution_id]                                                 AS  [distribution_id]
, i.[type]                                                             AS  [index_type]
, i.[type_desc]                                                        AS  [index_type_desc]
, nt.[pdw_node_id]                                                     AS  [pdw_node_id]
, pn.[type]                                                            AS  [pdw_node_type]
, pn.[name]                                                            AS  [pdw_node_name]
, di.name                                                              AS  [dist_name]
, di.position                                                          AS  [dist_position]
, nps.[partition_number]                                               AS  [partition_nmbr]
, nps.[reserved_page_count]                                            AS  [reserved_space_page_count]
, nps.[reserved_page_count] - nps.[used_page_count]                    AS  [unused_space_page_count]
, nps.[in_row_data_page_count]
    + nps.[row_overflow_used_page_count]
    + nps.[lob_used_page_count]                                        AS  [data_space_page_count]
, nps.[reserved_page_count]
 - (nps.[reserved_page_count] - nps.[used_page_count])
 - ([in_row_data_page_count]
         + [row_overflow_used_page_count]+[lob_used_page_count])       AS  [index_space_page_count]
, nps.[row_count]                                                      AS  [row_count]
from
    sys.schemas s
INNER JOIN sys.tables t
    ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.indexes i
    ON  t.[object_id] = i.[object_id]
    AND i.[index_id] <= 1
INNER JOIN sys.pdw_table_distribution_properties tp
    ON t.[object_id] = tp.[object_id]
INNER JOIN sys.pdw_table_mappings tm
    ON t.[object_id] = tm.[object_id]
INNER JOIN sys.pdw_nodes_tables nt
    ON tm.[physical_name] = nt.[name]
INNER JOIN sys.dm_pdw_nodes pn
    ON  nt.[pdw_node_id] = pn.[pdw_node_id]
INNER JOIN sys.pdw_distributions di
    ON  nt.[distribution_id] = di.[distribution_id]
INNER JOIN sys.dm_pdw_nodes_db_partition_stats nps
    ON nt.[object_id] = nps.[object_id]
    AND nt.[pdw_node_id] = nps.[pdw_node_id]
    AND nt.[distribution_id] = nps.[distribution_id]
LEFT OUTER JOIN (select * from sys.pdw_column_distribution_properties where distribution_ordinal = 1) cdp
    ON t.[object_id] = cdp.[object_id]
LEFT OUTER JOIN sys.columns c
    ON cdp.[object_id] = c.[object_id]
    AND cdp.[column_id] = c.[column_id]
WHERE pn.[type] = 'COMPUTE'
)
, size
AS
(
SELECT
   [execution_time]
,  [database_name]
,  [schema_name]
,  [table_name]
,  [two_part_name]
,  [node_table_name]
,  [node_table_name_seq]
,  [distribution_policy_name]
,  [distribution_column]
,  [distribution_id]
,  [index_type]
,  [index_type_desc]
,  [pdw_node_id]
,  [pdw_node_type]
,  [pdw_node_name]
,  [dist_name]
,  [dist_position]
,  [partition_nmbr]
,  [reserved_space_page_count]
,  [unused_space_page_count]
,  [data_space_page_count]
,  [index_space_page_count]
,  [row_count]
,  ([reserved_space_page_count] * 8.0)                                 AS [reserved_space_KB]
,  ([reserved_space_page_count] * 8.0)/1000                            AS [reserved_space_MB]
,  ([reserved_space_page_count] * 8.0)/1000000                         AS [reserved_space_GB]
,  ([reserved_space_page_count] * 8.0)/1000000000                      AS [reserved_space_TB]
,  ([unused_space_page_count]   * 8.0)                                 AS [unused_space_KB]
,  ([unused_space_page_count]   * 8.0)/1000                            AS [unused_space_MB]
,  ([unused_space_page_count]   * 8.0)/1000000                         AS [unused_space_GB]
,  ([unused_space_page_count]   * 8.0)/1000000000                      AS [unused_space_TB]
,  ([data_space_page_count]     * 8.0)                                 AS [data_space_KB]
,  ([data_space_page_count]     * 8.0)/1000                            AS [data_space_MB]
,  ([data_space_page_count]     * 8.0)/1000000                         AS [data_space_GB]
,  ([data_space_page_count]     * 8.0)/1000000000                      AS [data_space_TB]
,  ([index_space_page_count]  * 8.0)                                   AS [index_space_KB]
,  ([index_space_page_count]  * 8.0)/1000                              AS [index_space_MB]
,  ([index_space_page_count]  * 8.0)/1000000                           AS [index_space_GB]
,  ([index_space_page_count]  * 8.0)/1000000000                        AS [index_space_TB]
FROM base
)
SELECT *
FROM size
;
---------------------------------------------------------------
SELECT
     database_name
,    schema_name
,    table_name
,    distribution_policy_name
,      distribution_column
,    index_type_desc
,    COUNT(distinct partition_nmbr) as nbr_partitions
,    SUM(row_count)                 as table_row_count
,    SUM(reserved_space_GB)         as table_reserved_space_GB
,    SUM(data_space_GB)             as table_data_space_GB
,    SUM(index_space_GB)            as table_index_space_GB
,    SUM(unused_space_GB)           as table_unused_space_GB
FROM
    dbo.vTableSizes
GROUP BY
     database_name
,    schema_name
,    table_name
,    distribution_policy_name
,      distribution_column
,    index_type_desc
ORDER BY
    table_reserved_space_GB desc
;
---------------------------------------------------------------
SELECT
     index_type_desc
,    SUM(row_count)                as table_type_row_count
,    SUM(reserved_space_GB)        as table_type_reserved_space_GB
,    SUM(data_space_GB)            as table_type_data_space_GB
,    SUM(index_space_GB)           as table_type_index_space_GB
,    SUM(unused_space_GB)          as table_type_unused_space_GB
FROM dbo.vTableSizes
GROUP BY index_type_desc
;
---------------------------------------------------------------
SELECT
    distribution_id
,    SUM(row_count)                as total_node_distribution_row_count
,    SUM(reserved_space_MB)        as total_node_distribution_reserved_space_MB
,    SUM(data_space_MB)            as total_node_distribution_data_space_MB
,    SUM(index_space_MB)           as total_node_distribution_index_space_MB
,    SUM(unused_space_MB)          as total_node_distribution_unused_space_MB
FROM dbo.vTableSizes
GROUP BY     distribution_id
ORDER BY    distribution_id
;
---------------------------------------------------------------
--Find out the difference between the row count from the statistics (stats_row_count) and the actual row count (actual_row_count).

select 
objIdsWithStats.[object_id], 
actualRowCounts.[schema], 
actualRowCounts.logical_table_name, 
statsRowCounts.stats_row_count, 
actualRowCounts.actual_row_count,
row_count_difference = CASE
	WHEN actualRowCounts.actual_row_count >= statsRowCounts.stats_row_count THEN actualRowCounts.actual_row_count - statsRowCounts.stats_row_count
	ELSE statsRowCounts.stats_row_count - actualRowCounts.actual_row_count
END,
percent_deviation_from_actual = CASE
	WHEN actualRowCounts.actual_row_count = 0 THEN statsRowCounts.stats_row_count
	WHEN statsRowCounts.stats_row_count = 0 THEN actualRowCounts.actual_row_count
	WHEN actualRowCounts.actual_row_count >= statsRowCounts.stats_row_count THEN CONVERT(NUMERIC(18, 0), CONVERT(NUMERIC(18, 2), (actualRowCounts.actual_row_count - statsRowCounts.stats_row_count)) / CONVERT(NUMERIC(18, 2), actualRowCounts.actual_row_count) * 100)
	ELSE CONVERT(NUMERIC(18, 0), CONVERT(NUMERIC(18, 2), (statsRowCounts.stats_row_count - actualRowCounts.actual_row_count)) / CONVERT(NUMERIC(18, 2), actualRowCounts.actual_row_count) * 100)
END
from
(
	select distinct object_id from sys.stats where stats_id > 1
) objIdsWithStats
left join
(
	select object_id, sum(rows) as stats_row_count from sys.partitions group by object_id
) statsRowCounts
on objIdsWithStats.object_id = statsRowCounts.object_id 
left join
(
	SELECT sm.name [schema] ,
	tb.name logical_table_name ,
	tb.object_id object_id ,
	SUM(rg.row_count) actual_row_count
	FROM sys.schemas sm
	INNER JOIN sys.tables tb ON sm.schema_id = tb.schema_id
	INNER JOIN sys.pdw_table_mappings mp ON tb.object_id = mp.object_id
	INNER JOIN sys.pdw_nodes_tables nt ON nt.name = mp.physical_name
	INNER JOIN sys.dm_pdw_nodes_db_partition_stats rg
	ON rg.object_id = nt.object_id
	AND rg.pdw_node_id = nt.pdw_node_id
	AND rg.distribution_id = nt.distribution_id
	WHERE 1 = 1
	GROUP BY sm.name, tb.name, tb.object_id
) actualRowCounts
on objIdsWithStats.object_id = actualRowCounts.object_id
---------------------------------------------------------------
--Query 2: Find out the age of your statistics by checking the last time your statistics were updated on each table.
SELECT
    sm.[name] AS [schema_name],
    tb.[name] AS [table_name],
    co.[name] AS [stats_column_name],
    st.[name] AS [stats_name],
    STATS_DATE(st.[object_id],st.[stats_id]) AS [stats_last_updated_date]
FROM
    sys.objects ob
    JOIN sys.stats st
        ON  ob.[object_id] = st.[object_id]
    JOIN sys.stats_columns sc
        ON  st.[stats_id] = sc.[stats_id]
        AND st.[object_id] = sc.[object_id]
    JOIN sys.columns co
        ON  sc.[column_id] = co.[column_id]
        AND sc.[object_id] = co.[object_id]
    JOIN sys.types  ty
        ON  co.[user_type_id] = ty.[user_type_id]
    JOIN sys.tables tb
        ON  co.[object_id] = tb.[object_id]
    JOIN sys.schemas sm
        ON  tb.[schema_id] = sm.[schema_id]
WHERE
    st.[user_created] = 1;
---------------------------------------------------------------




DMVs:

--- Currently running and queued requests
SELECT COUNT(*) AS QueryCount, status
FROM sys.dm_pdw_exec_requests
GROUP BY status
ORDER BY QueryCount

 

--- Shows queries waiting for resources

SELECT COUNT(*) AS QueryCount, state, type
FROM sys.dm_pdw_resource_waits
GROUP BY type, state
ORDER BY QueryCount

----
select * from sys.dm_pdw_nodes_tran_locks where request_status = 'WAIT'

---

/*
	The following query can be used to determine what resources a request is waiting for.
	Source: https://docs.microsoft.com/en-us/azure/sql-data-warehouse/analyze-your-workload
*/
SELECT  w.[wait_id]
,       w.[session_id]
,       w.[type]                                           AS Wait_type
,       w.[object_type]
,       w.[object_name]
,       w.[request_id]
,       w.[request_time]
,       w.[acquire_time]
,       w.[state]
,       w.[priority]
,       SESSION_ID()                                       AS Current_session
,       s.[status]                                         AS Session_status
,       s.[login_name]
,       s.[query_count]
,       s.[client_id]
,       s.[sql_spid]
,       r.[command]                                        AS Request_command
,       r.[label]
,       r.[status]                                         AS Request_status
,       r.[submit_time]
,       r.[start_time]
,       r.[end_compile_time]
,       r.[end_time]
,       DATEDIFF(ms,r.[submit_time],r.[start_time])        AS Request_queue_time_ms
,       DATEDIFF(ms,r.[start_time],r.[end_compile_time])   AS Request_compile_time_ms
,       DATEDIFF(ms,r.[end_compile_time],r.[end_time])     AS Request_execution_time_ms
,       r.[total_elapsed_time]
FROM    sys.dm_pdw_waits w
JOIN    sys.dm_pdw_exec_sessions s  ON w.[session_id] = s.[session_id]
JOIN    sys.dm_pdw_exec_requests r  ON w.[request_id] = r.[request_id]
WHERE    w.[session_id] <> SESSION_ID()
;

---
 /*
	NOTE: THIS QUERY IS NOT 100% ACCURATE, but is helpful in most cases. It attempts to link waiting queries to other queries that are blocking them.
    Sometimes if there are multiple queries blocking the waiting query, it cannot correctly identify the first query in the blocking chain.  
*/

WITH 
WaitingSidsList AS (
	SELECT 
		DateDiff(minute, waiting_waits.request_time, getdate()) as Wait_Time,
		waiting_waits.session_id AS        'Waiting_SID',
		waiting_waits.request_id AS        'Waiting_QID',
		blocking_waits.session_id AS    'Blocking_SID',
		blocking_waits.request_id AS    'Blocking_QID',
		waiting_waits.wait_id AS        'waiting_waitID',
		waiting_sessions.login_name AS    'Waiting_Login_Name',
		blocking_sessions.login_name AS    'Blocking_Login_Name',
		waiting_sessions.app_name AS    'Waiting_App_Name',
		blocking_sessions.app_name AS    'Blocking_App_name',
		waiting_PER.command AS            'Waiting_command',
		blocking_PER.command AS            'Blocking_command'
	FROM sys.dm_pdw_waits waiting_waits
	JOIN sys.dm_pdw_waits blocking_waits
		on waiting_waits.object_name = blocking_waits.object_name
		and waiting_waits.request_id != blocking_waits.request_id
	LEFT JOIN sys.dm_pdw_exec_sessions waiting_sessions
		ON waiting_waits.session_id = waiting_sessions.session_id
	LEFT JOIN sys.dm_pdw_exec_sessions blocking_sessions
		ON blocking_waits.session_id = blocking_sessions.session_id
	LEFT JOIN sys.dm_pdw_exec_requests waiting_PER
		ON waiting_PER.request_id = Waiting_waits.request_id
	LEFT JOIN sys.dm_pdw_exec_requests blocking_PER
		ON blocking_PER.request_id = blocking_waits.request_id
	WHERE waiting_waits.state = 'queued'
), 
MAX_WaitingSidsList AS (
	SELECT    Waiting_SID,
			MAX(waiting_waitID) as 'MAX_WaitID'
	FROM WaitingSidsList
	GROUP BY waiting_SID
) SELECT 
	 WaitingSidsList.Wait_Time AS 'Wait_Time_(M)',
	 WaitingSidsList.Waiting_SID,
	 WaitingSidsList.Waiting_QID,
	 WaitingSidsList.Blocking_SID,
	 WaitingSidsList.Blocking_QID,
	 WaitingSidsList.Waiting_Login_Name,
	 WaitingSidsList.Blocking_Login_Name,
	 WaitingSidsList.Waiting_App_Name,
	 WaitingSidsList.Blocking_App_name,
	 WaitingSidsList.Waiting_command,
	 WaitingSidsList.Blocking_command
FROM MAX_WaitingSidsList
JOIN WaitingSidsList
	ON MAX_WaitingSidsList.waiting_SID = WaitingSidsList.Waiting_SID
	AND MAX_WaitingSidsList.MAX_WaitID = WaitingSidsList.waiting_waitID



---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------