--http://www.sqlservercentral.com/scripts/Maintenance+and+Management/31867/

-- Overview of DMV's other objects for 
-- Troubleshooting Service Broker
--
set nocount on
go
 use msdb ;  -- for forwarding messages
go
--  use [The correct database !!] ;

-- use Traveloffice;

go

Select @@Servername + ' - '+ db_name()  as [ServerName - DbName] 
go
--
Select '*** Read the sqlserver''s ERRORLOG !!! ***' as Servicemessage
-- use TravelOffice
select *
from sys.transmission_queue
order by enqueue_time, message_sequence_number
;

-- When SQL Server needs a database master key to decrypt or encrypt a key, 
--	SQL Server tries to decrypt the database master key with the service master key 
--	of the instance. If the decryption fails, SQL Server searches the credential 
--	store for master key credentials that have the same family GUID as the database 
--	for which it needs the master key. 
--	SQL Server then tries to decrypt the database master key with each 
--	matching credential until the decryption succeeds or there are no 
--	more credentials. 
select *
from sys.master_key_passwords 
;
select MKP.*
, D.name as DbName
from master.sys.master_key_passwords MKP
inner join master.sys.credentials C
on MKP.credential_id = C.credential_id
left join master.sys.database_recovery_status DRS
on MKP.family_guid = DRS.family_guid
left join master.sys.databases D
on DRS.database_id = D.Database_id
;

select * 
from master.sys.endpoints 
where type_desc='SERVICE_BROKER'
;

select * 
from sys.services
;


SELECT name, is_broker_enabled , service_broker_guid
FROM sys.databases
WHERE database_id = DB_ID() 
;

select * 
from sys.routes
;

SELECT tq.to_service_name as [No_Exact_Match_TransQueue_2_Routes]
, *
FROM sys.transmission_queue AS tq
WHERE NOT EXISTS
    (SELECT remote_service_name
     FROM sys.routes R
     WHERE lower(R.remote_service_name) = lower(tq.to_service_name) ) 
;

select * 
from sys.service_contracts
;


select * 
from sys.conversation_endpoints
;

select * 
from sys.service_contract_usages
;

select * 
from sys.remote_service_bindings
;

select * 
from sys.conversation_groups
;


select * 
from sys.service_broker_endpoints 
;


select * 
from sys.service_queues
;


select * 
from sys.service_message_types
;

select * 
from sys.service_queue_usages
;

select * 
from sys.service_contract_message_usages
;

select * 
from sys.message_type_xml_schema_collection_usages
;

select db_name(database_id) as DbName
, * 
from sys.dm_broker_queue_monitors
;

select db_name(database_id) as DbName
, * 
from sys.dm_broker_activated_tasks
;

select * 
from sys.dm_broker_connections 
;

select * 
from sys.dm_broker_forwarded_messages
;



go
use msdb;
if exists (select * from sys.routes where name <> 'AutoCreatedLocal')
 begin
	print '-- check forwarding routes in msdb !!! '
	select * from sys.routes;
 end
go

use master;
go
select name, is_broker_enabled 
from sys.databases 
order by name ;

go

/*
-- import sql-errorlog 
set nocount on
CREATE TABLE #ErrLog (SeqNo bigint identity(1,1) not null,  LogDate datetime, ProcessInfo varchar(50), LogText varchar(max))
INSERT INTO #ErrLog (LogDate,ProcessInfo,LogText)
EXEC sp_readerrorlog
SELECT *
FROM #ErrLog 
ORDER BY LogDate desc, SeqNo desc

drop table #ErrLog

*/
go
/*
-- If your sure you don't have any conversations you want to keep active you can use
-- this script to clean up all the garbage.  
use THECORRECTDATABASE-PLEASE

declare @handle uniqueidentifier

declare conv cursor for 
  select top ( PUT_YOUR_NUMBER_HERE ) conversation_handle 
	from sys.conversation_endpoints

open conv
fetch NEXT FROM conv into @handle

while @@FETCH_STATUS = 0
 Begin
   END Conversation @handle with cleanup
   fetch NEXT FROM conv into @handle
 End

close conv
deallocate conv


*/
