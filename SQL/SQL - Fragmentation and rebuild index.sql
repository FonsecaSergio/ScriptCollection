SELECT o.name, o.object_id, ips.index_type_desc, alloc_unit_type_desc, page_count, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats ( DB_ID(), NULL, NULL, NULL, 'LIMITED') ips  
JOIN sys.objects o on o.object_id = ips.object_id  
ORDER BY ips.page_count DESC

ALTER INDEX ALL ON Production.Product
REBUILD WITH (FILLFACTOR = 100)
