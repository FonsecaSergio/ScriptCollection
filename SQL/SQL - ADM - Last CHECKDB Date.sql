/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

CREATE TABLE #DBInfo (
       Id INT IDENTITY(1,1), 
       ParentObject VARCHAR(255),
       [Object] VARCHAR(255),
       Field VARCHAR(255),
       [Value] VARCHAR(255)
)

CREATE TABLE #Value(
DatabaseName VARCHAR(255),
LastDBCCCHeckDB_RunDate VARCHAR(255)
)

EXECUTE SP_MSFOREACHDB'INSERT INTO #DBInfo Execute (''DBCC DBINFO ( ''''?'''') WITH TABLERESULTS'');
INSERT INTO #Value (DatabaseName) SELECT [Value] FROM #DBInfo WHERE Field IN (''dbi_dbname'');
UPDATE #Value SET LastDBCCCHeckDB_RunDate=(SELECT TOP 1 [Value] FROM #DBInfo WHERE Field IN (''dbi_dbccLastKnownGood'')) where LastDBCCCHeckDB_RunDate is NULL;
TRUNCATE TABLE #DBInfo';

SELECT * FROM #Value

DROP TABLE #DBInfo
DROP TABLE #Value