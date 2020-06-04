/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

CREATE TABLE #ls (
	NAME VARCHAR(255)
	,LogSize REAL
	,LogSpaceUsed REAL
	,STATUS INT
	)

INSERT #ls
EXEC ('dbcc sqlperf(logspace)')

DECLARE @name VARCHAR(255)
	,@sql VARCHAR(1000);

SELECT d.NAME
	,DATABASEPROPERTYEX(d.NAME, 'Status') STATUS
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoCreateStatistics') = 1
			THEN 'ON'
		ELSE 'OFF'
		END AutoCreateStatistics
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoUpdateStatistics') = 1
			THEN 'ON'
		ELSE 'OFF'
		END AutoUpdateStatistics
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoShrink') = 1
			THEN 'ON'
		ELSE 'OFF'
		END AutoShrink
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoClose') = 1
			THEN 'ON'
		ELSE 'OFF'
		END AutoClose
	,DATABASEPROPERTYEX(d.NAME, 'Collation') Collation
	,DATABASEPROPERTYEX(d.NAME, 'Updateability') Updateability
	,DATABASEPROPERTYEX(d.NAME, 'UserAccess') UserAccess
	,replace(page_verify_option_desc, '_', ' ') PageVerifyOption
	,d.compatibility_level CompatibilityLevel
	,DATABASEPROPERTYEX(d.NAME, 'Recovery') RecoveryModel
	,convert(BIGINT, 0) AS Size
	,convert(BIGINT, 0) Used
	,CASE 
		WHEN sum(NumberReads + NumberWrites) > 0
			THEN sum(IoStallMS) / sum(NumberReads + NumberWrites)
		ELSE - 1
		END AvgIoMs
	,ls.LogSize
	,ls.LogSpaceUsed
	,b.backup_start_date LastBackup
INTO #dbs1
FROM master.sys.databases AS d
LEFT JOIN msdb..backupset b ON d.NAME = b.database_name
	AND b.backup_start_date = (
		SELECT max(backup_start_date)
		FROM msdb..backupset
		WHERE database_name = b.database_name
			AND type = 'D'
		)
LEFT JOIN::fn_virtualfilestats(- 1, - 1) AS vfs ON d.database_id = vfs.DbId
JOIN #ls AS ls ON d.NAME = ls.NAME
GROUP BY d.NAME
	,DATABASEPROPERTYEX(d.NAME, 'Status')
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoCreateStatistics') = 1
			THEN 'ON'
		ELSE 'OFF'
		END
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoUpdateStatistics') = 1
			THEN 'ON'
		ELSE 'OFF'
		END
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoShrink') = 1
			THEN 'ON'
		ELSE 'OFF'
		END
	,CASE 
		WHEN DATABASEPROPERTYEX(d.NAME, 'IsAutoClose') = 1
			THEN 'ON'
		ELSE 'OFF'
		END
	,DATABASEPROPERTYEX(d.NAME, 'Collation')
	,DATABASEPROPERTYEX(d.NAME, 'Updateability')
	,DATABASEPROPERTYEX(d.NAME, 'UserAccess')
	,page_verify_option_desc
	,d.compatibility_level
	,DATABASEPROPERTYEX(d.NAME, 'Recovery')
	,ls.LogSize
	,ls.LogSpaceUsed
	,b.backup_start_date;

CREATE TABLE #dbsize1 (
	fileid INT
	,filegroup INT
	,TotalExtents BIGINT
	,UsedExtents BIGINT
	,dbname VARCHAR(255)
	,FileName VARCHAR(255)
	);

DECLARE c1 CURSOR FAST_FORWARD
FOR
SELECT NAME
FROM #dbs1;

OPEN c1;

FETCH NEXT
FROM c1
INTO @name;

WHILE @@fetch_status = 0
BEGIN
	SET @sql = 'use [' + @name + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS;'

	INSERT #dbsize1
	EXEC (@sql);

	UPDATE #dbs1
	SET Size = (
			SELECT sum(TotalExtents) / 16
			FROM #dbsize1
			)
		,Used = (
			SELECT sum(UsedExtents) / 16
			FROM #dbsize1
			)
	WHERE NAME = @name;

	TRUNCATE TABLE #dbsize1;

	FETCH NEXT
	FROM c1
	INTO @name;
END;

CLOSE c1;

DEALLOCATE c1;

SELECT *
FROM #dbs1
ORDER BY NAME;

DROP TABLE #dbsize1;

DROP TABLE #dbs1;

DROP TABLE #ls;
