select top 50 
    sum(qs.total_worker_time) as total_cpu_time, 
    sum(qs.execution_count) as total_execution_count,
    count(*) as  number_of_statements, 
    qs.plan_handle,
	T.text
from 
    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) T
group by qs.plan_handle, T.text
order by sum(qs.total_worker_time) desc
