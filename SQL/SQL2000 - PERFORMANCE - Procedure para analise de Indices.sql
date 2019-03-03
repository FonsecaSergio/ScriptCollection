SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
ALTER PROCEDURE USP_DBshowcontig_single_db @name varchar(50)
AS
SET NOCOUNT ON

DECLARE @tablename VARCHAR (128)
DECLARE @dbname VARCHAR(20)
DECLARE @sql VARCHAR(1000)
DECLARE @inserttable VARCHAR(3200)

-- Create the table
CREATE TABLE #DBFRAGMENT (
	ObjectName VARCHAR (50),
	ObjectId INT,
	IndexName VARCHAR (100),
	IndexId INT,
	Lvl INT,
	CountPages INT,
	CountRows INT,
	MinRecSize INT,
	MaxRecSize INT,
	AvgRecSize INT,  
	ForRecCount INT,
	Extents INT,
	ExtentSwitches INT,
	AvgFreeBytes INT,
	AvgPageDensity INT,
	ScanDensity DECIMAL,
	BestCount INT,
	ActualCount INT,
	LogicalFrag DECIMAL,
	ExtentFrag DECIMAL
)

create table #tablename (table_name varchar(400))

--DECLARE DB Cursor
DECLARE databases CURSOR FOR
	SELECT NAME 
	FROM MASTER.DBO.SYSDATABASES
	WHERE NAME = @NAME
 
--Open the cursor
OPEN databases
FETCH NEXT FROM databases INTO @dbname

WHILE @@FETCH_STATUS = 0
 BEGIN
  set @sql = 'SELECT TABLE_NAME = NAME FROM ' + @dbname + '..SYSOBJECTS WHERE XTYPE =' + '''' + 'U' + ''''
  insert into #tablename exec(@sql)
  -- Declare cursor
  DECLARE tables CURSOR FOR
      SELECT TABLE_NAME
        FROM #tablename
  -- Open the cursor
  OPEN tables
  -- Loop through all the tables in the database
  FETCH NEXT FROM tables INTO @tablename
  WHILE @@FETCH_STATUS = 0
   BEGIN

     -- Do the showcontig of all indexes of the table
     INSERT INTO #DBFRAGMENT
     EXEC ('USE ' + @dbname + ' DBCC SHOWCONTIG (''' + @tablename + ''') WITH TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
     FETCH NEXT FROM tables INTO @tablename
   END


 select 
	ObjectName,
	ObjectId,
	IndexName,
	IndexId,
	Lvl,
	CountPages,
	CountRows,
	MinRecSize,
	MaxRecSize,
	AvgRecSize,
	ForRecCount,
	Extents,
	ExtentSwitches,
	AvgFreeBytes,
	AvgPageDensity,
	ScanDensity,
	BestCount,
	ActualCount,
	LogicalFrag,
	ExtentFrag
  FROM #DBFRAGMENT where ltrim(rtrim(#DBFRAGMENT.indexname))<> ''''

  -- Close and deallocate the cursor
  CLOSE tables
  DEALLOCATE tables
  delete from #tablename
  delete from #DBFRAGMENT 
  FETCH NEXT FROM databases INTO @dbname
 END

CLOSE databases
DEALLOCATE databases
drop table #tablename
--Delete the temporary table
DROP TABLE #DBFRAGMENT

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO