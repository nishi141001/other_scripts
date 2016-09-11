/*************************************************/
-- sp_who2
-- TOP SORT METRICS
/*************************************************/

-- ===============================================
-- 出力時のソートカラムを指定

-- @SORT_No
-- 1 : HighCPU
-- 2 : HighDiskIO
-- ===============================================

DECLARE @SORT_No	INT				;
SET @SORT_No      = '1'             ; -- FROM '1' or '2'

-- ===============================================
-- データ格納用のテーブル変数(@sp_who2_table)を宣言
-- ===============================================

DECLARE @sp_who2_table TABLE(
		SPID		INT				,
		Status		VARCHAR(MAX)	,
		Login		VARCHAR(MAX)	,
		HostName	VARCHAR(MAX)	,
		BlkBy		VARCHAR(MAX)	,
		DBName		VARCHAR(MAX)	,
		Command		VARCHAR(MAX)	,
		CPUTime		INT				,
		DiskIO		INT				,
		LastBatch	VARCHAR(MAX)	,
		ProgramName	VARCHAR(MAX)	,	
		SPID_		INT				,
		REQUESTID	INT
		)	;

-- ===============================================
-- テーブル変数(@sp_who2_table)に実行結果を挿入
-- ===============================================

INSERT INTO @sp_who2_table　
	EXEC sp_who2
	;

-- ===============================================
-- 実行結果をCPUTimeで降順ソートして出力
-- ===============================================

SELECT * FROM @sp_who2_table
	ORDER BY 
		  CASE @SORT_No
			  WHEN 1 THEN CPUTime
			  WHEN 2 THEN DiskIO
			  ELSE CPUTime
	  END DESC	
	  ;


