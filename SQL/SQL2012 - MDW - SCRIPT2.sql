USE [MDW]
GO

DROP TABLE [custom_snapshots].[SERGIO_DATA]
GO

DROP TABLE [custom_snapshots].[SERGIO_VERSION]
GO




/****** Object:  Table [custom_snapshots].[metadata_table_blockers]    Script Date: 27/08/2014 16:48:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [custom_snapshots].[SERGIO_DATA](
	[DATA] [DATETIME] NULL,

	[database_name] [nvarchar](128) NULL,
	[collection_time] [datetimeoffset](7) NULL,
	[snapshot_id] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IDX_metadata_table_blockers]    Script Date: 27/08/2014 16:48:22 ******/
CREATE NONCLUSTERED INDEX [IDX_SERGIO_DATA] ON [custom_snapshots].[SERGIO_DATA]
(
	[snapshot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [custom_snapshots].[SERGIO_DATA]  WITH CHECK ADD  CONSTRAINT [FK_SERGIO_DATA_snapshots_internal] FOREIGN KEY([snapshot_id])
REFERENCES [core].[snapshots_internal] ([snapshot_id])
ON DELETE CASCADE
GO

ALTER TABLE [custom_snapshots].[SERGIO_DATA] CHECK CONSTRAINT [FK_SERGIO_DATA_snapshots_internal]
GO

/****** Object:  Table [custom_snapshots].[metadata_table_blockers]    Script Date: 27/08/2014 16:48:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [custom_snapshots].[SERGIO_VERSION](
	[VERSION] [NVARCHAR](MAX) NULL,
	[DB_NAME] [SYSNAME] NULL,

	[database_name] [nvarchar](128) NULL,
	[collection_time] [datetimeoffset](7) NULL,
	[snapshot_id] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IDX_metadata_table_blockers]    Script Date: 27/08/2014 16:48:22 ******/
CREATE NONCLUSTERED INDEX [IDX_SERGIO_VERSION] ON [custom_snapshots].[SERGIO_VERSION]
(
	[snapshot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [custom_snapshots].[SERGIO_VERSION]  WITH CHECK ADD  CONSTRAINT [FK_SERGIO_VERSION_snapshots_internal] FOREIGN KEY([snapshot_id])
REFERENCES [core].[snapshots_internal] ([snapshot_id])
ON DELETE CASCADE
GO

ALTER TABLE [custom_snapshots].[SERGIO_VERSION] CHECK CONSTRAINT [FK_SERGIO_VERSION_snapshots_internal]






USE msdb

DECLARE @collection_set_id INT = (SELECT collection_set_id FROM syscollector_collection_sets WHERE name = 'TESTE SERGIO')
IF (@collection_set_id IS NOT NULL)
	EXEC [msdb].[dbo].[sp_syscollector_delete_collection_set] @collection_set_id = @collection_set_id

GO


Begin Transaction
Begin Try
Declare @collection_set_id_15 int
Declare @collection_set_uid_16 uniqueidentifier
EXEC [msdb].[dbo].[sp_syscollector_create_collection_set] @name=N'TESTE SERGIO', @collection_mode=0, 
@description=N'TESTE SERGIO', @logging_level=0, @days_until_expiration=14, @schedule_name=N'CollectorSchedule_Every_15min', 
@collection_set_id=@collection_set_id_15 OUTPUT, @collection_set_uid=@collection_set_uid_16 OUTPUT

Select @collection_set_id_15, @collection_set_uid_16

Declare @collector_type_uid_17 uniqueidentifier
Select @collector_type_uid_17 = collector_type_uid From [msdb].[dbo].[syscollector_collector_types] Where name = N'Generic T-SQL Query Collector Type';
Declare @collection_item_id_18 int

EXEC [msdb].[dbo].[sp_syscollector_create_collection_item] @name=N'TESTE1', @parameters=N'
<ns:TSQLQueryCollector xmlns:ns="DataCollectorType">
<Query>
	<Value>
		SET NOCOUNT ON
		SELECT DATA = GETDATE()
	</Value>
	<OutputTable>SERGIO_DATA</OutputTable>
</Query>

<Query>
	<Value>
		SELECT VERSION = @@VERSION, DB_NAME = DB_NAME()
	</Value>
	<OutputTable>SERGIO_VERSION</OutputTable>
	
</Query>
<Databases UseUserDatabases="true"><Database>master</Database></Databases>

</ns:TSQLQueryCollector>
', @collection_item_id=@collection_item_id_18 OUTPUT, @frequency=60, @collection_set_id=@collection_set_id_15, @collector_type_uid=@collector_type_uid_17
Select @collection_item_id_18

Declare @collector_type_uid_19 uniqueidentifier
Select @collector_type_uid_19 = collector_type_uid From [msdb].[dbo].[syscollector_collector_types] Where name = N'Performance Counters Collector Type';
Declare @collection_item_id_20 int
EXEC [msdb].[dbo].[sp_syscollector_create_collection_item] @name=N'SERGIO - Performance Counters', 
@parameters=N'<ns:PerformanceCountersCollector xmlns:ns="DataCollectorType">
<PerformanceCounters Objects="Process" Counters="% Processor Time" Instances="*" />
</ns:PerformanceCountersCollector>', @collection_item_id=@collection_item_id_20 OUTPUT, @frequency=60, @collection_set_id=@collection_set_id_15, @collector_type_uid=@collector_type_uid_19
Select @collection_item_id_20

Commit Transaction;
End Try
Begin Catch
Rollback Transaction;
DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorNumber INT;
DECLARE @ErrorLine INT;
DECLARE @ErrorProcedure NVARCHAR(200);
SELECT @ErrorLine = ERROR_LINE(),
       @ErrorSeverity = ERROR_SEVERITY(),
       @ErrorState = ERROR_STATE(),
       @ErrorNumber = ERROR_NUMBER(),
       @ErrorMessage = ERROR_MESSAGE(),
       @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');
RAISERROR (14684, @ErrorSeverity, 1 , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);

End Catch;

GO


