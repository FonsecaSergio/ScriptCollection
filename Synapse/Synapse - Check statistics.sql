--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-statistics#update-statistics

------------------------------------------------------------------------------------------------------------------------
--Query 1: Find out the difference between the row count from the statistics (stats_row_count) and the actual row count (actual_row_count).
select 
	objIdsWithStats.[object_id], 
	actualRowCounts.[schema], 
	actualRowCounts.logical_table_name, 
	statsRowCounts.stats_row_count, 
	actualRowCounts.actual_row_count,
	row_count_difference = CASE
		WHEN actualRowCounts.actual_row_count >= statsRowCounts.stats_row_count THEN actualRowCounts.actual_row_count - statsRowCounts.stats_row_count
		ELSE statsRowCounts.stats_row_count - actualRowCounts.actual_row_count
	END,
	percent_deviation_from_actual = CASE
		WHEN actualRowCounts.actual_row_count = 0 THEN statsRowCounts.stats_row_count
		WHEN statsRowCounts.stats_row_count = 0 THEN actualRowCounts.actual_row_count
		WHEN actualRowCounts.actual_row_count >= statsRowCounts.stats_row_count THEN CONVERT(NUMERIC(18, 0), CONVERT(NUMERIC(18, 2), (actualRowCounts.actual_row_count - statsRowCounts.stats_row_count)) / CONVERT(NUMERIC(18, 2), actualRowCounts.actual_row_count) * 100)
		ELSE CONVERT(NUMERIC(18, 0), CONVERT(NUMERIC(18, 2), (statsRowCounts.stats_row_count - actualRowCounts.actual_row_count)) / CONVERT(NUMERIC(18, 2), actualRowCounts.actual_row_count) * 100)
	END
from
(
	select distinct object_id from sys.stats where stats_id > 1
) objIdsWithStats
left join
(
	select object_id, sum(rows) as stats_row_count from sys.partitions group by object_id
) statsRowCounts
on objIdsWithStats.object_id = statsRowCounts.object_id 
left join
(
	SELECT sm.name [schema] ,
	tb.name logical_table_name ,
	tb.object_id object_id ,
	SUM(rg.row_count) actual_row_count
	FROM sys.schemas sm
	INNER JOIN sys.tables tb ON sm.schema_id = tb.schema_id
	INNER JOIN sys.pdw_table_mappings mp ON tb.object_id = mp.object_id
	INNER JOIN sys.pdw_nodes_tables nt ON nt.name = mp.physical_name
	INNER JOIN sys.dm_pdw_nodes_db_partition_stats rg
	ON rg.object_id = nt.object_id
	AND rg.pdw_node_id = nt.pdw_node_id
	AND rg.distribution_id = nt.distribution_id
	WHERE 1 = 1
	GROUP BY sm.name, tb.name, tb.object_id
) actualRowCounts
on objIdsWithStats.object_id = actualRowCounts.object_id


------------------------------------------------------------------------------------------------------------------------
--Query 2: Find out the age of your statistics by checking the last time your statistics were updated on each table.
SELECT
    sm.[name] AS [schema_name],
    tb.[name] AS [table_name],
    co.[name] AS [stats_column_name],
    st.[name] AS [stats_name],
    STATS_DATE(st.[object_id],st.[stats_id]) AS [stats_last_updated_date]
FROM
    sys.objects ob
    JOIN sys.stats st
        ON  ob.[object_id] = st.[object_id]
    JOIN sys.stats_columns sc
        ON  st.[stats_id] = sc.[stats_id]
        AND st.[object_id] = sc.[object_id]
    JOIN sys.columns co
        ON  sc.[column_id] = co.[column_id]
        AND sc.[object_id] = co.[object_id]
    JOIN sys.types  ty
        ON  co.[user_type_id] = ty.[user_type_id]
    JOIN sys.tables tb
        ON  co.[object_id] = tb.[object_id]
    JOIN sys.schemas sm
        ON  tb.[schema_id] = sm.[schema_id]
WHERE
    st.[user_created] = 1;

--Then UPDATE STATISTICS needed

--UPDATE STATISTICS [schema_name].[table_name]([stat_name]);
--UPDATE STATISTICS [schema_name].[table_name];