select 
    cur.* 
from 
    sys.dm_exec_connections con
    cross apply sys.dm_exec_cursors(con.session_id) as cur
where
    cur.fetch_buffer_size = 1 
    and cur.properties LIKE 'API%'	-- API cursor (Transact-SQL cursors 
