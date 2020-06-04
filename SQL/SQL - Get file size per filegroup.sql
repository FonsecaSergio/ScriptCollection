/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

IF OBJECT_ID('tempdb..#TEMP_SPACE') IS NOT NULL
	DROP TABLE #TEMP_SPACE
GO
CREATE TABLE #TEMP_SPACE (DBNAME sysname, [FILE] sysname, [FILEGROUP] sysname, Size numeric (18,2))

EXEC sp_MSforeachdb '
use ?
INSERT INTO #TEMP_SPACE
SELECT DB_NAME(), F.name, FG.name, size_Mb = size * 8 /1024 
FROM sys.database_files F
INNER JOIN sys.data_spaces FG
	ON F.data_space_id = FG.data_space_id
WHERE F.type = 0 -- ROWS
'

SELECT DBNAME, FILEGROUP, SizeMb = SUM(Size) FROM #TEMP_SPACE
GROUP BY DBNAME, FILEGROUP
order by DBNAME, FILEGROUP
