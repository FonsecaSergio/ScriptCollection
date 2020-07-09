/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

--Returns successful Azure SQL Database database connections, connection failures, and deadlocks. You can use this information to track or troubleshoot your database activity with SQL Database.
--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-event-log-azure-sql-database
SELECT * FROM sys.event_log

--Contains statistics for SQL Database database connectivity events, providing an overview of database connection successes and failures. For more information about connectivity events, see Event Types in sys.event_log (Azure SQL Database).
--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-connection-stats-azure-sql-database
SELECT * FROM sys.database_connection_stats

--Returns the edition (service tier), service objective (pricing tier) and elastic pool name, if any, for an Azure SQL database or an Azure SQL Data Warehouse. If logged on to the master database in an Azure SQL Database server, returns information on all databases. For Azure SQL Data Warehouse, you must be connected to the master database.
--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-service-objectives-azure-sql-database
SELECT d.name, slo.*    
FROM sys.databases d   
JOIN sys.database_service_objectives slo    
ON d.database_id = slo.database_id;  


SELECT * FROM sys.resource_usage

SELECT * FROM sys.server_resource_stats