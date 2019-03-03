IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spIndexTunning]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spIndexTunning]
GO
/*
	EXEC [spIndexTunning] @DEBUG = 1
*/
CREATE PROCEDURE [dbo].[spIndexTunning]
(
	@DEBUG BIT = 0
)
AS
	-- ensure a USE <databasename> statement has been executed first.
	SET NOCOUNT ON
	DECLARE @objectid int
	DECLARE @indexid int
	DECLARE @partitioncount bigint
	DECLARE @schemaname sysname
	DECLARE @objectname sysname
	DECLARE @indexname sysname
	DECLARE @partitionnum bigint
	DECLARE @partitions bigint
	DECLARE @frag float
	DECLARE @command varchar(8000)
	-- ensure the temporary table does not exist
	IF EXISTS (SELECT name FROM sys.objects WHERE name = 'work_to_do')
		DROP TABLE work_to_do
	-- conditionally select from the function, converting object and index IDs to names.
	SELECT
		object_id AS objectid,
		index_id AS indexid,
		partition_number AS partitionnum,
		avg_fragmentation_in_percent AS frag
	INTO work_to_do
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')
	WHERE avg_fragmentation_in_percent > 10.0 AND index_id > 0
	-- Declare the cursor for the list of partitions to be processed.
	DECLARE partitions CURSOR FOR SELECT * FROM work_to_do

	-- Open the cursor.
	OPEN partitions

	-- Loop through the partitions.
	FETCH NEXT
	   FROM partitions
	   INTO @objectid, @indexid, @partitionnum, @frag

	WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @objectname = o.name, @schemaname = s.name
			FROM sys.objects AS o
			JOIN sys.schemas as s ON s.schema_id = o.schema_id
			WHERE o.object_id = @objectid

			SELECT @indexname = name 
			FROM sys.indexes
			WHERE  object_id = @objectid AND index_id = @indexid

			SELECT @partitioncount = count (*) 
			FROM sys.partitions
			WHERE object_id = @objectid AND index_id = @indexid

	-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding
	IF @frag < 30.0
		BEGIN
		SELECT @command = 'ALTER INDEX ' + @indexname + ' ON ' + @schemaname + '.' + @objectname + ' REORGANIZE'
		IF @partitioncount > 1
			SELECT @command = @command + ' PARTITION=' + CONVERT (CHAR, @partitionnum)
		IF @DEBUG = 0
			EXEC (@command)
		END

	IF @frag >= 30.0
		BEGIN
		SELECT @command = 'ALTER INDEX ' + @indexname +' ON ' + @schemaname + '.' + @objectname + ' REBUILD'
		IF @partitioncount > 1
			SELECT @command = @command + ' PARTITION=' + CONVERT (CHAR, @partitionnum)
		IF @DEBUG = 0
			EXEC (@command)
		END
	IF @DEBUG = 0
		PRINT 'Executed ' + @command
	ELSE
		PRINT 'DEBUG ' + @command

	FETCH NEXT FROM partitions INTO @objectid, @indexid, @partitionnum, @frag
	END
	-- Close and deallocate the cursor.
	CLOSE partitions
	DEALLOCATE partitions

	-- drop the temporary table
	IF EXISTS (SELECT name FROM sys.objects WHERE name = 'work_to_do')
		DROP TABLE work_to_do
GO
