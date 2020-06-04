/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

SELECT 
	t.NAME AS TableName,
	SUM(p.rows) AS RowCounts,
	SUM(a.total_pages) AS TotalPages, 
	SUM(a.used_pages) AS UsedPages, 
	SUM(a.data_pages) AS DataPages,
	(SUM(a.total_pages) * 8) AS TotalSpaceKb, 
	(SUM(a.used_pages) * 8) AS UsedSpaceKb, 
	(SUM(a.data_pages) * 8) AS DataSpaceKb,
	(SUM(a.total_pages) * 8) / 1024 AS TotalSpaceMB, 
	(SUM(a.used_pages) * 8) / 1024 AS UsedSpaceMB, 
	(SUM(a.data_pages) * 8) / 1024 AS DataSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.NAME, i.object_id 
ORDER BY TotalSpaceKb DESC

SELECT 
	t.NAME AS TableName,
	i.name AS indexName,
	SUM(p.rows) AS RowCounts,
	SUM(a.total_pages) AS TotalPages, 
	SUM(a.used_pages) AS UsedPages, 
	SUM(a.data_pages) AS DataPages,
	(SUM(a.total_pages) * 8) AS TotalSpaceKb, 
	(SUM(a.used_pages) * 8) AS UsedSpaceKb, 
	(SUM(a.data_pages) * 8) AS DataSpaceKb,
	(SUM(a.total_pages) * 8) / 1024 AS TotalSpaceMB, 
	(SUM(a.used_pages) * 8) / 1024 AS UsedSpaceMB, 
	(SUM(a.data_pages) * 8) / 1024 AS DataSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.NAME, i.object_id, i.index_id, i.name 
ORDER BY TotalSpaceKb DESC