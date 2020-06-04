USE MDW

DECLARE @collection_set_id INT
DECLARE @collection_set_uid UNIQUEIDENTIFIER

SELECT @collection_set_id = collection_set_id, @collection_set_uid = collection_set_uid 
FROM msdb..syscollector_collection_sets WHERE name = 'TESTE SERGIO'

SELECT * FROM msdb..syscollector_collection_sets WHERE name = 'TESTE SERGIO'
select * FROM msdb..syscollector_collection_items where collection_set_id = @collection_set_id


SELECT TOP 1000 [source_id]
      ,[collection_set_uid]
      ,[instance_name]
      ,[days_until_expiration]
      ,[operator]
  FROM [MDW].[core].[source_info_internal]
  WHERE [collection_set_uid] = @collection_set_uid


  /****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [source_id]
      ,[snapshot_id]
      ,[snapshot_time_id]
      ,[snapshot_time]
      ,[valid_through]
      ,[instance_name]
      ,[collection_set_uid]
      ,[operator]
      ,[log_id]
  FROM [MDW].[core].[snapshots]
  WHERE [collection_set_uid] = @collection_set_uid


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [DATA]
      ,[database_name]
      ,[collection_time]
      ,[snapshot_id]
  FROM [MDW].[custom_snapshots].[SERGIO_DATA]

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [VERSION],[DB_NAME]
      ,[database_name]
      ,[collection_time]
      ,[snapshot_id]
  FROM [MDW].[custom_snapshots].[SERGIO_VERSION]