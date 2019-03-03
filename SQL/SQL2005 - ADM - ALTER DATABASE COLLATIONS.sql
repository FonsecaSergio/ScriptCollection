USE master

SET NOCOUNT ON
DECLARE @DATABASE SYSNAME
DECLARE @QUERY VARCHAR(MAX)

DECLARE @COLLATION AS VARCHAR(100)
SET @COLLATION = 'Latin1_General_CI_AS'

IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL
      DROP TABLE #TEMP

SELECT name 
INTO #TEMP
FROM SYS.databases WHERE database_id > 4
AND name NOT LIKE 'ReportServer%'
AND name NOT LIKE 'AdventureWorks%'


WHILE (SELECT COUNT(*) FROM #TEMP) > 0
BEGIN
      SELECT TOP 1 @DATABASE = name FROM #TEMP

      -- Alterando a collation do banco de dados
      SET @QUERY = 'ALTER DATABASE [' + @DATABASE + '] COLLATE ' + @COLLATION
      PRINT @QUERY

      -- Verificando a collation do banco de dados após a alteração
      --SELECT DATABASEPROPERTYEX(@DATABASE,'Collation')

      -- Gerando as instruções de ALTER
      -- Gerar o ALTER <Tabela> e ALTER COLUMN <Coluna>
      
      SELECT 'USE ' + @DATABASE
      
      SET @QUERY = ''
      
      SET @QUERY = @QUERY + 'SELECT ''ALTER TABLE '' + TABLE_NAME + '' ALTER COLUMN '' + COLUMN_NAME + '' '' +' + CHAR(10)
      SET @QUERY = @QUERY + 'CASE' + CHAR(10)
      SET @QUERY = @QUERY + 'WHEN DATA_TYPE IN (''Text'',''NText'') THEN DATA_TYPE' + CHAR(10)
      SET @QUERY = @QUERY + 'WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN DATA_TYPE + ''(MAX)''' + CHAR(10)
      SET @QUERY = @QUERY + 'ELSE DATA_TYPE + ''('' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(4)) + '')''' + CHAR(10)
      SET @QUERY = @QUERY + 'END + '' COLLATE '' + ''' + @COLLATION + ''' + '' '' +' + CHAR(10)
      SET @QUERY = @QUERY + 'CASE IS_NULLABLE WHEN ''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END' + CHAR(10)
      SET @QUERY = @QUERY + 'FROM [' + @DATABASE + '].Information_Schema.Columns' + CHAR(10)
      SET @QUERY = @QUERY + 'WHERE COLLATION_NAME IS NOT NULL'

      EXEC (@QUERY)

      DELETE FROM #TEMP
      WHERE name = @DATABASE
END
