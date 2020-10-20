/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-10-20
************************************************/

SELECT * FROM sys.dm_operation_status

---------------------------------------

WHILE 
(
    SELECT TOP 1 state_desc
    FROM sys.dm_operation_status
    WHERE 
        1=1
        AND resource_type_desc = 'Database'
        AND major_resource_id = 'fonsecanetDW'
        --AND operation = 'ALTER DATABASE'
		AND operation = 'RESUME DATABASE'
		
    ORDER BY
        start_time DESC
) = 'IN_PROGRESS'
BEGIN
    RAISERROR('Scale operation in progress',0,0) WITH NOWAIT;
    WAITFOR DELAY '00:00:05';
END
PRINT 'Complete';
