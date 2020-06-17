/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

USE master
GO
 
DECLARE @execSql varchar(MAX)
DECLARE @databaseName SYSNAME
--Set the database name for which to kill the connections 
SET @databaseName = 'DBNAME'
 
IF DB_ID(@databaseName) IS NOT NULL
BEGIN
      -----------------------------------------------------------------------------
      SET @execSql = ''
      SET @execSql += 'ALTER DATABASE ' + @databaseName + CHAR(10)
      SET @execSql += 'SET SINGLE_USER ' + CHAR(10)
      SET @execSql += 'WITH ROLLBACK IMMEDIATE' + CHAR(10)
 
      -----------------------------------------------------------------------------
      -- Agora vamos realizar a tarefa de matar as conexoes
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
