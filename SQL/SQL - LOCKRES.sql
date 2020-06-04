/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/
--Sample Metadata queries
-- For Page or Key resources

SELECT 
	DB_ID(),
	object_name(p.object_id) AS object_name,
	i.name AS index_name,
	p.object_id,
	p.index_id,
	p.partition_number
FROM sys.partitions p
INNER JOIN sys.indexes i ON i.object_id = p.object_id
	AND i.index_id = p.index_id
WHERE p.hobt_id = 72057594045857792

-- For Page resources
DBCC TRACEON (3604)
GO

DBCC PAGE(6, 1, 791, 3)
GO

DBCC TRACEOFF (3604)

-- For Key resources
SELECT *
FROM Production.Product WITH (NOLOCK)
WHERE % % lockres % % COLLATE DATABASE_DEFAULT = '(61a06abd401c)' -- Key hash obtained from resource_description column
