/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/
SELECT 
    OBJ.type_desc AS ObjectType,
	SCH.name AS SchemaName,
	OBJ.name AS ObjectName,
	IDX.type_desc AS IndexType,
	IDX.name AS IndexName,
	MF.name AS file_name,
	MF.physical_name,
	DS.name AS DataSpaceName,
	AU.type_desc AS AllocationDesc,
	AU.total_pages / 128 AS TotalSizeMB,
	AU.used_pages / 128 AS UsedSizeMB,
	AU.data_pages / 128 AS DataSizeMB
FROM sys.data_spaces AS DS
INNER JOIN sys.allocation_units AS AU ON DS.data_space_id = AU.data_space_id
INNER JOIN sys.partitions AS PA ON (
		AU.type IN (1, 3)
		AND AU.container_id = PA.hobt_id
		)
	OR (
		AU.type = 2
		AND AU.container_id = PA.partition_id
		)
INNER JOIN sys.objects AS OBJ ON PA.object_id = OBJ.object_id
INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id
LEFT JOIN sys.master_files MF ON MF.data_space_id = DS.data_space_id
LEFT JOIN sys.indexes AS IDX ON PA.object_id = IDX.object_id
	AND PA.index_id = IDX.index_id
WHERE OBJ.type = 'U'
	AND MF.database_id = DB_ID()
ORDER BY DS.name,
	SCH.name,
	OBJ.name,
	IDX.name
