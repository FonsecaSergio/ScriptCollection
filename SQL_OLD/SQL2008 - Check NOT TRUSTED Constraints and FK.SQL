SELECT 
       'FKs'
      ,[CHECA CONSTRAINTS] = 'DBCC CHECKCONSTRAINTS (' + NAME + ')'
      ,[ALTERA CONSTRAINTS COM TRY CATCH] = 'BEGIN TRY ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' WITH CHECK CHECK CONSTRAINT ' + NAME + ' END TRY BEGIN CATCH END CATCH'  
      ,[ALTERA CONSTRAINTS] = 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' WITH CHECK CHECK CONSTRAINT ' + NAME    
      ,OBJECT_NAME(parent_object_id)
FROM sys.foreign_keys where is_not_trusted = 1

UNION ALL
SELECT 
       'CHECK'
      ,[CHECA CONSTRAINTS] = 'DBCC CHECKCONSTRAINTS (' + NAME + ')'
      ,[ALTERA CONSTRAINTS COM TRY CATCH] = 'BEGIN TRY ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' WITH CHECK CHECK CONSTRAINT ' + NAME + ' END TRY BEGIN CATCH END CATCH'  
      ,[ALTERA CONSTRAINTS] = 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + ' WITH CHECK CHECK CONSTRAINT ' + NAME    
      ,OBJECT_NAME(parent_object_id)
FROM sys.check_constraints where is_not_trusted = 1
ORDER BY OBJECT_NAME(parent_object_id)

-------------------
--v2.0

SELECT 
       'FKs'
      ,[CHECA CONSTRAINTS] = 'DBCC CHECKCONSTRAINTS (''' + QUOTENAME(S.name) + '.' + QUOTENAME(FK.NAME) + ''')'
      ,[ALTERA CONSTRAINTS COM TRY CATCH] = 'BEGIN TRY ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(FK.parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(FK.NAME) + ' END TRY BEGIN CATCH END CATCH'  
      ,[ALTERA CONSTRAINTS] = 'ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(FK.parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(FK.NAME)
      ,[parent_object_id] = OBJECT_NAME(FK.parent_object_id)
FROM sys.foreign_keys FK
INNER JOIN sys.tables T
	ON FK.parent_object_id = T.object_id
INNER JOIN sys.schemas S
	ON T.schema_id = S.schema_id

where is_not_trusted = 1


UNION ALL
SELECT 
       'CHECK'
      ,[CHECA CONSTRAINTS] = 'DBCC CHECKCONSTRAINTS (''' + QUOTENAME(S.name) + '.' + QUOTENAME(CC.NAME) + ''')'
      ,[ALTERA CONSTRAINTS COM TRY CATCH] = 'BEGIN TRY ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(CC.parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(CC.NAME) + ' END TRY BEGIN CATCH END CATCH'  
      ,[ALTERA CONSTRAINTS] = 'ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(CC.parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(CC.NAME)    
      ,[parent_object_id] = OBJECT_NAME(CC.parent_object_id)
FROM sys.check_constraints CC
INNER JOIN sys.tables T
	ON CC.parent_object_id = T.object_id
INNER JOIN sys.schemas S
	ON T.schema_id = S.schema_id
where is_not_trusted = 1
ORDER BY parent_object_id


