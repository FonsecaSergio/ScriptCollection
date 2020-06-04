use master
go

SELECT
    percent_complete,
    start_time ,
    command, 
    b.name AS DatabaseName, --Most of the time will said Main but this is because db is not accesible
    DATEADD(ms,estimated_completion_time,GETDATE()) AS RemainTime,
    (estimated_completion_time/1000/60) AS MinutesToFinish

    FROM sys.dm_exec_requests a
    INNER JOIN sys.databases b 
    ON a.database_id = b.database_id
    WHERE command like '%restore%'
    or command like '%Backup%'
    AND estimated_completion_time > 0

