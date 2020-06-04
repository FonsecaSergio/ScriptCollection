/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

SELECT TOP(5) [type] AS [ClerkType],
SUM(pages_kb) / 1024 AS [SizeMb]
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]
ORDER BY SUM(pages_kb) DESC

SELECT * 
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
WHERE type = 'MEMORYCLERK_SQLGENERAL'
AND memory_node_id != 64

SELECT * FROM sys.dm_os_memory_objects
WHERE page_allocator_address IN
(
	SELECT page_allocator_address
	FROM sys.dm_os_memory_clerks WITH (NOLOCK)
	WHERE type = 'MEMORYCLERK_SQLGENERAL'
	AND memory_node_id != 64
)
ORDER BY pages_in_bytes DESC
