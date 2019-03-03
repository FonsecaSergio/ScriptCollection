declare @name varchar(50)
declare @errorsave int
declare @tab_name varchar(100)

SET @errorsave = 0
SET @tab_name = 'COSTLOG'


if (rtrim(@tab_name) = '') 
	RAISERROR ('A non-zero length table name parameter is expected', 16, 1)	

BEGIN TRAN



--INDICES (SEM PK)
if exists (select name from sysindexes
where id = object_id(@tab_name) and indid > 0 and indid < 255 and (status & 64)=0 AND NAME NOT IN (SELECT Name FROM SYSOBJECTS WHERE XTYPE = 'PK'))
begin 
	declare ind_cursor cursor for 
	select name from sysindexes
	where id = object_id(@tab_name) and indid > 0 and indid < 255 and (status & 64)=0 AND NAME NOT IN (SELECT Name FROM SYSOBJECTS WHERE XTYPE = 'PK')

	open ind_cursor
	fetch next from ind_cursor into @name
	while (@@fetch_status = 0)
	begin 
		

		exec ('drop index ' + @tab_name + '.' + @name)
		set @errorsave = @errorsave + @@error
		
		fetch next from ind_cursor into @name
	end
	close ind_cursor
	deallocate ind_cursor
end 


--INDICES (COM PK)
if exists (select name from sysindexes
where id = object_id('COSTLOG') and indid > 0 and indid < 255 and (status & 64)=0 AND NAME IN (SELECT Name FROM SYSOBJECTS WHERE XTYPE = 'PK'))
begin 
	declare ind_cursor cursor for 
	select name from sysindexes
	where id = object_id(@tab_name) and indid > 0 and indid < 255 and (status & 64)=0 AND NAME IN (SELECT Name FROM SYSOBJECTS WHERE XTYPE = 'PK')

	open ind_cursor
	fetch next from ind_cursor into @name
	while (@@fetch_status = 0)
	begin 
		

		exec ('ALTER TABLE ' + @tab_name + ' DROP CONSTRAINT ' + @name)
		set @errorsave = @errorsave + @@error
		
		fetch next from ind_cursor into @name
	end
	close ind_cursor
	deallocate ind_cursor
end 


if (@errorsave = 0)
BEGIN
	COMMIT TRAN
	SELECT 'INDICES FORAM DELETADOS'
END
else
BEGIN
	ROLLBACK TRAN
	RAISERROR ('ERRO INDICES NÃO FORAM DELETADOS',16,1)
END

GO
