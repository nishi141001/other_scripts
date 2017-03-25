USE master
GO

SET NOCOUNT ON
GO

/*********************************************/
-- sort
-- 0 : Total CPU Usage TOP100
-- 1 : Average CPU Usage TOP100
-- 2 : Total Elapsed Time TOP100
-- 3 : Average Elapsed Time TOP100
-- 4 : Total IO Page TOP100
-- 5 : Average IO Page TOP100
/*********************************************/
DECLARE @sort INT

SET @sort = 0

SELECT TOP 100 CASE 
		WHEN @sort = 0
			THEN rank() OVER (
					ORDER BY total_worker_time DESC
						,sql_handle
						,statement_start_offset
					)
		WHEN @sort = 1
			THEN rank() OVER (
					ORDER BY (total_worker_time + 0.0) / (execution_count * 1000) DESC
						,sql_handle
						,statement_start_offset
					)
		WHEN @sort = 2
			THEN rank() OVER (
					ORDER BY total_elapsed_time DESC
						,sql_handle
						,statement_start_offset
					)
		WHEN @sort = 3
			THEN rank() OVER (
					ORDER BY (total_elapsed_time + 0.0) / (execution_count * 1000) DESC
						,sql_handle
						,statement_start_offset
					)
		WHEN @sort = 4
			THEN rank() OVER (
					ORDER BY (total_logical_reads + total_logical_writes) DESC
						,sql_handle
						,statement_start_offset
					)
		WHEN @sort = 5
			THEN rank() OVER (
					ORDER BY (total_logical_reads + total_logical_writes) / (execution_count + 0.0) DESC
						,sql_handle
						,statement_start_offset
					)
		END AS [row_no]
	,db_name(st.dbid) AS [database_name]
	,creation_time
	,last_execution_time
	,(total_worker_time + 0.0) / 1000 AS [total_worker_time(ms)]
	,(total_worker_time + 0.0) / (execution_count * 1000) AS [AvgCPUTime(ms)]
	,(total_elapsed_time + 0.0) / 1000 AS [total_elapsed_time(ms)]
	,(total_elapsed_time + 0.0) / (execution_count * 1000) AS [AvgElapsedTime(ms)]
	,total_logical_reads AS [LogicalReads(page)]
	,total_logical_writes AS [logicalWrites(page)]
	,total_logical_reads + total_logical_writes AS [AggIO(page)]
	,(total_logical_reads + total_logical_writes) / (execution_count + 0.0) AS [AvgIO(page)]
	,execution_count
	,total_rows
	,st.TEXT AS [batch_query_text]
	,CASE 
		WHEN sql_handle IS NULL
			THEN ' '
		ELSE (
				SUBSTRING(st.TEXT, (qs.statement_start_offset + 2) / 2, (
						CASE 
							WHEN qs.statement_end_offset = - 1
								THEN LEN(CONVERT(NVARCHAR(MAX), st.TEXT)) * 2
							ELSE qs.statement_end_offset
							END - qs.statement_start_offset
						) / 2)
				)
		END AS [statement_query_text]
	,plan_generation_num
	,qp.query_plan
FROM sys.dm_exec_query_stats AS [qs]
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS [st]
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS [qp]
WHERE total_worker_time > 0
ORDER BY CASE 
		WHEN @sort = 0
			THEN total_worker_time
		WHEN @sort = 1
			THEN (total_worker_time + 0.0) / (execution_count * 1000)
		WHEN @sort = 2
			THEN total_elapsed_time
		WHEN @sort = 3
			THEN (total_elapsed_time + 0.0) / (execution_count * 1000)
		WHEN @sort = 4
			THEN (total_logical_reads + total_logical_writes)
		WHEN @sort = 5
			THEN (total_logical_reads + total_logical_writes) / (execution_count + 0.0)
		END DESC
OPTION (RECOMPILE)
