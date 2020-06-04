/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

--https://techcommunity.microsoft.com/t5/DataCAT/CPU-and-Memory-Allocation-on-Azure-SQL-Database-Managed-Instance/ba-p/305508

SELECT cntr_value / 1024
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Memory Manager%'
AND
counter_name = 'Target Server Memory (KB)';

SELECT CONVERT(INT, value_in_use) / 1024 / 1024
FROM sys.configurations
WHERE name = 'max server memory (MB)';

SELECT process_memory_limit_mb, non_sos_mem_gap_mb, mem = process_memory_limit_mb - non_sos_mem_gap_mb
FROM sys.dm_os_job_object;