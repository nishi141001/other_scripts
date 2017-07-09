SELECT        	[sessions].[session_id]
                ,	[sessions].[status]
                ,	[sessions].[cpu_time] AS [cpu_time(ms)]
                ,	[sessions].[memory_usage]*8 AS [memory_usage(kb)]
                ,	[sessions].[total_scheduled_time] AS [total_scheduled_time(ms)]
                ,	[sessions].[total_elapsed_time] As [total_elapsed_time(ms)]
				,	[sessions].[logical_reads]*8 AS [logical_reads_in_session(kb)]
				,	[req].[logical_reads]*8 AS [logical_reads_in_request(kb)]
				,	[req].[granted_query_memory]*8 AS [granted_query_memory_in_request(kb)]
                ,	[sessions].[login_time]
                ,	[sessions].[last_request_end_time]
                ,	[req].[start_time]
                ,	[req].[command]
                ,	[sessions].[host_name]
                ,	[sessions].[login_name]
                ,	[sessions].[nt_domain]
                ,	[sessions].[nt_user_name]
                ,	[sessions].[program_name]
				,	[sessions].[client_interface_name]
				,	[con].[client_net_address]
                ,	[con].[client_tcp_port]
                ,	[req].[percent_complete]
                ,	[req].[estimated_completion_time]
				,	[inp_buf].[event_type]
				,	[inp_buf].[event_info]
				,	[exec_text].[text] AS [most_recent_sql]
                ,	CASE 
				WHEN [req].sql_handle IS NOT NULL THEN (
					SELECT TOP 1 
						SUBSTRING(t2.text, ([req].[statement_start_offset] + 2) / 2, 
							( 
							(CASE 
								WHEN	[req].[statement_end_offset] = -1 THEN ((LEN(CONVERT(NVARCHAR(MAX),[t2].[text]))) * 2) 
								ELSE		[req].[statement_end_offset]
							END) - [req].[statement_start_offset]
							) / 2
						) 
					FROM sys.dm_exec_sql_text([req].[sql_handle]) AS [t2] 
					)
				ELSE ''
			END  AS [running_sql_text] 
		,	[sql_plan].[query_plan] AS [sql_plan]
FROM sys.dm_exec_sessions AS [sessions]
LEFT OUTER JOIN sys.dm_exec_connections AS [con]  
	　　 ON ( [sessions].[session_id] = [con].[session_id] )
LEFT OUTER JOIN sys.dm_exec_requests [req]  
	     ON ( 	 [req].[session_id] = [con].[session_id] 
		AND	 [req].[connection_id] = [con].[connection_id] )
CROSS APPLY	sys.dm_exec_input_buffer([sessions].[session_id], NULL) AS [inp_buf]
OUTER APPLY	sys.dm_exec_sql_text([con].[most_recent_sql_handle]) AS [exec_text]
OUTER APPLY	sys.dm_exec_query_plan([req].plan_handle) AS [sql_plan]
WHERE	[sessions].[is_user_process] = 1
ORDER BY [sessions].[session_id]
