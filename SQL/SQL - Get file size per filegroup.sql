
/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
conditions contained within the Premier Customer Services Description.

*/
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
