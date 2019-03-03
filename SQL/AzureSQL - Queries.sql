--Returns successful Azure SQL Database database connections, connection failures, and deadlocks. You can use this information to track or troubleshoot your database activity with SQL Database.
--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-event-log-azure-sql-database
SELECT * FROM sys.event_log

--Contains statistics for SQL Database database connectivity events, providing an overview of database connection successes and failures. For more information about connectivity events, see Event Types in sys.event_log (Azure SQL Database).
--https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-connection-stats-azure-sql-database
SELECT * FROM sys.database_connection_stats