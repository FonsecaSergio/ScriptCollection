/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

-- Determining the Amount of Free Space in TempDB
SELECT 
	SUM(unallocated_extent_page_count) AS [free pages],
	(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used
SELECT 
	SUM(internal_object_reserved_page_count) AS [internal object pages used],
	(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB],
	SUM(user_object_reserved_page_count) AS [user object pages used],
	(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB],
	SUM(version_store_reserved_page_count) AS [version store pages used],
	(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Obtaining the space consumed currently in each session
SELECT Su.session_id,
  MAX(DSO.elastic_pool_name) as elastic_pool_name,
  MAX(DB_NAME(S.database_id)) as database_name,
  SUM(internal_objects_alloc_page_count) AS internal_objects_alloc_page_count,
  SUM(internal_objects_alloc_page_count)*1.0/128 AS internal_objects_alloc_page_count_MB,
  SUM(user_objects_alloc_page_count) AS user_objects_alloc_page_count,
  SUM(user_objects_alloc_page_count)*1.0/128 AS user_objects_alloc_page_count_MB
FROM tempdb.sys.dm_db_session_space_usage SU
LEFT JOIN sys.dm_exec_sessions S
	ON SU.session_id = S.session_id
LEFT JOIN sys.database_service_objectives DSO
	ON S.database_id = DSO.database_id
WHERe internal_objects_alloc_page_count + user_objects_alloc_page_count > 0
GROUP BY Su.session_id
ORDER BY user_objects_alloc_page_count desc, Su.session_id;

SELECT * FROM sys.database_service_objectives DSO

-- Obtaining the space consumed in all currently running tasks in each session
SELECT session_id,
  SUM(internal_objects_alloc_page_count) AS internal_objects_alloc_page_count,
  SUM(internal_objects_alloc_page_count)*1.0/128 AS internal_objects_alloc_page_count_MB,
  SUM(user_objects_alloc_page_count) AS user_objects_alloc_page_count,
  SUM(user_objects_alloc_page_count)*1.0/128 AS user_objects_alloc_page_count_MB
FROM tempdb.sys.dm_db_task_space_usage
WHERe internal_objects_alloc_page_count + user_objects_alloc_page_count > 0
GROUP BY session_id
ORDER BY user_objects_alloc_page_count desc, session_id;


