USE MASTER
go
SELECT start_time,
       percent_complete,
       command,
       b.name AS DatabaseName,
       -- MASTER will appear here because the database is not accesible yet.
       DATEADD(ms,estimated_completion_time,GETDATE()) AS StimatedCompletionTime,
      (estimated_completion_time/1000/60) AS MinutesToFinish
FROM sys.dm_exec_requests a
INNER JOIN sys.databases b ON a.database_id = b.database_id
WHERE command LIKE '%restore%'
OR command LIKE '%backup%'
AND estimated_completion_time > 0
