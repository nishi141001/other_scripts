/***************************************/
-- wait_completed用の拡張イベント
-- (1)調査対象のセッションIDを確認して
-- 以下xxxをセッションIDに置換してから実行
-- 
-- (2)拡張イベントファイルの保存先も
-- 変更してから実行（37行目）
/***************************************/
CREATE EVENT SESSION [exec_query_wait] ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(sqlserver.sql_text)
    WHERE ([package0].[equal_uint64]([sqlserver].[session_id],(xxx)) AND [duration]>(0))),
ADD EVENT sqlserver.query_post_compilation_showplan(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.query_post_execution_showplan(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sp_statement_starting(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))),
ADD EVENT sqlserver.sql_statement_starting(SET collect_statement=(1)
    ACTION(sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(xxx))) 
ADD TARGET package0.event_file(SET filename=N'C:\Program Files\Microsoft SQL Server\MSSQL13.INS_NISHI2016\MSSQL\Log\wait_event.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [exec_query_wait] ON SERVER STATE = START
GO

-- ===============================
-- 別セッション(session_ID = xxx)でクエリ実行
-- ===============================

ALTER EVENT SESSION [exec_query_wait] ON SERVER STATE = STOP
GO
DROP EVENT SESSION [exec_query_wait] ON SERVER
GO	