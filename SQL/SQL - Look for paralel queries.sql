/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/
SELECT 
    p.*,
    q.*,
    cp.plan_handle
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) p
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS q
WHERE cp.cacheobjtype = 'Compiled Plan'
    AND p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
        max(//p:RelOp/@Parallel)', 'float') > 0
