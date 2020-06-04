select 
    p.*, 
    q.*,
    cp.plan_handle
from 
    sys.dm_exec_cached_plans cp
    cross apply sys.dm_exec_query_plan(cp.plan_handle) p
    cross apply sys.dm_exec_sql_text(cp.plan_handle) as q
where 
    cp.cacheobjtype = 'Compiled Plan' and
    p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
        max(//p:RelOp/@Parallel)', 'float') > 0 