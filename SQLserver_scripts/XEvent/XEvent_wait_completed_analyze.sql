/*******************************************************/
-- 拡張イベントwait_completedの集計用
/*******************************************************/

-- SQL Server2016なら
DROP TABLE IF EXISTS tempdb..#wait_analyze 
GO

-- SQL Server2014まで
/*
IF OBJECT_ID(N'tempdb..#wait_analyze', N'U') IS NOT NULL
	DROP TABLE #wait_analyze
GO
*/

CREATE TABLE #wait_analyze (event_data XML)
GO

INSERT INTO #wait_analyze (event_data)
SELECT CAST(event_data AS XML) AS wait_events
FROM sys.fn_xe_file_target_read_file(	  N'C:\Program Files\Microsoft SQL Server\MSSQL13.INS_NISHI2016\MSSQL\Log\wait_event*.xel'
														, NULL
														, NULL
														, NULL
														)
GO



SELECT 
	 [waits].[sql_text]
	,[waits].[wait_type]
	,COUNT([waits].[wait_type]) AS wait_count
	,SUM([waits].[duration_ms]) AS total_wait_time_ms
	,SUM([waits].[signal_duration_ms]) AS total_signal_wait_time_ms
	,SUM([waits].[duration_ms]) - SUM([waits].[signal_duration_ms]) AS total_resource_wait_time_ms
FROM (
	SELECT 
		 event_data.value ('(/event/@timestamp)[1]', 'DATETIME') AS [date]
		,event_data.value ('(/event/@name)[1]' , 'VARCHAR(255)') AS [name]
		,event_data.value ('(/event/data[@name = ''wait_type'']/text)[1]', 'VARCHAR(255)') AS [wait_type]
		,event_data.value ('(/event/data[@name = ''cpu_time'']/value)[1]', 'BIGINT') AS [cpu_time]
		,event_data.value ('(/event/data[@name = ''duration'']/value)[1]', 'BIGINT') AS [duration_ms]
		,event_data.value ('(/event/data[@name = ''signal_duration'']/value)[1]', 'BIGINT') AS [signal_duration_ms]
		,event_data.value ('(/event/action[@name = ''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS [sql_text]  
	FROM #wait_analyze
	WHERE event_data.value ('(/event/@name)[1]' , 'VARCHAR(255)') = 'wait_completed'
	) AS waits
GROUP BY [waits].[sql_text],[waits].[wait_type]
ORDER BY total_wait_time_ms DESC
GO

SELECT 
	 [waits].[sql_text] AS [sql_text]
	,[waits].[name] AS [event_name]
	,SUM([waits].[cpu_time_μs])/1000 AS [total_cpu_time_ms]
	,SUM([waits].[duration_μs])/1000 AS [total_elapsed_time_ms]
FROM (
	SELECT 
		 event_data.value ('(/event/@timestamp)[1]', 'DATETIME') AS [date]
		,event_data.value ('(/event/@name)[1]' , 'VARCHAR(255)') AS [name]
		,event_data.value ('(/event/data[@name = ''cpu_time'']/value)[1]', 'BIGINT') AS [cpu_time_μs]
		,event_data.value ('(/event/data[@name = ''duration'']/value)[1]', 'BIGINT') AS [duration_μs]
		,event_data.value ('(/event/action[@name = ''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS [sql_text]  
		,event_data.value ('(/event/data[@name = ''statement'']/value)[1]', 'VARCHAR(MAX)') AS [statement]
	FROM #wait_analyze
	WHERE 
		event_data.value ('(/event/@name)[1]' , 'VARCHAR(255)') IN (
																								 'query_post_compilation_showplan'
																								,'sql_statement_completed'
																								,'sp_statement_completed'
																								,'sql_batch_completed'
																								,'query_post_execution_showplan'
																								)
	) AS waits
GROUP BY [waits].[sql_text], [waits].[name]
