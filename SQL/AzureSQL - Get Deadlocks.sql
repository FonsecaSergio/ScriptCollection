/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/
--Run on USER DB
SELECT *
FROM sys.event_log
WHERE event_type = 'deadlock'
ORDER BY start_time DESC

-------------------------------------------------------------------------------------------------------------------------
--Run on MASTER
WITH CTE AS (
		SELECT CAST(event_data AS XML) AS [target_data_XML]
		FROM sys.fn_xe_telemetry_blob_target_read_file('dl', NULL, NULL, NULL)
		)

SELECT 
   target_data_XML.value('(/event/@timestamp)[1]', 'DateTime2') AS TIMESTAMP,
	target_data_XML.query('/event/data[@name=''xml_report'']/value/deadlock') AS deadlock_xml,
	target_data_XML.query('/event/data[@name=''database_name'']/value').value('(/value)[1]', 'nvarchar(100)') AS db_name
FROM CTE

-------------------------------------------------------------------------------------------------------------------------
--XE
-----------------------------------------------------------------------------
--1. Create the xevent as below.
-----------------------------------------------------------------------------
CREATE EVENT SESSION deadlock ON DATABASE ADD event database_xml_deadlock_report ADD TARGET package0.ring_buffer (SET max_memory = (3072))
	WITH (STARTUP_STATE = OFF)
GO

-----------------------------------------------------------------------------
---2. Start the collection
-----------------------------------------------------------------------------
ALTER EVENT SESSION deadlock ON DATABASE STATE = start;

-----------------------------------------------------------------------------
--3.After the deadlock happens, collect the details as below
-----------------------------------------------------------------------------
DECLARE @x XML;

SELECT @x = CAST(st.target_data AS XML)
FROM sys.dm_xe_database_sessions AS se
INNER JOIN sys.dm_xe_database_session_targets AS st ON se.address LIKE st.event_session_address
WHERE se.name = 'deadlock'

SELECT @x

-----------------------------------------------------------------------------
--4. Finally, you can drop the Xevent as below.
-----------------------------------------------------------------------------
ALTER EVENT SESSION deadlock ON DATABASE STATE = stop;

DROP EVENT SESSION deadlock ON DATABASE;
