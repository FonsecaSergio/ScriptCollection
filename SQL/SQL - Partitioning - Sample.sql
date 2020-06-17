/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-06-17
************************************************/

SET NOCOUNT ON
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cleanup
----------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS [dbo].[PARTITIONED_TABLE]
GO
DROP TABLE IF EXISTS [dbo].[TABLE_INCLUSION]
GO
IF  EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'Sch_Test')
DROP PARTITION SCHEME [Sch_Test]
GO
IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'Pfn_Test')
DROP PARTITION FUNCTION [Pfn_Test]
GO
----------------------------------------------------------------------------------------------------------------------------------------------------------
--create function and partition schema
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PARTITION FUNCTION [Pfn_Test](smallint) 
AS 
		RANGE LEFT FOR VALUES (-32000)
GO

CREATE PARTITION SCHEME [Sch_Test] 
	AS PARTITION [Pfn_Test] ALL TO ([PRIMARY])
GO
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Create partitioned table
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE [PARTITIONED_TABLE]
(
	ID SMALLINT NOT NULL PRIMARY KEY,
	TESTE INT,
	TESTE2 INT
) ON [Sch_Test] (ID)

INSERT INTO PARTITIONED_TABLE
VALUES (-32000,1,1)
INSERT INTO PARTITIONED_TABLE
VALUES (-31999,2,2)

----------------------------------------------------------------------------------------------------------------------------------------------------------
--VERIFY DATA
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	'PARTITIONED_TABLE - INITIAL DATA'
	,$partition.[Pfn_Test](ID) as PARTITION
	,* 
FROM PARTITIONED_TABLE

----------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE second table
----------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT CHAR(10)+CHAR(10)+CHAR(10)

CREATE TABLE [TABLE_INCLUSION]
(
	ID SMALLINT NOT NULL/* PRIMARY KEY*/,
	TESTE INT,
	TESTE2 INT
) ON [PRIMARY] --[Sch_Test] (ID)

INSERT INTO [TABLE_INCLUSION]
VALUES (-31998,3,3)

ALTER TABLE dbo.TABLE_INCLUSION 
	ADD CONSTRAINT PK_TABLE_INCLUSION PRIMARY KEY CLUSTERED (ID) ON [PRIMARY]

ALTER TABLE dbo.TABLE_INCLUSION 
	ADD CONSTRAINT CK_TABLE_INCLUSION_ID CHECK (ID = -31998)

SELECT 'TABLE_INCLUSION', * FROM [TABLE_INCLUSION]

----------------------------------------------------------------------------------------------------------------------------------------------------------
--SPLIT AND SWITH PARTITION
----------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER PARTITION SCHEME [Sch_Test]
NEXT USED [PRIMARY]

ALTER PARTITION FUNCTION [Pfn_Test] ()
	SPLIT RANGE(-31999)

DECLARE @PARTITION AS INT
SELECT @PARTITION = fanout FROM sys.partition_functions WHERE NAME = 'Pfn_Test'
--SELECT @PARTITION as [@PARTITION]


ALTER TABLE [TABLE_INCLUSION]
	SWITCH TO [PARTITIONED_TABLE] PARTITION @PARTITION

----------------------------------------------------------------------------------------------------------------------------------------------------------
--VERIFIFY
----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
	'PARTITIONED_TABLE - FINAL DATA'
	,$partition.[Pfn_Test](ID) as PARTITION
	,* 
FROM PARTITIONED_TABLE

----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cleanup
----------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS [dbo].[PARTITIONED_TABLE]
GO
DROP TABLE IF EXISTS [dbo].[TABLE_INCLUSION]
GO
IF  EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'Sch_Test')
DROP PARTITION SCHEME [Sch_Test]
GO
IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'Pfn_Test')
DROP PARTITION FUNCTION [Pfn_Test]
GO


----------------------------------------------------------------------------------------------------------------------------------------------------------

SET NOCOUNT OFF



/*
SELECT $partition.[Pfn_Test](-32000)
SELECT $partition.[Pfn_Test](-31997)
SELECT $partition.[Pfn_Test](-31996)
SELECT $partition.[Pfn_Test](-31995)


SELECT * FROM sys.partition_range_values
SELECT * FROM sys.partition_functions
SELECT * FROM sys.partition_schemes
SELECT * FROM sys.partition_parameters
SELECT OBJECT_NAME(Object_ID),* FROM sys.partitions
*/