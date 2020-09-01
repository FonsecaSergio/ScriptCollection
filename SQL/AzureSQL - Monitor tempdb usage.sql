DROP TABLE IF EXISTS ##TEMP_COLUMNS 
GO
SELECT * INTO ##TEMP_COLUMNS 
FROM sys.columns

/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-09-01
************************************************/

-- Determining the Amount of Space Used  / free
SELECT 
	 [Source] = 'database_files'
	,[TEMPDB_max_size_MB] = SUM(max_size) * 8 / 1027.0
	,[TEMPDB_current_size_MB] = SUM(size) * 8 / 1027.0
	,[FileCount] = COUNT(FILE_ID)
FROM tempdb.sys.database_files
WHERE type = 0 --ROWS

SELECT 
	 [Source] = 'dm_db_file_space_usage'
	,[free_space_MB] = SUM(U.unallocated_extent_page_count) * 8 / 1024.0
	,[used_space_MB] = SUM(U.internal_object_reserved_page_count + U.user_object_reserved_page_count + U.version_store_reserved_page_count) * 8 / 1024.0
    ,[internal_object_space_MB] = SUM(U.internal_object_reserved_page_count) * 8 / 1024.0
    ,[user_object_space_MB] = SUM(U.user_object_reserved_page_count) * 8 / 1024.0
    ,[version_store_space_MB] = SUM(U.version_store_reserved_page_count) * 8 / 1024.0
FROM tempdb.sys.dm_db_file_space_usage U

-- Obtaining the space consumed currently in each session
SELECT 
	 [Source] = 'dm_db_session_space_usage'
	,[session_id] = Su.session_id
	,[login_name] = MAX(S.login_name)
	,[database_id] = MAX(S.database_id)
	,[database_name] = MAX(DB_NAME(S.database_id))
	,[elastic_pool_name] = MAX(DSO.elastic_pool_name)
	,[internal_objects_alloc_page_count_MB] = SUM(internal_objects_alloc_page_count) * 8 / 1024.0
	,[user_objects_alloc_page_count_MB] = SUM(user_objects_alloc_page_count) * 8 / 1024.0
FROM tempdb.sys.dm_db_session_space_usage SU
LEFT JOIN sys.dm_exec_sessions S
        ON SU.session_id = S.session_id
LEFT JOIN sys.database_service_objectives DSO
        ON S.database_id = DSO.database_id
WHERE internal_objects_alloc_page_count + user_objects_alloc_page_count > 0
GROUP BY Su.session_id
ORDER BY [user_objects_alloc_page_count_MB] desc, Su.session_id;


-- Obtaining the space consumed in all currently running tasks in each session
SELECT 
	 [Source] = 'dm_db_task_space_usage'
	,[session_id] = SU.session_id
	,[login_name] = MAX(S.login_name)
	,[database_id] = MAX(S.database_id)
	,[database_name] = MAX(DB_NAME(S.database_id))
	,[elastic_pool_name] = MAX(DSO.elastic_pool_name)
	,[internal_objects_alloc_page_count_MB] = SUM(SU.internal_objects_alloc_page_count) * 8 / 1024.0
	,[user_objects_alloc_page_count_MB] = SUM(SU.user_objects_alloc_page_count) * 8 / 1024.0
FROM tempdb.sys.dm_db_task_space_usage SU
LEFT JOIN sys.dm_exec_sessions S
        ON SU.session_id = S.session_id
LEFT JOIN sys.database_service_objectives DSO
        ON S.database_id = DSO.database_id
WHERE internal_objects_alloc_page_count + user_objects_alloc_page_count > 0
GROUP BY SU.session_id
ORDER BY [user_objects_alloc_page_count_MB] desc, session_id;
