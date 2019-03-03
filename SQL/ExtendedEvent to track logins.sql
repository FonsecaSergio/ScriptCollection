DROP EVENT SESSION [login] ON SERVER 
GO

CREATE EVENT SESSION [login] ON SERVER 
ADD EVENT sqlserver.login(
	SET collect_database_name=(1)
    ACTION(sqlserver.username))

--DETAILED FILE
	--ADD TARGET package0.event_file(SET filename=N'C:\TEMP\login.xel'),
--ONLY HISTOGRAM
	ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.login',slots=(1000),source=N'sqlserver.username')

WITH 
(
	 MAX_MEMORY=256 Mb -- MEM to keep the events
	,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS
	,MAX_DISPATCH_LATENCY=30 SECONDS
	,MAX_EVENT_SIZE=0 KB
	,MEMORY_PARTITION_MODE=NONE
	,TRACK_CAUSALITY=OFF
	,STARTUP_STATE=ON  --STARTUP_STATE=ON if server restarts I starts again
)
GO

/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
conditions contained within the Premier Customer Services Description.

*/
