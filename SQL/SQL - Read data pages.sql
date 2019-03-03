
DBCC TRACEON (3604); -- READ DATA PAGES
--SELECT sys.fn_PhysLocFormatter(%%physloc%%) AS Location,* FROM TABLE_CLUSTER

SELECT page_type_desc, allocation_unit_type_desc, allocated_page_file_id, allocated_page_page_id,extent_page_id
FROM sys.dm_db_database_page_allocations(DB_ID(), object_id('TABLE_CLUSTER'), NULL, NULL, 'DETAILED')

DBCC PAGE(SANDBOX, 1, 1, 3) -- GAM
DBCC PAGE(SANDBOX, 1, 2, 3) -- SGAM
DBCC PAGE(SANDBOX, 1, 3, 3) -- PFS

DBCC PAGE(SANDBOX, 1, 89, 3)
DBCC PAGE(SANDBOX, 1, 90, 3)

SELECT total_pages, used_pages, data_pages FROM sys.allocation_units where container_id = ( SELECT partition_id FROM sys.partitions where object_id = object_id('TABLE_CLUSTER') )
GO
EXEC sp_spaceused 'TABLE_CLUSTER'
