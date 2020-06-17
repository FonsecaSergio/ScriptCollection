/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

SELECT o.id,
       object_name(o.id),
       i.indid,
       i.name,
       rows,
       stats_date(o.id, i.indid) AS 'stats updated'
FROM   sysobjects AS o
       INNER JOIN
       sysindexes AS i
       ON o.id = i.id
WHERE  o.type = N'U';


SELECT
    sp.stats_id, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter 
FROM sys.stats AS stat 
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp