
IF (OBJECT_ID('tempdb..#TEMP_REQUESTS') IS NOT NULL)
	DROP TABLE #TEMP_REQUESTS 
IF (OBJECT_ID('tempdb..#TEMP_SESSIONS') IS NOT NULL)
	DROP TABLE #TEMP_SESSIONS
IF (OBJECT_ID('tempdb..#TEMP_CONNECTIONS') IS NOT NULL)
	DROP TABLE #TEMP_CONNECTIONS

SELECT * INTO #TEMP_REQUESTS 
FROM SYS.dm_exec_requests

SELECT * INTO #TEMP_SESSIONS
FROM SYS.dm_exec_sessions

SELECT * INTO #TEMP_CONNECTIONS
FROM SYS.dm_exec_connections

---------------------------------------------------------------------------
;WITH AUX AS -- BLOCKERS AND BLOCKEDS
(
	SELECT S.session_id, R.blocking_session_id
	FROM #TEMP_SESSIONS S
	LEFT JOIN #TEMP_REQUESTS R
		ON S.session_id = R.session_id
	where S.session_id IN (
		SELECT DISTINCT blocking_session_id FROM #TEMP_REQUESTS where blocking_session_id <> 0 -- BLOCKERS
		UNION ALL
		SELECT session_id FROM #TEMP_REQUESTS where blocking_session_id <> 0 -- BLOCKEDS
	)
),
HEAD_BLOCKER AS
(
	SELECT LEVEL = 1,A.session_id, A.blocking_session_id 
	FROM AUX A where blocking_session_id IS NULL

	UNION ALL

	SELECT LEVEL = LEVEL + 1,A.session_id, A.blocking_session_id 
	FROM AUX A
	INNER JOIN HEAD_BLOCKER B
		ON A.blocking_session_id = B.session_id

)
SELECT 
	A.LEVEL
	,A.session_id
	,A.blocking_session_id
	,REQUEST_session_id = C.session_id
	,CONNECTION_LastQuery = D.text
	,REQUEST_LastBatch = E.text
	,REQUEST_LastPlan = F.query_plan
FROM HEAD_BLOCKER A
INNER JOIN #TEMP_CONNECTIONS B
	ON A.session_id = B.session_id
LEFT JOIN #TEMP_REQUESTS C
	ON A.session_id = C.session_id
OUTER APPLY sys.dm_exec_sql_text(B.most_recent_sql_handle) D
OUTER APPLY sys.dm_exec_sql_text(C.sql_handle) E
OUTER APPLY sys.dm_exec_query_plan(C.plan_handle) F


