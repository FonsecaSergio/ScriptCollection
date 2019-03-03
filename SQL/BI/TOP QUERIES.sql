/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
conditions contained within the Premier Customer Services Description.

*/
--TOP QUERIES BY TOTAL READS
SELECT TOP 25
	 'TOP QUERIES BY TOTAL READS'
	,[AVG_CPU_TIME] = total_worker_time/execution_count / 1000
	,[AVG_ELAPSED_TIME] = total_elapsed_time/execution_count / 1000
	,[AVG_READ] = total_logical_reads/execution_count
	,[AVG_WRITE] = total_logical_writes/execution_count
	,QS.execution_count
	,query_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_hash,2)
	,query_plan_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_plan_hash,2)
	,[dbid] = COALESCE(QT.dbid,PA.value,1)
	,[BATCH_TEXT] = QT.text
	,[STATEMENT_TEXT] = 
		SUBSTRING(QT.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(QT.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1)
	,QS.plan_generation_num
	,QS.creation_time
	,QS.last_execution_time
	,QS.total_worker_time
	,QS.last_worker_time
	,QS.min_worker_time
	,QS.max_worker_time
	,QS.total_logical_writes
	,QS.last_logical_writes
	,QS.min_logical_writes
	,QS.max_logical_writes
	,QS.total_logical_reads
	,QS.last_logical_reads
	,QS.min_logical_reads
	,QS.max_logical_reads
	,QS.total_clr_time
	,QS.last_clr_time
	,QS.min_clr_time
	,QS.max_clr_time
	,QS.total_elapsed_time
	,QS.last_elapsed_time
	,QS.min_elapsed_time
	,QS.max_elapsed_time
	,QS.total_rows
	,QS.last_rows
	,QS.min_rows
	,QS.max_rows
	,query_plan_batch = QP.query_plan
	,query_plan_statement = TRY_CONVERT(xml,QPS.query_plan)
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) QP 
CROSS APPLY sys.dm_exec_text_query_plan (QS.plan_handle,qs.statement_start_offset,qs.statement_end_offset) QPS 
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) QT
OUTER APPLY sys.dm_exec_plan_attributes(QS.plan_handle) PA
WHERE execution_count > 0
AND attribute = 'dbid'
ORDER BY total_logical_reads DESC

--TOP QUERIES BY AVG READS
SELECT TOP 25
	 'TOP QUERIES BY AVG READS'
	,[AVG_CPU_TIME] = total_worker_time/execution_count / 1000
	,[AVG_ELAPSED_TIME] = total_elapsed_time/execution_count / 1000
	,[AVG_READ] = total_logical_reads/execution_count
	,[AVG_WRITE] = total_logical_writes/execution_count
	,QS.execution_count
	,query_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_hash,2)
	,query_plan_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_plan_hash,2)
	,[dbid] = COALESCE(QT.dbid,PA.value,1)
	,[BATCH_TEXT] = QT.text
	,[STATEMENT_TEXT] = 
		SUBSTRING(QT.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(QT.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1)
	,QS.plan_generation_num
	,QS.creation_time
	,QS.last_execution_time
	,QS.total_worker_time
	,QS.last_worker_time
	,QS.min_worker_time
	,QS.max_worker_time
	,QS.total_logical_writes
	,QS.last_logical_writes
	,QS.min_logical_writes
	,QS.max_logical_writes
	,QS.total_logical_reads
	,QS.last_logical_reads
	,QS.min_logical_reads
	,QS.max_logical_reads
	,QS.total_clr_time
	,QS.last_clr_time
	,QS.min_clr_time
	,QS.max_clr_time
	,QS.total_elapsed_time
	,QS.last_elapsed_time
	,QS.min_elapsed_time
	,QS.max_elapsed_time
	,QS.total_rows
	,QS.last_rows
	,QS.min_rows
	,QS.max_rows
	,query_plan_batch = QP.query_plan
	,query_plan_statement = TRY_CONVERT(xml,QPS.query_plan)
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) QP 
CROSS APPLY sys.dm_exec_text_query_plan (QS.plan_handle,qs.statement_start_offset,qs.statement_end_offset) QPS 
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) QT
OUTER APPLY sys.dm_exec_plan_attributes(QS.plan_handle) PA
WHERE execution_count > 0
AND attribute = 'dbid'
ORDER BY total_logical_reads / execution_count DESC

--TOP QUERIES BY TOTAL CPU
SELECT TOP 25
	 'TOP QUERIES BY TOTAL CPU'
	,[AVG_CPU_TIME] = total_worker_time/execution_count / 1000
	,[AVG_ELAPSED_TIME] = total_elapsed_time/execution_count / 1000
	,[AVG_READ] = total_logical_reads/execution_count
	,[AVG_WRITE] = total_logical_writes/execution_count
	,QS.execution_count
	,query_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_hash,2)
	,query_plan_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_plan_hash,2)
	,[dbid] = COALESCE(QT.dbid,PA.value,1)
	,[BATCH_TEXT] = QT.text
	,[STATEMENT_TEXT] = 
		SUBSTRING(QT.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(QT.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1)
	,QS.plan_generation_num
	,QS.creation_time
	,QS.last_execution_time
	,QS.total_worker_time
	,QS.last_worker_time
	,QS.min_worker_time
	,QS.max_worker_time
	,QS.total_logical_writes
	,QS.last_logical_writes
	,QS.min_logical_writes
	,QS.max_logical_writes
	,QS.total_logical_reads
	,QS.last_logical_reads
	,QS.min_logical_reads
	,QS.max_logical_reads
	,QS.total_clr_time
	,QS.last_clr_time
	,QS.min_clr_time
	,QS.max_clr_time
	,QS.total_elapsed_time
	,QS.last_elapsed_time
	,QS.min_elapsed_time
	,QS.max_elapsed_time
	,QS.total_rows
	,QS.last_rows
	,QS.min_rows
	,QS.max_rows
	,query_plan_batch = QP.query_plan
	,query_plan_statement = TRY_CONVERT(xml,QPS.query_plan)
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) QP 
CROSS APPLY sys.dm_exec_text_query_plan (QS.plan_handle,qs.statement_start_offset,qs.statement_end_offset) QPS 
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) QT
OUTER APPLY sys.dm_exec_plan_attributes(QS.plan_handle) PA
WHERE execution_count > 0
AND attribute = 'dbid'
ORDER BY total_worker_time DESC

--TOP QUERIES BY AVG CPU
SELECT TOP 25
	 'TOP QUERIES BY AVG CPU'
	,[AVG_CPU_TIME] = total_worker_time/execution_count / 1000
	,[AVG_ELAPSED_TIME] = total_elapsed_time/execution_count / 1000
	,[AVG_READ] = total_logical_reads/execution_count
	,[AVG_WRITE] = total_logical_writes/execution_count
	,QS.execution_count
	,query_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_hash,2)
	,query_plan_hash_text = TRY_CONVERT(VARCHAR(20), QS.query_plan_hash,2)
	,[dbid] = COALESCE(QT.dbid,PA.value,1)
	,[BATCH_TEXT] = QT.text
	,[STATEMENT_TEXT] = 
		SUBSTRING(QT.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(QT.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1)
	,QS.plan_generation_num
	,QS.creation_time
	,QS.last_execution_time
	,QS.total_worker_time
	,QS.last_worker_time
	,QS.min_worker_time
	,QS.max_worker_time
	,QS.total_logical_writes
	,QS.last_logical_writes
	,QS.min_logical_writes
	,QS.max_logical_writes
	,QS.total_logical_reads
	,QS.last_logical_reads
	,QS.min_logical_reads
	,QS.max_logical_reads
	,QS.total_clr_time
	,QS.last_clr_time
	,QS.min_clr_time
	,QS.max_clr_time
	,QS.total_elapsed_time
	,QS.last_elapsed_time
	,QS.min_elapsed_time
	,QS.max_elapsed_time
	,QS.total_rows
	,QS.last_rows
	,QS.min_rows
	,QS.max_rows
	,query_plan_batch = QP.query_plan
	,query_plan_statement = TRY_CONVERT(xml,QPS.query_plan)
FROM sys.dm_exec_query_stats QS
CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) QP 
CROSS APPLY sys.dm_exec_text_query_plan (QS.plan_handle,qs.statement_start_offset,qs.statement_end_offset) QPS 
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) QT
OUTER APPLY sys.dm_exec_plan_attributes(QS.plan_handle) PA
WHERE execution_count > 0
AND attribute = 'dbid'
ORDER BY total_worker_time / execution_count DESC

