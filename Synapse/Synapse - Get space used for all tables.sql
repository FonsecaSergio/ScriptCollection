/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2021-02-12
************************************************/

SELECT 
	sm.name [schema] ,
	tb.name logical_table_name ,
	tb.object_id object_id ,
	SUM(rg.row_count) actual_row_count ,
	CONVERT(numeric(25,2),SUM(rg.row_count) / 1000000.0) actual_row_count_Million ,
	CONVERT(numeric(25,0),SUM(rg.reserved_page_count) * 8) SpaceUsed_Kb ,
	CONVERT(numeric(25,2),SUM(rg.reserved_page_count) * 8 / 1024.0) SpaceUsed_Mb ,
	CONVERT(numeric(25,2),SUM(rg.reserved_page_count) * 8 / 1024 / 1024.0) SpaceUsed_Gb
FROM sys.schemas sm
INNER JOIN sys.tables tb ON sm.schema_id = tb.schema_id
INNER JOIN sys.pdw_table_mappings mp ON tb.object_id = mp.object_id
INNER JOIN sys.pdw_nodes_tables nt ON nt.name = mp.physical_name
INNER JOIN sys.dm_pdw_nodes_db_partition_stats rg
ON rg.object_id = nt.object_id
AND rg.pdw_node_id = nt.pdw_node_id
AND rg.distribution_id = nt.distribution_id
--WHERE sm.name = 'dbo'
GROUP BY sm.name, tb.name, tb.object_id
ORDER BY actual_row_count DESC