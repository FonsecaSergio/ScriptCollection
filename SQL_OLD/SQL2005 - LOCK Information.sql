SELECT  L.request_session_id AS SPID, 
        DB_NAME(L.resource_database_id) AS DatabaseName,
        O.Name AS LockedObjectName, 
        P.object_id AS LockedObjectId, 
        L.resource_type AS LockedResource, 
        L.request_mode AS LockType,
        ST.text AS SqlStatementText,        
        ES.login_name AS LoginName,
        ES.host_name AS HostName,
        TST.is_user_transaction as IsUserTransaction,
        AT.name as TransactionName,
        CN.auth_scheme as AuthenticationMethod
FROM    sys.dm_tran_locks L
        JOIN sys.partitions P ON P.hobt_id = L.resource_associated_entity_id
        JOIN sys.objects O ON O.object_id = P.object_id
        JOIN sys.dm_exec_sessions ES ON ES.session_id = L.request_session_id
        JOIN sys.dm_tran_session_transactions TST ON ES.session_id = TST.session_id
        JOIN sys.dm_tran_active_transactions AT ON TST.transaction_id = AT.transaction_id
        JOIN sys.dm_exec_connections CN ON CN.session_id = ES.session_id
        CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
WHERE   resource_database_id = db_id()
ORDER BY L.request_session_id