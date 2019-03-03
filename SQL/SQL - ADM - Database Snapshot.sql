USE [master]
GO
 
	DECLARE @execSql varchar(MAX)
	DECLARE @databaseName SYSNAME
	--Set the database name for which to kill the connections 
	SET @databaseName = 'TESTE_SNAPSHOT'
 
	IF DB_ID(@databaseName) IS NOT NULL
	BEGIN
		  -----------------------------------------------------------------------------
		  SET @execSql = ''
		  SET @execSql += 'ALTER DATABASE ' + @databaseName + CHAR(10)
		  SET @execSql += 'SET SINGLE_USER ' + CHAR(10)
		  SET @execSql += 'WITH ROLLBACK IMMEDIATE' + CHAR(10)
 
		  -----------------------------------------------------------------------------
		  -- Agora vamos realizar a tarefa de matar as conexões
		  SET @execSql = ''
		  SELECT 
				 @execSql = @execSql + 'KILL ' + convert(char(10), spid) + ' '
		  FROM master.dbo.sysprocesses 
		  WHERE 
				 db_name(dbid) = @databaseName 
				 and DBID <> 0 
				 and spid <> @@spid 
				 and spid > 50
           
		  EXEC(@execSql) 
 
		  -----------------------------------------------------------------------------
		  SET @execSql = ''
		  SET @execSql += 'ALTER DATABASE ' + @databaseName + CHAR(10)
		  SET @execSql += 'SET MULTI_USER ' + CHAR(10)
		  SET @execSql += 'WITH ROLLBACK IMMEDIATE' + CHAR(10)
		  EXEC(@execSql) 
		  -----------------------------------------------------------------------------
 
	END
GO

DROP DATABASE [TESTE_SNAPSHOT]
GO

CREATE DATABASE [TESTE_SNAPSHOT]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TESTE_SNAPSHOT', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TESTE_SNAPSHOT.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'TESTE_SNAPSHOT_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TESTE_SNAPSHOT_log.ldf' , SIZE = 504KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
GO

USE [TESTE_SNAPSHOT]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Table_1](
	[ID] [int] NULL,
	[nome] [varchar](50) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

INSERT INTO [dbo].[Table_1] ([ID],[nome])
VALUES (1,'TESTE 1')
GO
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE [TESTE_SNAPSHOT]
GO

SELECT * FROM [dbo].[Table_1]
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE DATABASE [TESTE_SNAPSHOT_BKP] 
ON
	( NAME = TESTE_SNAPSHOT , FILENAME =  'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data\TESTE_SNAPSHOT_BKP.ss' )
AS SNAPSHOT OF [TESTE_SNAPSHOT];
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE [TESTE_SNAPSHOT]
GO

INSERT INTO [dbo].[Table_1] ([ID],[nome])
VALUES (2,'TESTE 2')
GO

SELECT * FROM [dbo].[Table_1]
GO
SELECT * FROM [TESTE_SNAPSHOT_BKP].[dbo].[Table_1]
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE master
GO
 
DECLARE @execSql varchar(MAX)
DECLARE @databaseName SYSNAME
--Set the database name for which to kill the connections 
SET @databaseName = 'TESTE_SNAPSHOT'
 
IF DB_ID(@databaseName) IS NOT NULL
BEGIN
      -----------------------------------------------------------------------------
      SET @execSql = ''
      SET @execSql += 'ALTER DATABASE ' + @databaseName + CHAR(10)
      SET @execSql += 'SET SINGLE_USER ' + CHAR(10)
      SET @execSql += 'WITH ROLLBACK IMMEDIATE' + CHAR(10)
 
      -----------------------------------------------------------------------------
      -- Agora vamos realizar a tarefa de matar as conexões
      SET @execSql = ''
      SELECT 
             @execSql = @execSql + 'KILL ' + convert(char(10), spid) + ' '
      FROM master.dbo.sysprocesses 
      WHERE 
             db_name(dbid) = @databaseName 
             and DBID <> 0 
             and spid <> @@spid 
             and spid > 50
           
      EXEC(@execSql) 
 
      -----------------------------------------------------------------------------
      SET @execSql = ''
      SET @execSql += 'ALTER DATABASE ' + @databaseName + CHAR(10)
      SET @execSql += 'SET MULTI_USER ' + CHAR(10)
      SET @execSql += 'WITH ROLLBACK IMMEDIATE' + CHAR(10)
      EXEC(@execSql) 
      -----------------------------------------------------------------------------
 
END
GO


RESTORE DATABASE [TESTE_SNAPSHOT] from 
DATABASE_SNAPSHOT = 'TESTE_SNAPSHOT_BKP';
GO
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM [TESTE_SNAPSHOT].[dbo].[Table_1]
GO
SELECT * FROM [TESTE_SNAPSHOT_BKP].[dbo].[Table_1]
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [master]
GO

DROP DATABASE [TESTE_SNAPSHOT_BKP]
GO

