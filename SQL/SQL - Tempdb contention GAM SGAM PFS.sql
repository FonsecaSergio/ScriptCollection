SELECT * FROM sys.dm_exec_requests R
OUTER APPLY sys.dm_exec_sql_text (R.sql_handle) T

Select 
	session_id
	,wait_type
	,wait_duration_ms
	,blocking_session_id
	,resource_description
	,ResourceType = CASE 
		WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) AS INT) - 1 % 8088 = 0
			THEN 'Is PFS Page'
		WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) AS INT) - 2 % 511232 = 0
			THEN 'Is GAM Page'
		WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) AS INT) - 3 % 511232 = 0
			THEN 'Is SGAM Page'
		ELSE 'Is Not PFS, GAM, or SGAM page'
		END
FROM sys.dm_os_waiting_tasks
WHERE wait_type LIKE 'PAGE%LATCH_%'
	AND resource_description LIKE '2:%'


use tempdb
--Select database_id,DB_name(database_id) as [Database],
-- allocated_page_page_id , page_type_desc
--from sys.dm_db_database_page_allocations(DB_ID(),null,null,null,'Detailed')

Select OBJ.name, P.* 
from sys.dm_db_page_info(2,1,128,'DETAILED') P
INNER JOIN sys.partitions PART ON P.partition_id = PART.partition_id
INNER JOIN sys.objects OBJ ON PART.object_id = OBJ.object_id

SELECT database_id, name, compatibility_level, is_mixed_page_allocation_on 
FROM sys.databases

--http://sqlsoldier.net/wp/sqlserver/breakingdowntempdbcontentionpart2


DECLARE @PAGEID INT = 809547096

SELECT
	CASE
		WHEN @PAGEID = 1 OR @PAGEID % 8088 = 0 THEN 'PFS'
		WHEN @PAGEID = 2 OR @PAGEID % 511232 = 0 THEN 'GAM'
		WHEN @PAGEID = 3 OR (@PAGEID - 1) % 511232 = 0 THEN 'SGAM'
		WHEN @PAGEID IS NOT NULL THEN 'Other'
		ELSE NULL
	END AS page_type

--https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-gam-sgam-pfs-and-other-allocation-maps/