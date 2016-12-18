-- ===============================================
-- 現在のDBのロック詳細
-- ===============================================

USE Param_testDB
SELECT 
		[locks].[request_session_id]													AS	[spid],
		ISNULL(DB_NAME([resource_database_id]), '')							AS	[db_name],
		CASE	
			WHEN	[resource_type] = 'OBJECT'				THEN	OBJECT_NAME([resource_associated_entity_id])
			WHEN	[resource_associated_entity_id] =	0	THEN	''
			ELSE	OBJECT_NAME([p].[object_id])
		END																													AS [entity_name],
		[ind].[index_id]																									AS [index_id],
		[ind].[name]																										AS [index_name],
		ISNULL([locks].[resource_type], '')																		AS [resource_type],
		[locks].resource_description																				AS [resource_description],
		[locks].request_mode																							AS [request_mode],
		[locks].request_type																							AS [request_type],
		ISNULL([wait].[wait_duration_ms], 0)																	AS [wait_duration_ms],
		ISNULL([wait].[wait_type], N'')																			AS [wait_type],
		ISNULL([wait].[resource_description], N'')															AS [resource_description],
		ISNULL(CONVERT (varchar,[wait].[blocking_session_id]), '')									AS [blocking_session_id],
		ISNULL(REPLACE(REPLACE([query_text].[text],CHAR(13), ''), CHAR(10), ' '), N'')	AS [query_text],
		[plan].[query_plan]																							AS [query_plan]
FROM			[sys].[dm_tran_locks]													AS [locks] WITH (NOLOCK)
	LEFT JOIN	[sys].[partitions]														AS [p] WITH (NOLOCK)
			ON	[p].[partition_id]					= [locks].[resource_associated_entity_id]
	LEFT JOIN	[sys].[dm_os_waiting_tasks]										AS [wait] WITH (NOLOCK)
			ON	[locks].[lock_owner_address]	= [wait].[resource_address]
	LEFT JOIN	[sys].[indexes]															AS [ind] WITH (NOLOCK)
			ON	[p].[object_id]						= [ind].[object_id]
			AND	[p].[index_id]						= [ind].[index_id]
	LEFT JOIN	[sys].[dm_exec_requests]											AS [requests] WITH (NOLOCK)
			ON	[locks].[request_session_id]	= [requests].[session_id]
    OUTER APPLY	[sys].[dm_exec_sql_text]([requests].[sql_handle])	AS [query_text] 
	OUTER APPLY [sys].[dm_exec_query_plan]([requests].[plan_handle]) AS [plan] 
WHERE	resource_database_id = DB_ID()
	AND	resource_type <> 'DATABASE'
ORDER BY spid
OPTION (RECOMPILE)
