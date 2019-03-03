SELECT TOP 100 
       AvgWorkerTime_sec = (total_worker_time / execution_count) / 1000/1000.0
                   ,max_worker_time_sec = max_worker_time / 1000/1000.0
       ,BATCHTEXT = REPLACE(REPLACE(REPLACE(LEFT(B.text, 100),CHAR(13),''),CHAR(10),''),CHAR(16),'')
                   -- ,BATCHPLAN = C.query_plan
                   ,min_logical_reads
                   ,max_logical_reads
                   ,avg_logical_reads = total_logical_reads / execution_count
                   ,PercLogReads = CONVERT(numeric(18,5), ((CONVERT(numeric(18,5), min_logical_reads) / max_logical_reads) * 100))
FROM sys.dm_exec_procedure_stats A
CROSS APPLY sys.dm_exec_sql_text (A.sql_handle) B
CROSS APPLY sys.dm_exec_query_plan(A.plan_handle) C
WHERE max_logical_reads > 0 and execution_count > 0
ORDER BY CONVERT(numeric(18,5), ((CONVERT(numeric(18,5), min_logical_reads) / max_logical_reads) * 100))
