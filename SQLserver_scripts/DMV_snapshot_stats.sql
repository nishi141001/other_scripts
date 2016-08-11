/******************************************************/
-- DataCollectionDHWのsnapshotからSQLTextベースで抽出する
-- 残存期間はデフォルトで2weeks

-- collection_time sample
-- DECRARE @DateFrom datetime = '2016-03-01 00:00:00.000' ;
-- DECRARE @DateTo datetime = '2016-03-02 00:00:00.000' ;

-- TOP SORT METRICS
-- @SORT_No
-- 1 : HighExecution
-- 2 : HighAvgCPU
-- 3 : HighAvgElapsedTime
-- 4 : HighAvgPhisicalRead
-- 5 : HighAvgLogicalWrite
/******************************************************/
USE master 
GO
SET NOCOUNT ON
GO
/*****************************************************/
DECLARE @Search_words	NVARCHAR(50)	;
DECLARE @SORT_No		INT				;
DECLARE @DateFrom		datetime		; 
DECLARE @DateTo			datetime		;


SET @Search_words = 'a'			              ; -- Search word
SET @SORT_No      = '1'                       ; -- FROM '1' TO '5'
SET @DateFrom     = '2016-03-01 00:00:00.000' ;
SET @DateTo       = '2016-10-04 00:00:00.000' ;


SET @Search_words = CASE LEN(@Search_words)
			                 WHEN 0 THEN ''
			                 ELSE '%' + @Search_words + '%'
		                END
;		


SELECT TOP(100)
    CASE @SORT_No 
		  WHEN 1 THEN 'HighExecution' 
		  WHEN 2 THEN 'HighAvgCPU'
		  WHEN 3 THEN 'HighAvgElapsedTime'
		  WHEN 4 THEN 'HighAvgRead'
		  WHEN 5 THEN 'HighAvgWrite'
		  ELSE		  'HighExecution' 
	  END AS type, 
		[snap_text].[sql_handle]							,
		[snap_plan].[statement_start_offset]				,
		[snap_plan].[statement_end_offset]					,
		[snap_plan].[plan_generation_num]	AS [Recompile]	,
		 REPLACE(REPLACE(REPLACE(SUBSTRING([snap_text].[sql_text], ([snap_stats].[statement_start_offset] / 2) + 1, ((
                                                            CASE [snap_stats].[statement_end_offset]
	                                                             WHEN -1 THEN DATALENGTH([snap_text].[sql_text])
	                                                             ELSE [snap_stats].[statement_end_offset]
	                                                          END - [snap_stats].[statement_start_offset]) / 2) + 1),CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ')	AS [stmt_text],
		 REPLACE(REPLACE(REPLACE([snap_text].[sql_text],CHAR(13), ''), CHAR(10), ' '), CHAR(9), ' ')																	AS [batch_text],
		 [snap_plan].[query_plan]	,
		 DB_NAME([snap_text].[database_id])	AS [db_name]	,
		 [snap_stats].[creation_time]						,
		 [snap_stats].[last_execution_time]					,
		 [snap_stats].[execution_count]						,
		 [snap_stats].[snapshot_execution_count]			,
		 [snap_stats].[total_worker_time]					,
		 [snap_stats].[snapshot_worker_time]				,
		 [snap_stats].[min_worker_time]						,
		 [snap_stats].[max_worker_time]						,
		 [snap_stats].[total_physical_reads]				,
		 [snap_stats].[snapshot_physical_reads]				,
		 [snap_stats].[min_physical_reads]					,
		 [snap_stats].[max_physical_reads]					,
		 [snap_stats].[total_logical_reads]					,
		 [snap_stats].[snapshot_logical_reads]				,
		 [snap_stats].[min_logical_reads]					,
		 [snap_stats].[max_logical_reads]					,
		 [snap_stats].[total_elapsed_time]					,
		 [snap_stats].[snapshot_elapsed_time]				,
		 [snap_stats].[min_elapsed_time]					,
		 [snap_stats].[max_elapsed_time]					,
		 [snap_stats].[collection_time]						,
		 [snap_stats].[snapshot_id]							
  FROM [DMV_snapshot_DWH].[snapshots].[notable_query_text] AS [snap_text]	,
       [DMV_snapshot_DWH].[snapshots].[notable_query_plan] AS [snap_plan]	,
       [DMV_snapshot_DWH].[snapshots].[query_stats]        AS [snap_stats]
    WHERE [snap_text].[sql_handle] = [snap_plan].[sql_handle]
      AND [snap_text].[sql_handle] = [snap_stats].[sql_handle]
      AND [snap_plan].[statement_start_offset] = [snap_stats].[statement_start_offset]
      AND [snap_plan].[statement_end_offset] = [snap_stats].[statement_end_offset]
      AND [snap_text].[source_id] = [snap_plan].[source_id]
      AND [snap_plan].[plan_handle] = [snap_stats].[plan_handle]
      AND [snap_plan].[database_id] = [snap_text].[database_id]
      AND [snap_plan].[plan_generation_num] = [snap_stats].[plan_generation_num]
      AND [collection_time] 
				BETWEEN @DateFrom
                    AND @DateTo
      AND [snap_text].[sql_text] LIKE @Search_words
  ORDER BY 
 	  CASE @SORT_No
		  WHEN 1 THEN [execution_count]
		  WHEN 2 THEN [total_worker_time]  / [execution_count] / 1000.0
		  WHEN 3 THEN [total_elapsed_time] / [execution_count] / 1000.0
		  WHEN 4 THEN ([total_physical_reads] / [execution_count]) + ([total_logical_reads] / [execution_count]) 
		  WHEN 5 THEN [total_logical_writes]  / [execution_count]
		  ELSE [execution_count]
	  END DESC

  
  
