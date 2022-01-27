/************************************************
Author: ??? / Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2022-01-27
************************************************/

/*

ATTENTION: To capture the actual execution plan, the query that has performance issues must be running.

To find @session_id (SPID) and @pdw_node_id, you can follow this:

-- Here you can identify the request_id of the query that has performance issues:
select * from sys.dm_pdw_exec_requests 
where status = 'Running' 
order by submit_time desc

-- Here you will identify the query step (step_index) that is taking the longest (or the step that has been running for the longest time):
select * from sys.dm_pdw_request_steps 
where request_id = 'QID84788' -- fill in the query ID here

-- Here you will identify the query's spid (session_id) on the node:
select * from sys.dm_pdw_sql_requests 
where request_id = 'QID84844'  -- fill in the query ID here
and step_index = 1 -- fill in the step index here

	-- Depending on the step, spid can be retrieved from sys.dm_pdw_sql_requests or sys.dm_pdw_dms_workers 
	select pdw_node_id, distribution_id, sql_spid, * 
	from sys.dm_pdw_dms_workers 
	where request_id = N'QID84750' 
	and step_index = 1 
	and [type] like '%READER%'; 


*/

-- If you already have the @pdw_node_id and @session_id information you can consider placing the script snippet below 
-- in a .sql file (eg, captureall.sql). Remember to fill in the values of the @pdw_node_id and @session_id variables correctly:
declare @pdw_node_id int = 6 
declare @session_id int = 595 

-- Then, you can execute the command below from the command prompt:

	-- sqlcmd -S dwtestsvrscus.database.windows.net -d databasename -U username -P password -I -i .\captureall.sql -o .\all.txt -y0 

-- In this example, the result of the collection would be stored in the file all.txt


print 'sys.dm_pdw_nodes_exec_query_plan...'

select * from sys.dm_pdw_nodes_exec_query_plan 
where pdw_node_id = @pdw_node_id and session_id = @session_id 

print 'sys.dm_pdw_nodes_exec_text_query_plan...'

select * from  sys.dm_pdw_nodes_exec_text_query_plan
where pdw_node_id = @pdw_node_id and session_id = @session_id 

print 'sys.dm_pdw_nodes_exec_sql_text...'

select * from sys.dm_pdw_nodes_exec_sql_text 
where pdw_node_id = @pdw_node_id and session_id = @session_id 

print 'sys.dm_pdw_nodes_exec_query_statistics_xml...'

select * from sys.dm_pdw_nodes_exec_query_statistics_xml 
where pdw_node_id = @pdw_node_id and session_id = @session_id 
 
print 'sys.dm_pdw_nodes_exec_query_profiles...'

select * from sys.dm_pdw_nodes_exec_query_profiles 
where pdw_node_id = @pdw_node_id and session_id = @session_id 


