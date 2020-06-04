/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

DECLARE @IndexType_HEAP INT = 0
DECLARE @IndexType_CLUSTERED INT = 1
DECLARE @IndexType_NONCLUSTERED INT = 2

;WITH AUX AS
(
	SELECT 
		 [SCHEMA] = s.name
		,[TABLE] = o.[name]
		,[INDEX] = CASE WHEN i.name <> '' THEN i.name ELSE '[HEAP]' END
		,[INDEX_TYPE_ID] = i.type
		,[INDEX_TYPE] = i.type_desc
		,last_user_lookup = COALESCE(ios.last_user_lookup,'1900-01-01')
		,last_user_scan = COALESCE(ios.last_user_scan,'1900-01-01')
		,last_user_seek = COALESCE(ios.last_user_seek,'1900-01-01')
		,last_user_update = COALESCE(ios.last_user_update,'1900-01-01') -- The user_updates counter indicates the level of maintenance on the index caused by insert, update, or delete operations on the underlying table or view
		,last_system_lookup = COALESCE(ios.last_system_lookup,'1900-01-01')
		,last_system_scan = COALESCE(ios.last_system_scan,'1900-01-01')
		,last_system_seek = COALESCE(ios.last_system_seek,'1900-01-01')
		,last_system_update = COALESCE(ios.last_system_update,'1900-01-01')
	FROM sys.tables AS t
	INNER JOIN sys.objects o ON o.[object_id] = t.[object_id]
	INNER JOIN sys.schemas AS s ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.indexes i  ON t.[object_id] = i.[object_id]
	LEFT JOIN sys.dm_db_index_usage_stats ios ON t.[object_id] = ios.[object_id] AND i.[index_id] = ios.[index_id]
	AND o.is_ms_shipped = 0 -- Only user Objects
	AND i.type IN (@IndexType_HEAP, @IndexType_CLUSTERED, @IndexType_NONCLUSTERED)
	AND i.is_hypothetical = 0 -- NOT hypothetical
)
SELECT * FROM AUX