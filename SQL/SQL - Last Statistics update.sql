/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

-- STATS RELATED TO INDEX
SELECT 
    o.id,
    object_name(o.id),
    i.indid,
    i.name,
    rows,
    stats_date(o.id, i.indid) AS 'stats updated'
FROM sysobjects AS o
INNER JOIN sysindexes AS i
    ON o.id = i.id
WHERE  o.type = N'U';


-- STATS RELATED TO INDEX AND COLUMNS WITHOUT INDEX
SELECT
     sp.stats_id
    ,stat.name
    ,stat.filter_definition
    ,sp.last_updated
    ,sp.rows
    ,sp.rows_sampled
    ,sp.steps
    ,sp.unfiltered_rows
    ,sp.modification_counter
FROM sys.stats AS stat 
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp