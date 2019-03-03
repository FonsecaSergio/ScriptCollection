DECLARE @intDBID INT;
SET @intDBID = (SELECT [dbid] 
                FROM master.dbo.sysdatabases 
                WHERE name = 'INDEX_REVIEW');

-- Flush the procedure cache for one database only
DBCC FLUSHPROCINDB (@intDBID);

--SELECT * FROM sys.dm_exec_cached_plans C
--CROSS APPLY sys.dm_exec_sql_text (C.plan_handle) T