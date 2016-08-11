
SET NOCOUNT ON
GO
DECLARE @get_sql_handle VARBINARY(64);

-- *********************************************************
-- 【実行時の注意事項】
-- クエリオプション⇒「列のヘッダーを結果セットに含める」の☑を外し、
-- 上部メニューから「結果をファイルに出力」して、保存形式を.htmlにしてください。
-- sa接続してから実行してください。

-- 【実行前のインプット】
-- 枠内に対象①②を入力してから実行
-- ①今回対象となるDBの名前

	USE sales; --ここに調査対象のDB名を入力
	-- ex)USE sales
-- ②今回対象となるSQLハンドル

	SET @get_sql_handle =  0x02000000962E9C1112DB0C4263611A06B91AEC49B35B91890000000000000000000000000000000000000000
						-- ↑ここに調査対象のSQLハンドルを入力

-- =========================================================
-- sql_handleを探すのは以下SQLを実行する
/*
SELECT TOP 100
	[sql_handle],
	[total_elapsed_time] / [execution_count] / 1000.0 AS [Average Elapsed Time (ms)], 
	[total_worker_time]  / [execution_count] / 1000.0 AS [Average Worker Time (ms)], 
	[total_physical_reads] / [execution_count] AS [Average Physical Read Count], 
	[total_logical_reads] / [execution_count] AS [Average Logical Read Count], 
	[total_logical_writes]  / [execution_count] AS [Average Logical Write], 
	[total_elapsed_time] / 1000.0 AS [total_elapsed_time (ms)],
	[total_worker_time] / 1000.0  AS [total_worker_time (ms)],
	[total_physical_reads] AS [total_physical_reads (page)],
	[total_logical_reads] AS [total_logical_reads (page)],
	[total_logical_writes] AS [total_logical_writes (page)],
	[execution_count], 
	[total_rows],
	[last_rows],
	[max_rows],
	[plan_generation_num],
	[creation_time],
	[last_execution_time],
	DB_NAME(st.dbid) AS db_name,
	REPLACE(REPLACE(REPLACE(SUBSTRING(text, 
	([statement_start_offset] / 2) + 1, 
	((CASE [statement_end_offset]
	WHEN -1 THEN DATALENGTH(text)
	ELSE [statement_end_offset]
	END - [statement_start_offset]) / 2) + 1),CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [stmt_text],
	REPLACE(REPLACE(REPLACE([text],CHAR(13), ''), CHAR(10), ' '), CHAR(9), ' ') AS [text],
	[query_plan]
FROM
	[sys].[dm_exec_query_stats]
	CROSS APPLY 
	[sys].[dm_exec_sql_text]([sql_handle]) AS st
	CROSS APPLY
	[sys].[dm_exec_query_plan]([plan_handle])
WHERE
	text like '%jobs%'

*/
-- ========================================================
-- *********************************************************


/**********************************************************/
-- 取得内容一覧
-- 01_☑サーバ情報、☑エディション、☑パラメータ情報等
-- 02_☑テーブル定義、テーブル一覧,カラム情報、カーディナリティ
-- 03_☑統計情報　←未インデックス系の統計方法は別の方法で取得
-- 04_☑インデックス情報,インデックス一覧、不足しているインデックス
-- 05_未フルスキャン情報、暗黙型変換等のwarn情報
-- 06_☑一回あたりの動的管理ビュー,statementtext,今回のstatementが含まれるbatchtext
/**********************************************************/



-- ============================================================
-- 不要な一時テーブルを削除
-- ============================================================
IF OBJECT_ID(N'tempdb..#No_01' , N'U') IS NOT NULL DROP TABLE #No_01;
IF OBJECT_ID(N'tempdb..#REF_TABLE_COLUMN' , N'U') IS NOT NULL DROP TABLE #REF_TABLE_COLUMN ;
IF OBJECT_ID(N'tempdb..#REF_TABLE_COLUMN_LIST' , N'U') IS NOT NULL DROP TABLE #REF_TABLE_COLUMN_LIST ;
IF OBJECT_ID(N'tempdb..#No_02_01' , N'U') IS NOT NULL DROP TABLE #No_02_01	;
IF OBJECT_ID(N'tempdb..#No_02_02_01' , N'U') IS NOT NULL DROP TABLE #No_02_02_01	;
IF OBJECT_ID(N'tempdb..#No_02_02' , N'U') IS NOT NULL DROP TABLE #No_02_02	;
IF OBJECT_ID(N'tempdb..#No_02_03' , N'U') IS NOT NULL DROP TABLE #No_02_03	;
IF OBJECT_ID(N'tempdb..#STATS' , N'U') IS NOT NULL DROP TABLE #STATS;
IF OBJECT_ID(N'tempdb..#STATS_HEADER_TEMP' , N'U') IS NOT NULL DROP TABLE #STATS_HEADER_TEMP;
IF OBJECT_ID(N'tempdb..#STATS_DENSITY_TEMP' , N'U') IS NOT NULL DROP TABLE #STATS_DENSITY_TEMP;
IF OBJECT_ID(N'tempdb..#STATS_HISTOGRAM_TEMP' , N'U') IS NOT NULL DROP TABLE #STATS_HISTOGRAM_TEMP;
IF OBJECT_ID(N'tempdb..#STATS_HEADER' , N'U') IS NOT NULL DROP TABLE #STATS_HEADER;
IF OBJECT_ID(N'tempdb..#STATS_DENSITY' , N'U') IS NOT NULL DROP TABLE #STATS_DENSITY;
IF OBJECT_ID(N'tempdb..#STATS_HISTOGRAM' , N'U') IS NOT NULL DROP TABLE #STATS_HISTOGRAM;
IF OBJECT_ID(N'tempdb..#No_04_01' , N'U') IS NOT NULL DROP TABLE #No_04_01;
IF OBJECT_ID(N'tempdb..#No_04_02' , N'U') IS NOT NULL DROP TABLE #No_04_02;
IF OBJECT_ID(N'tempdb..#No_04_03' , N'U') IS NOT NULL DROP TABLE #No_04_03;
IF OBJECT_ID(N'tempdb..#No_06_01' , N'U') IS NOT NULL DROP TABLE #No_06_01;

-- ============================================================
-- 抽出したxmlプランを一時テーブルから取り出して処理するための変数
DECLARE @ref_column_xml xml; 
DECLARE @docHandle INT;
-- ============================================================
-- XMLを格納するための一時テーブル作成(in session)
CREATE TABLE #REF_TABLE_COLUMN ([ref_column] xml);
-- ============================================================
-- 参照したテーブルとカラムの一覧を一時テーブル作成(in session)
CREATE TABLE #REF_TABLE_COLUMN_LIST (
		 [database]                                        VARCHAR(255)
		,[Schema]                                          VARCHAR(255)
		,[Table]                                           VARCHAR(255)
		,[Alias]                                           VARCHAR(255)
		,[Column]                                          VARCHAR(255)
);
-- ============================================================
-- xmlplan用の名前空間を指定
WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)

-- ============================================================
-- 一時テーブルへinsert
INSERT INTO #REF_TABLE_COLUMN 

 SELECT 
  		 -- 一つのSQLハンドルから複数個のプランが採取できてしまう場合は最初の一つのみを使用する
       TOP(1)qp.query_plan.query('//sp:ColumnReference') 
 FROM  sys.dm_exec_query_stats AS [qs]
      CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS [qp]
      CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS [st]
		 WHERE 
				sql_handle = @get_sql_handle
;

-- プランのうち参照したカラム情報を含むxml情報を抽出
-- 変数へ代入+<ROOT>ノードを追加
SELECT @ref_column_xml = (
							SELECT ref_column FROM #REF_TABLE_COLUMN 
							FOR XML RAW('ROOT')
						);

EXEC sp_xml_preparedocument @docHandle OUTPUT,@ref_column_xml;
 WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)
 INSERT INTO #REF_TABLE_COLUMN_LIST
 SELECT 
	DISTINCT
	SUBSTRING([Database], 2, LEN([Database]) -2) AS [Database]	,
	SUBSTRING([Schema]  , 2, LEN([Schema])   -2) AS [Schema]	,
	SUBSTRING([Table]   , 2, LEN([Table])    -2) AS [Table]		,
	SUBSTRING([Alias]   , 2, LEN([Alias])    -2) AS [Alias]		,
	[Column]									 AS [Column]
	FROM OPENXML (@docHandle , '/ROOT/ref_column//' ,2)
	 WITH (		 
				 [Database]  VARCHAR(255) './@Database',
				 [Schema]    VARCHAR(255) './@Schema'  ,
				 [Table]     VARCHAR(255) './@Table'   ,
				 [Alias]     VARCHAR(255) './@Alias'   ,
				 [Column]    VARCHAR(255) './@Column'  
				 --[Index]     VARCHAR(255) '@Index'
		 )
	;

EXEC sp_xml_removedocument @docHandle;

/**********************************************************/
-- 01_サーバ情報、エディション、パラメータ情報等
/**********************************************************/
-- ============================================================
CREATE TABLE #No_01 (
						[MachineName]						sql_variant	,
						[ServerName]						sql_variant	,
						[InstanceName]						sql_variant	,
						[IsClustered]						sql_variant	,
						[ComputerNamePhysicalNetBIOS]		sql_variant	,
						[Edition]							sql_variant	,
						[ProductLevel]						sql_variant	,
						[ProductUpdateLevel]				sql_variant	,
						[ProductVersion]					sql_variant	,
						[ProductMajorVersion]				sql_variant	,
						[ProductMinorVersion]				sql_variant	,
						[ProductBuild]						sql_variant	,
						[ProductBuildType]					sql_variant	,
						[ProductUpdateReference]			sql_variant	,
						[ProcessID]							sql_variant	,
						[Collation]							sql_variant	,
						[IsFullTextInstalled]				sql_variant	,
						[IsIntegratedSecurityOnly]			sql_variant	,
						[FilestreamConfiguredLevel]			sql_variant	,
						[IsHadrEnabled]						sql_variant	,
						[HadrManagerStatus]					sql_variant	,
						[InstanceDefaultDataPath]			sql_variant	,
						[InstanceDefaultLogPath]			sql_variant	,
						[BuildClrVersion]					sql_variant	
						)
-- ============================================================
DECLARE @prop_exec_sql NVARCHAR(max)	;
SET @prop_exec_sql = 'USE master; '
SET @prop_exec_sql = @prop_exec_sql +
'SELECT 
      SERVERPROPERTY("@prop_tmp01") AS [MachineName]					, 
	  SERVERPROPERTY("@prop_tmp02") AS [ServerName]						,  
      SERVERPROPERTY("@prop_tmp03") AS [Instance]						, 
      SERVERPROPERTY("@prop_tmp04") AS [IsClustered]					, 
      SERVERPROPERTY("@prop_tmp05") AS [ComputerNamePhysicalNetBIOS]	, 
      SERVERPROPERTY("@prop_tmp06") AS [Edition]						, 
      SERVERPROPERTY("@prop_tmp07") AS [ProductLevel]					,
      SERVERPROPERTY("@prop_tmp08") AS [ProductUpdateLevel]				,
      SERVERPROPERTY("@prop_tmp09") AS [ProductVersion]					,
      SERVERPROPERTY("@prop_tmp10") AS [ProductMajorVersion]			, 
      SERVERPROPERTY("@prop_tmp11") AS [ProductMinorVersion]			, 
      SERVERPROPERTY("@prop_tmp12") AS [ProductBuild]					, 
      SERVERPROPERTY("@prop_tmp13") AS [ProductBuildType]				,	
      SERVERPROPERTY("@prop_tmp14") AS [ProductUpdateReference]			,
      SERVERPROPERTY("@prop_tmp15") AS [ProcessID]						,
      SERVERPROPERTY("@prop_tmp16") AS [Collation]						, 
      SERVERPROPERTY("@prop_tmp17") AS [IsFullTextInstalled]			, 
      SERVERPROPERTY("@prop_tmp18") AS [IsIntegratedSecurityOnly]		,
      SERVERPROPERTY("@prop_tmp19") AS [FilestreamConfiguredLevel]		,
      SERVERPROPERTY("@prop_tmp20") AS [IsHadrEnabled]					, 
      SERVERPROPERTY("@prop_tmp21") AS [HadrManagerStatus]				,
      SERVERPROPERTY("@prop_tmp22") AS [InstanceDefaultDataPath]		,
      SERVERPROPERTY("@prop_tmp23") AS [InstanceDefaultLogPath]			,
      SERVERPROPERTY("@prop_tmp24") AS [Build CLR Version];
'

SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp01"' ,'''MachineName'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp02"' ,'''ServerName'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp03"' ,'''InstanceName'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp04"' ,'''IsClustered'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp05"' ,'''ComputerNamePhysicalNetBIOS'''	);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp06"' ,'''Edition'''						);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp07"' ,'''ProductLevel'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp08"' ,'''ProductUpdateLevel'''			);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp09"' ,'''ProductVersion'''				);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp10"' ,'''ProductMajorVersion'''			);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp11"' ,'''ProductMinorVersion'''			);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp12"' ,'''ProductBuild'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp13"' ,'''ProductBuildType'''				);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp14"' ,'''ProductUpdateReference'''		);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp15"' ,'''ProcessID'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp16"' ,'''Collation'''					);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp17"' ,'''IsFullTextInstalled'''			);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp18"' ,'''IsIntegratedSecurityOnly'''		);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp19"' ,'''FilestreamConfiguredLevel'''	);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp20"' ,'''IsHadrEnabled'''				);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp21"' ,'''HadrManagerStatus'''			);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp22"' ,'''InstanceDefaultDataPath'''		);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp23"' ,'''InstanceDefaultLogPath'''		);
SET @prop_exec_sql = REPLACE ( @prop_exec_sql , '"@prop_tmp24"' ,'''BuildClrVersion'''				);

INSERT INTO #No_01 EXEC sp_executesql @prop_exec_sql;
/**********************************************************/
-- 02_テーブル定義、テーブル一覧
/**********************************************************/

/*
-- 複数結果セットを返すストアドをそれぞれ別々の一時テーブルに
-- と思ったけどできなかったため保留。。。
*/
-- =======================================================================
--  Temp Table No_02_01 = Column info
--  Temp Table No_02_02 = Index info
--  Temp Table No_02_03 = referenced or Check info
-- =======================================================================

-- =======================================================================
-- CREATE #No_02_01
CREATE TABLE #No_02_01(
						[Table_name] 					NVARCHAR(128)	,
						[Column_name] 					NVARCHAR(128)	,
						[Column_id] 					INT				,
						[Type]							NVARCHAR(128)	,
						[Nullable]						VARCHAR(35)		,
						[Length]						INT	    		,
						[Prec]					        CHAR(5)	   		,
						[Scale]					        CHAR(5)			,
						[Collation]						SYSNAME NULL	,
						[Computed]						VARCHAR(35)		,
						[Filestream]					VARCHAR(35)
            ) ;
-- =======================================================================
-- CREATE #No_02_02

CREATE TABLE #No_02_02_01(
						[index_name]			    SYSNAME NULL	,
						[index_description]			VARCHAR(210)	,
						[index_keys]			    NVARCHAR(2078)
						) ;

CREATE TABLE #No_02_02(	
						[Table_name] 			    NVARCHAR(128)	,
						[index_name]			    SYSNAME NULL	,
						[index_description]			VARCHAR(210)	,
						[index_keys]			    NVARCHAR(2078)
						) ;
-- =======================================================================
-- CREATE #No_02_03
CREATE TABLE #No_02_03(
						[CONSTRAINT_NAME] 					NVARCHAR(128)	,
						[DB_name] 							NVARCHAR(128)	,
						[Schema_name] 						NVARCHAR(128)	,
						[Table_name] 						NVARCHAR(128)	,
						[Column_name] 						NVARCHAR(128)	,
						[UPDATE_RULE] 						NVARCHAR(128)	,
						[DELETE_RULE] 						NVARCHAR(128)	,
						[Check_clause] 						NVARCHAR(256)
						) ;

-- =======================================================================
-- #No_02_01
INSERT INTO #No_02_01
SELECT
	[obj].[name]		AS [Table_name]		,
	[col].[name]		AS	[Column_name]	,
	[col].[column_id]	AS	[Column_id]		,	
	[typ].[name]		AS [Type]			,
	[col].[is_nullable]	AS [Nullable]		,
	[col].[max_length]	AS [Length]			,
	[col].[precision]	AS [Prec]			,
	[col].[scale]		AS [Scale]			,
	[col].[collation_name]					,
	[col].[is_computed]						,
	[col].[is_filestream]
FROM     sys.columns	AS [col](NOLOCK)	,        
		 sys.types		AS [typ](NOLOCK)	,
		 sys.objects	AS [obj](NOLOCK)
WHERE    
	[col].[object_id] = [obj].[object_id]		
AND      [col].[system_type_id]=[typ].[system_type_id]
AND      [obj].[name] IN (SELECT
					 			[Table] 
					 		FROM #REF_TABLE_COLUMN_LIST
						 ) 	


-- ========================================================================
-- #No_02_02			
-- 変数の宣言のみ
-- 実行はNo_03のカーソル内
DECLARE @index_exec_sql		 NVARCHAR(max)	;

SET @index_exec_sql		= N'INSERT INTO #No_02_02_01 EXEC sys.sp_helpindex "temp_@objname" ;'

-- #No_02_02			
-- ========================================================================
-- #No_02_03_01

		INSERT INTO #No_02_03
			SELECT
					DISTINCT ref.CONSTRAINT_NAME,
					col.TABLE_CATALOG			,
					col.TABLE_SCHEMA			,
					TABLE_NAME					,
					COLUMN_NAME					,
					UPDATE_RULE					,
					DELETE_RULE					,	
					'NULL'						
			FROM	INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS	AS ref,
					INFORMATION_SCHEMA.KEY_COLUMN_USAGE			AS col
			WHERE 
					ref.CONSTRAINT_NAME = col.CONSTRAINT_NAME
				AND TABLE_NAME  IN (SELECT
					 					[Table] 
					 				FROM #REF_TABLE_COLUMN_LIST
									) 
			;
-- #No_02_03_01
-- =========================================================================
-- #No_02_03_02
  INSERT INTO #No_02_03
	SELECT
						DISTINCT chk.CONSTRAINT_NAME	,
						col.TABLE_CATALOG				,
						col.TABLE_SCHEMA				,
						col.TABLE_NAME					,
						'NULL'							,
						'NULL'							,
						'NULL'							,
						chk.CHECK_CLAUSE
				FROM	INFORMATION_SCHEMA.CHECK_CONSTRAINTS	AS chk,
						INFORMATION_SCHEMA.KEY_COLUMN_USAGE		AS col
				WHERE 
					 col.TABLE_NAME  IN (SELECT
					 						[Table] 
					 					FROM #REF_TABLE_COLUMN_LIST
										) 
				;

-- #No_02_03_02
/**********************************************************/
-- 03_統計情報
/**********************************************************/
CREATE TABLE #STATS(
					[Schema_name]	NVARCHAR(255)	,
					[Table_name]	NVARCHAR(255)	,
					[Stat_name]		NVARCHAR(255) 
)
-- ============================================================
-- temp TABLE DBCC SHOW_STATISTICS
-- ============================================================
CREATE TABLE #STATS_HEADER_TEMP(
							[Name]					NVARCHAR(255)	,
							[Updated]				datetime2		,
							[Rows]					INT				,
							[Rows Sampled]			INT				,
							[Steps]					INT				,
							[Density]				FLOAT			,
							[Average key length]	FLOAT			,
							[String Index]			NVARCHAR(255)	,
							[Filter Expression]		NVARCHAR(255)	,
							[Unfiltered Rows]		INT
						) ;

CREATE TABLE #STATS_HEADER(
							[Table_name] 		    NVARCHAR(128)	,
							[Stat_name]			NVARCHAR(128)	,
							[Name]					NVARCHAR(255)	,
							[Updated]				datetime2		,
							[Rows]					INT				,
							[Rows Sampled]			INT				,
							[Steps]					INT				,
							[Density]				FLOAT			,
							[Average key length]	FLOAT			,
							[String Index]			NVARCHAR(255)	,
							[Filter Expression]		NVARCHAR(255)	,
							[Unfiltered Rows]		INT
						) ;

CREATE TABLE #STATS_DENSITY_TEMP(
							[ALL Density]			FLOAT			,
							[Average Length]		FLOAT			,
							[Columns]				NVARCHAR(255)
						) ;

CREATE TABLE #STATS_DENSITY(
							[Table_name] 		    NVARCHAR(128)	,
							[Stat_name]			NVARCHAR(128)	,
							[ALL Density]			FLOAT			,
							[Average Length]		FLOAT			,
							[Columns]				NVARCHAR(255)
						) ;

CREATE TABLE #STATS_HISTOGRAM_TEMP(
							[RANGE_HI_KEY]			NVARCHAR(MAX)	,
							[RANGE_ROWS]			INT				,
							[EQ_ROWS]				INT				,
							[DISTINCT_RANGE_ROWS]	INT				,
							[AVG_RANGE_ROWS]		INT
						) ;
CREATE TABLE #STATS_HISTOGRAM(
							[Table_name] 		    NVARCHAR(128)	,
							[Stat_name]			NVARCHAR(128)	,
							[RANGE_HI_KEY]			NVARCHAR(MAX)	,
							[RANGE_ROWS]			INT				,
							[EQ_ROWS]				INT				,
							[DISTINCT_RANGE_ROWS]	INT				,
							[AVG_RANGE_ROWS]		INT
						) ;

-- ============================================================
DECLARE	
		@exec_sql_header	NVARCHAR(max)	,
		@exec_sql_density	NVARCHAR(max)	,
		@exec_sql_histogram	NVARCHAR(max)	,
		@exec_sql			NVARCHAR(max)	,
		@objname			NVARCHAR(776)	,
		@dbname				SYSNAME			,
		@column				VARCHAR(255)	, 
		@Schema				VARCHAR(255)	,
		@Stat_name		VARCHAR(255)
;


SET @exec_sql_header	= N'''DBCC SHOW_STATISTICS ("@tmp1" ,"@tmp2" ) WITH STAT_HEADER,NO_INFOMSGS '''		;
SET @exec_sql_density	= N'''DBCC SHOW_STATISTICS ("@tmp1" ,"@tmp2" ) WITH DENSITY_VECTOR,NO_INFOMSGS'''	;
SET @exec_sql_histogram = N'''DBCC SHOW_STATISTICS ("@tmp1" ,"@tmp2" ) WITH HISTOGRAM,NO_INFOMSGS'''		;
SET @exec_sql = ''; 


INSERT INTO #STATS	
SELECT	
		DISTINCT
		infs.TABLE_SCHEMA			AS [Schema]					,
		syst.name					AS [Table_name]				,
		syss.name					AS [Stat_name]		
	FROM sys.stats_columns			AS syssc					, 
		 sys.stats					AS syss						,
		 sys.tables					AS syst						,
		 INFORMATION_SCHEMA.TABLES	AS infs						,
		 #REF_TABLE_COLUMN_LIST		AS [List]
	WHERE	syssc.object_id = syss.object_id 
		AND syssc.stats_id	= syss.stats_id
		AND	syssc.object_id = syst.object_id
		AND infs.TABLE_NAME = [List].[Table] 
		AND	syst.name in (SELECT
								[Table] 
							FROM #REF_TABLE_COLUMN_LIST
						)

-- ============================================================
-- 実行計画から取得したテーブル、統計情報一覧をカーソル処理して統計情報を取得
-- ============================================================

DECLARE TableList CURSOR FORWARD_ONLY FOR 
	SELECT * FROM #STATS 
	FOR READ ONLY;

-- ============================================================
-- 統計情報取得開始
-- ============================================================

OPEN TableList ;

-- ============================================================
-- 調査対象のテーブル名、カラム名を取得
-- ============================================================

FETCH NEXT 
	FROM TableList INTO 
					@Schema	,
					@objname,
					@Stat_name
;
WHILE @@FETCH_STATUS = 0

-- ============================================================
-- 結果を出力用テーブルにインサート
-- カーソル対象の変数をスキーマ.テーブル,カラムに動的に代入
-- ============================================================

BEGIN
-- No_02_02.index info
	SET @index_exec_sql		= REPLACE(@index_exec_sql	,'temp_@objname' , @Schema + '.' + @objname)	
	;
	EXEC (@index_exec_sql	);

-- HEADER_OUTPUT
	SET @exec_sql	= 'INSERT #STATS_HEADER_TEMP	 EXEC (' 
					+ REPLACE(REPLACE(@exec_sql_header	 ,'@tmp1', @Schema + '.' + @objname	), '@tmp2' , @Stat_name) 
					+ ') ;'
	;
	EXEC (@exec_sql)　;

-- DENSITY_OUTPUT
	SET @exec_sql	= 'INSERT #STATS_DENSITY_TEMP	 EXEC (' 
					+ REPLACE(REPLACE(@exec_sql_density	 ,'@tmp1', @Schema + '.' + @objname	), '@tmp2' , @Stat_name) 
					+ ') ;'
	;
	EXEC (@exec_sql)　;

-- HISTOGRAM_OUTPUT
	SET @exec_sql	= 'INSERT #STATS_HISTOGRAM_TEMP	 EXEC (' 
					+ REPLACE(REPLACE(@exec_sql_histogram	 ,'@tmp1', @Schema + '.' + @objname	), '@tmp2' , @Stat_name) 
					+ ') ;'
	;
	EXEC (@exec_sql)　;

	INSERT INTO #No_02_02			SELECT 
										@objname,
										*
									FROM #No_02_02_01

	INSERT INTO #STATS_HEADER		SELECT 
										@objname	,
										@Stat_name	,
										*
									FROM #STATS_HEADER_TEMP
	;
	INSERT INTO #STATS_DENSITY		SELECT 
										@objname	,
										@Stat_name	,
										*
									FROM #STATS_DENSITY_TEMP
	;
	INSERT INTO #STATS_HISTOGRAM	SELECT 
									@objname		,
									@Stat_name		,
									*
									FROM #STATS_HISTOGRAM_TEMP
	;
	
	TRUNCATE TABLE #No_02_02_01 ;
	TRUNCATE TABLE #STATS_HEADER_TEMP	;
	TRUNCATE TABLE #STATS_DENSITY_TEMP	;
	TRUNCATE TABLE #STATS_HISTOGRAM_TEMP;

-- ============================================================
-- 次の調査対象のテーブル名、カラム名を取得
-- ============================================================

FETCH NEXT 
	FROM TableList INTO 
					@Schema ,
					@objname,
					@Stat_name
;

END;
CLOSE TableList ;

DEALLOCATE TableList ;

/**********************************************************/
-- 04_01.インデックス情報
/**********************************************************/

CREATE TABLE #No_04_01 (
						[Table] 	      NVARCHAR(128)	,
						[Column] 	      NVARCHAR(128)	,
						[PK]				  VARCHAR(128)	,
						[IX1]				  VARCHAR(128)	,
						[IX2]				  VARCHAR(128)	,
						[IX3]				  VARCHAR(128)	,
						[IX4]				  VARCHAR(128)	,
						[IX5]				  VARCHAR(128)	,
						[IX6]				  VARCHAR(128)	,
						[IX7]				  VARCHAR(128)	,
						[IX8]				  VARCHAR(128)	,
						[IX9]				  VARCHAR(128)	,
						[IX10]				  VARCHAR(128)	,
						[IX11]				  VARCHAR(128)	,
						[IX12]				  VARCHAR(128)	,
						[IX13]				  VARCHAR(128)	,
						[IX14]				  VARCHAR(128)	,
						[IX15]				  VARCHAR(128)	
						) ;

WITH Index_temp_01 AS (
						SELECT
							DENSE_RANK() OVER( PARTITION BY T4.NAME
												   ORDER BY T1.NAME
											) RN		,
							T1.TYPE_DESC				,
							T4.NAME TABLE_NAME			,
							T1.NAME INDEX_NAME			,
							T2.KEY_ORDINAL				,
							T3.COLUMN_ID				,
							T3.NAME COLUMN_NAME			,
							T1.IS_PRIMARY_KEY			,
							/*
							CASE 
								WHEN CONVERT(VARCHAR,T2.IS_DESCENDING_KEY) = '0' THEN '(ASC or Columnstore or Hash)'
								WHEN CONVERT(VARCHAR,T2.IS_DESCENDING_KEY) = '1' THEN '(DESC)'
							END	AS IS_DESCENDING_KEY	,
							*/
							CASE 
								WHEN CONVERT(VARCHAR,T2.IS_INCLUDED_COLUMN) = '1' THEN '(INCLUDE or part_of_Columnstore)'
								ELSE ''
							END	AS IS_INCLUDED_COLUMN

						FROM		sys.indexes T1
						INNER JOIN	sys.index_columns T2
							ON	T1.OBJECT_ID = T2.OBJECT_ID
							AND	T1.INDEX_ID	 = T2.INDEX_ID
						INNER JOIN	sys.columns T3
							ON	T2.OBJECT_ID = T3.OBJECT_ID
							AND	T2.COLUMN_ID = T3.COLUMN_ID
						INNER JOIN	sys.tables T4
							ON	T1.OBJECT_ID = T4.OBJECT_ID
						
						)
,
	Index_temp_02 AS (
						SELECT
							CASE 
								WHEN IS_PRIMARY_KEY = 1 THEN  -1 
								ELSE RN
							END RN			,
							TABLE_NAME		,
							CASE			
								WHEN CONVERT(VARCHAR,KEY_ORDINAL) IS NULL THEN CONVERT(VARCHAR,KEY_ORDINAL)
								WHEN CONVERT(VARCHAR,KEY_ORDINAL) = '0' THEN IS_INCLUDED_COLUMN 
								ELSE CONVERT(VARCHAR,KEY_ORDINAL) + IS_INCLUDED_COLUMN 
							END KEY_ORDINAL	,
							COLUMN_ID		,
							COLUMN_NAME		
						FROM
							Index_temp_01
						WHERE TABLE_NAME in ( SELECT
													[Table] 
												FROM #REF_TABLE_COLUMN_LIST
											) 
					)
	INSERT INTO #No_04_01 
	SELECT
		TABLE_NAME	AS [Table]	,
		COLUMN_NAME	AS [Column]	,
		[-1]	AS PK			,
		[1]		AS IX1			,
		[2]		AS IX2			,
		[3]		AS IX3			,
		[4]		AS IX4			,
		[5]		AS IX5			,
		[6]		AS IX6			,
		[7]		AS IX7			,
		[8]		AS IX8			,
		[9]		AS IX9			,
		[10]		AS IX10		,
		[11]		AS IX11		,
		[12]		AS IX12		,
		[13]		AS IX13		,
		[14]		AS IX14		,
		[15]		AS IX15
	FROM
		Index_temp_02
	PIVOT
	(
		MIN(KEY_ORDINAL)
		FOR RN IN ([-1], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15])
	) AS PT
	ORDER BY
		TABLE_NAME,
		COLUMN_ID
	;

-- ============================================================
-- 04_02.不足しているインデックス
-- ============================================================
CREATE TABLE #No_04_02 (
						[Database]				NVARCHAR(128)	,
						[Table]					NVARCHAR(128)	,
						[avg_user_impact]		FLOAT(8)		,
						[avg_total_user_cost]	FLOAT(8)		,
						[equality_columns]		NVARCHAR(4000)	, 
						[inequality_columns]	NVARCHAR(4000)	,
						[included_columns]		NVARCHAR(4000)	,
						[user_seeks]			BIGINT			,
						[last_user_seek]		DATETIME		,
						[user_scans]			BIGINT			,
						[last_user_scan]		DATETIME		, 
						[statement]				NVARCHAR(4000)
					) ;


INSERT INTO #No_04_02
		SELECT 
			[List].[Database] AS [Database]	,
			[List].[Table]	AS [Table]		,
			avg_user_impact					,
			avg_total_user_cost				,
			[equality_columns]				, 
			[inequality_columns]			,
			included_columns				,
			user_seeks						,
			last_user_seek					,
			user_scans						,
			last_user_scan					, 
			[statement]
		FROM		#REF_TABLE_COLUMN_LIST					AS [List],
					[sys].[dm_db_missing_index_details]		AS mid	
		LEFT JOIN	[sys].[dm_db_missing_index_groups]		AS mig
			ON	mid.index_handle = mig.index_handle
		LEFT JOIN	[sys].[dm_db_missing_index_group_stats] AS migs
			ON	migs.group_handle = mig.index_group_handle
		WHERE
			OBJECT_NAME(mid.[object_id]) IN ( SELECT
										 			[Table] 
										 		FROM #REF_TABLE_COLUMN_LIST
											)
		ORDER BY
			[Database]	ASC, 
			[Table]		ASC
		OPTION (RECOMPILE)
;

-- ============================================================
-- 04_03.インデックス使用状況の取得
-- ============================================================
CREATE TABLE #No_04_03 (
						[DB_name]							NVARCHAR(128)	,
						[Schema_name]						NVARCHAR(128)	,
						[Table_name]						NVARCHAR(128)	,
						[Index_name]						NVARCHAR(128)	,
						[Index_type]						NVARCHAR(120)	,
						[alloc_unit_type_desc]				NVARCHAR(120)	,
						[page_count]						BIGINT			,
						[avg_fragmentation_in_percent]		FLOAT			,
						[Condition]							NVARCHAR(128)	,
						[index_id]							INT				,
						[Index_column]						NVARCHAR(MAX)	,
						[Index_column(include)]				NVARCHAR(MAX)	,
						[partition_number]					INT				,
						[data_compression_desc]				NVARCHAR(120)	,
						[reserved_page_count]				BIGINT			,
						[row_count]							BIGINT			,
						[user_seeks]						BIGINT			,
						[last_user_seek]					DATETIME		,
						[user_scans]						BIGINT			,
						[last_user_scan]					DATETIME		,
						[user_lookups]						BIGINT			,
						[last_user_lookup]					DATETIME		,
						[leaf_insert_count]					BIGINT			,
						[leaf_delete_count]					BIGINT			,
						[leaf_ghost_count]					BIGINT			,
						[leaf_update_count]					BIGINT			,
						[page_io_latch_wait_count]			BIGINT			,
						[page_io_latch_wait_in_ms]			BIGINT			,
						[page_latch_wait_count]				BIGINT			,
						[page_latch_wait_in_ms]				BIGINT			,
						[row_lock_count]					BIGINT			,
						[row_lock_wait_count]				BIGINT			,
						[row_lock_wait_in_ms]				BIGINT			,
						[page_lock_count]					BIGINT			,
						[page_lock_wait_count]				BIGINT			,
						[page_lock_wait_in_ms]				BIGINT			,
						[Stats_name]						NVARCHAR(256)	,
						[Stats_date]						DATETIME		,
						[auto_created]						BIT				,
						[user_created]						BIT				,
						[no_recompute]						BIT				,
						[create_date]						DATETIME		,
						[modify_date]						DATETIME
						) ;

INSERT INTO #No_04_03 
SELECT 
	DB_NAME()					AS [DB_name]
	, SCHEMA_NAME(so.schema_id) AS [Schema_name]
	, OBJECT_NAME(si.object_id) AS [Table_name]
	, si.name					AS [Index_name]
	, si.type_desc				AS [Index_type]
	, ips.alloc_unit_type_desc
	, ips.page_count
	, ips.avg_fragmentation_in_percent
	, CASE 
		WHEN (
				(	ips.avg_fragmentation_in_percent > 10	AND ips.avg_fragmentation_in_percent < 15)
			OR  (	ips.avg_page_space_used_in_percent < 75 AND ips.avg_page_space_used_in_percent > 60)
			)
			AND ips.page_count > 8
			AND ips.index_id NOT IN (0)
		THEN 'Reorganize'

		WHEN ((ips.avg_fragmentation_in_percent > 15) OR (ips.avg_page_space_used_in_percent < 60)) 
			AND ips.page_count > 8 
			AND ips.index_id NOT IN (0)
		THEN 'Rebuild'
		ELSE 'Good Condition'
	END							AS [Condition]
	, si.index_id
	, SUBSTRING(idxcolinfo.idxcolname,1,LEN(idxcolinfo.idxcolname) -1) AS [Index_column]
	, SUBSTRING(idxinccolinfo.idxinccolname,1,LEN(idxinccolinfo.idxinccolname) -1) AS [Index_column(include)]
	, dps.partition_number
	, sp.data_compression_desc
	, dps.reserved_page_count
	, dps.row_count
	, ius.user_seeks
	, ius.last_user_seek
	, ius.user_scans
	, ius.last_user_scan
	, ius.user_lookups
	, ius.last_user_lookup
	, ios.leaf_insert_count
	, ios.leaf_delete_count
	, ios.leaf_ghost_count
	, ios.leaf_update_count
	, ios.page_io_latch_wait_count
	, ios.page_io_latch_wait_in_ms
	, ios.page_latch_wait_count
	, ios.page_latch_wait_in_ms
	, ios.row_lock_count
	, ios.row_lock_wait_count
	, ios.row_lock_wait_in_ms
	, ios.page_lock_count
	, ios.page_lock_wait_count
	, ios.page_lock_wait_in_ms
	, ss.name								AS [Stats_name]
	, STATS_DATE(si.object_id, si.index_id) AS [Stats_date]
	, ss.auto_created
	, ss.user_created
	, ss.no_recompute
	, so.create_date
	, so.modify_date
FROM	sys.dm_db_index_physical_stats (DB_ID('sales')
											,NULL -- NULL to view all tables
											,NULL -- NULL to view all indexes; otherwise, input index number
											,NULL -- NULL to view all partitions of an index
											,'DETAILED' --We want all information
										) AS ips,	
		sys.indexes AS si
LEFT JOIN	sys.dm_db_index_usage_stats ius
	ON	ius.object_id = si.object_id
	AND	ius.index_id = si.index_id
	AND	ius.database_id = DB_ID()
LEFT JOIN	sys.dm_db_partition_stats AS dps
	ON	si.object_id = dps.object_id
	AND	si.index_id = dps.index_id
LEFT JOIN	sys.objects so
	ON	si.object_id = so.object_id
LEFT JOIN	sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ios
	ON	ios.object_id = si.object_id
	AND	ios.index_id = si.index_id
	AND	ios.partition_number = dps.partition_number
LEFT JOIN	sys.stats ss
	ON	si.object_id = ss.object_id
	AND	si.index_id = ss.stats_id
LEFT JOIN	sys.partitions sp
	ON	sp.object_id = si.object_id
	AND	sp.index_id = si.index_id
	AND	sp.partition_number = dps.partition_number
CROSS APPLY
	(SELECT 
		sc.name + ','
	FROM		sys.index_columns sic
	INNER JOIN	sys.columns sc
		ON	sic.object_id = sc.object_id
		AND	sic.column_id = sc.column_id
	WHERE	
			sic.object_id = si.object_id
		AND	sic.index_id = si.index_id
		AND	sic.is_included_column = 0
	FOR XML PATH('')
	) AS idxcolinfo(idxcolname)
	CROSS APPLY
	(SELECT 
		sc.name + ','
	FROM		sys.index_columns sic	
	INNER JOIN	sys.columns sc
		ON	sic.object_id = sc.object_id
		AND	sic.column_id = sc.column_id
	WHERE
			sic.object_id = si.object_id
		AND	sic.index_id = si.index_id
		AND	sic.is_included_column = 1
	FOR XML PATH('')
	) AS idxinccolinfo(idxinccolname)
WHERE
		(ius.database_id = DB_ID() OR ius.database_id IS NULL)
	AND (ips.database_id = DB_ID() OR ius.database_id IS NULL)
	AND	so.schema_id <> SCHEMA_ID('sys')
	AND	ips.object_id	= si.object_id 
	AND ips.index_id	= si.index_id 
	AND ips.partition_number = sp.partition_number
	AND ips.object_id	= so.object_id
	AND ips.object_id	= ios.object_id
	AND ips.index_id	= ios.index_id
	AND ips.partition_number = ios.partition_number
ORDER BY
	Table_name,
	index_id,
	partition_number,
	page_count
OPTION (RECOMPILE)

;
-- ============================================================
/*

SELECT * FROM #STATS_HEADER;
SELECT * FROM #STATS_DENSITY;
SELECT * FROM #STATS_HISTOGRAM;
SELECT * FROM #STATS	
SELECT * FROM #REF_TABLE_COLUMN_LIST
SELECT * FROM #No_04_01;
SELECT * FROM #No_04_02;
SELECT * FROM #No_04_03;
*/


/**********************************************************/
-- 06_選択したsql_handleと類似内容のクエリを持つSQLの一回あたりの動的管理ビュー
/**********************************************************/
CREATE TABLE #No_06_01(
						[Avarage_elapsed_time(ms)]			BIGINT			NULL,
						[Avarage_worker_time(ms)]			BIGINT			NULL,
						[Avarage_physical_reads_count]		BIGINT			NULL,
						[Avarage_logical_reads_count]		BIGINT			NULL,
						[Avarage_logical_writes_count]		BIGINT			NULL,
						[total_elapsed_time(ms)]			BIGINT			NULL,
						[total_worker_time(ms)]				BIGINT			NULL,
						[total_wait_time(ms)]				BIGINT			NULL,
						[total_physical_reads(8k_page)]		BIGINT			NULL,
						[total_logical_reads(8k_page)]		BIGINT			NULL,
						[total_logical_writes(8k_page)]		BIGINT			NULL,
						[execution_count]					BIGINT			NULL,
						[total_rows]						BIGINT			NULL,
						[last_rows]							BIGINT			NULL,
						[min_rows]							BIGINT			NULL,
						[max_rows]							BIGINT			NULL,
						[plan_generation_num]				BIGINT			NULL,
						[creation_time]						DATETIME		NULL,
						[last_execution_time]				DATETIME		NULL,
						[db_name]							SYSNAME			NULL,
						[statement_text]					NVARCHAR(MAX)	NULL,
						[batch_text]						NVARCHAR(MAX)	NULL,
						[query_plan]						XML				NULL
						)	;

INSERT INTO #No_06_01
SELECT 
	[total_elapsed_time] / [execution_count] / 1000.0					AS [Average Elapsed Time (ms)]			, 
	[total_worker_time]  / [execution_count] / 1000.0					AS [Average Worker Time (ms)]			, 
	[total_physical_reads] / [execution_count]							AS [Average Physical Read Count]		, 
	[total_logical_reads] / [execution_count]							AS [Average Logical Read Count]			, 
	[total_logical_writes]  / [execution_count]							AS [Average Logical Write]				, 
	[total_elapsed_time] / 1000.0										AS [total_elapsed_time (ms)]			,
	[total_worker_time] / 1000.0										AS [total_worker_time <CPU_time>(ms)]	,
	([total_elapsed_time] / 1000.0) - ([total_worker_time] / 1000.0)	AS [total_wait_time(ms)]				,	
	[total_physical_reads]												AS [total_physical_reads (8k_page)]		,
	[total_logical_reads]												AS [total_logical_reads (8k_page)]		,
	[total_logical_writes]												AS [total_logical_writes (8k_page)]		,
	[execution_count], 
	[total_rows],
	[last_rows],
	[min_rows],
	[max_rows],
	[plan_generation_num]												AS [Recompiles],
	[creation_time],
	[last_execution_time],
	DB_NAME(st.dbid)													AS db_name,
	REPLACE(REPLACE(REPLACE(SUBSTRING(text, 
	([statement_start_offset] / 2) + 1, 
	((CASE [statement_end_offset]
	WHEN -1 THEN DATALENGTH(text)
	ELSE [statement_end_offset]
	END - [statement_start_offset]) / 2) + 1),CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [statement_text],
	REPLACE(REPLACE(REPLACE([text],CHAR(13), ''), CHAR(10), ' '), CHAR(9), ' ') AS [batch_text]
	,query_plan
FROM
	[sys].[dm_exec_query_stats]
	CROSS APPLY 
	[sys].[dm_exec_sql_text]([sql_handle]) AS st
	CROSS APPLY
	[sys].[dm_exec_query_plan]([plan_handle])
WHERE [query_hash] IN (SELECT
						[query_hash]
						FROM		[sys].[dm_exec_query_stats]
						CROSS APPLY [sys].[dm_exec_sql_text]([sql_handle]) AS st
						WHERE sql_handle = @get_sql_handle
						)
OPTION (RECOMPILE)

/*********************************************************/
-- OUTOUT report
/*********************************************************/


-- ============================================================
-- report header
-- ============================================================

PRINT '<html>'
PRINT '<head>'
PRINT '<title>SQL_TableColumns_Stats</title>'

PRINT '<style type="text/css">'
PRINT 'body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}'
PRINT 'a {font-weight:bold; color:#663300;}'
PRINT 'pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */'
	
PRINT 'h1 {font-size:16pt; font-weight:bold; color:#336699;}'
PRINT 'h2 {font-size:14pt; font-weight:bold; color:#336699;}'
PRINT 'h3 {font-size:12pt; font-weight:bold; color:#336699;}'
PRINT 'li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}'
PRINT 'table {font-size:8pt; color:black; background:white;}'
PRINT 'th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}'
PRINT 'td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}'
PRINT 'td.c {text-align:center;} /* center */'


PRINT 'td.l {text-align:left;} /* left (default) */'
PRINT 'td.r {text-align:right;} /* right */'
PRINT 'font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */'
PRINT 'font.f {font-size:8pt; color:#999999;} /* footnote in gray */'
PRINT '</style>'
PRINT ''

PRINT '</head>'
PRINT '<body>'
PRINT ''
PRINT '<h1>対象クエリが参照した情報一覧</h1>'
PRINT '<ul>'
PRINT '<li><a href="#No_01">サーバ情報</a></li>'
PRINT '<li><a href="#No_02">定義</a></li>'
PRINT '<li><a href="#No_03">統計情報</a></li>'
PRINT '<li><a href="#No_04">インデックス情報</a></li>'
PRINT '<li><a href="#No_05">【未実装】プランの警告情報</a></li>'
PRINT '<li><a href="#No_06">動的管理ビュー</a></li>'
PRINT '</ul>'



-- ============================================================
-- report No_01
-- ============================================================

PRINT '<a name="No_01">サーバ情報</a>'
PRINT '<h2>サーバ情報</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>MachineName</th>'
PRINT '<th>ServerName</th>'
PRINT '<th>InstanceName</th>'
PRINT '<th>IsClustered</th>'
PRINT '<th>ComputerNamePhysicalNetBIOS</th>'
PRINT '<th>Edition</th>'
PRINT '<th>ProductLevel</th>'
PRINT '<th>ProductUpdateLevel</th>'
PRINT '<th>ProductVersion</th>'
PRINT '<th>ProductMajorVersion</th>'
PRINT '<th>ProductMinorVersion</th>'
PRINT '<th>ProductBuild</th>'
PRINT '<th>ProductBuildType</th>'
PRINT '<th>ProductUpdateReference</th>'
PRINT '<th>ProcessID</th>'
PRINT '<th>Collation</th>'
PRINT '<th>IsFullTextInstalled</th>'
PRINT '<th>IsIntegratedSecurityOnly</th>'
PRINT '<th>FilestreamConfiguredLevel</th>'
PRINT '<th>IsHadrEnabled</th>'
PRINT '<th>HadrManagerStatus</th>'
PRINT '<th>InstanceDefaultDataPath</th>'
PRINT '<th>InstanceDefaultLogPath</th>'
PRINT '<th>BuildClrVersion</th>'
PRINT '</tr>'


SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY MachineName))						+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,MachineName								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ServerName		 							),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,InstanceName 								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IsClustered 								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ComputerNamePhysicalNetBIOS				),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Edition									),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductLevel								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductUpdateLevel							),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductVersion								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductMajorVersion						),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductMinorVersion						),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductBuild								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductBuildType							),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProductUpdateReference						),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,ProcessID				 					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Collation				 					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IsFullTextInstalled						),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IsIntegratedSecurityOnly 					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,FilestreamConfiguredLevel 					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IsHadrEnabled 								),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,HadrManagerStatus							),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,InstanceDefaultDataPath					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,InstanceDefaultLogPath 					),'NULL')				+ '</td>'  ,
		'<td>' + ISNULL(CONVERT(NVARCHAR,BuildClrVersion 							),'NULL')				+ '</td>'  ,
   		'</tr>'
  FROM #No_01 ;
PRINT '</table>'


-- ============================================================
-- report No_02
-- ============================================================			
PRINT '<a name="No_02">定義</a>'
PRINT '<h2>テーブル定義</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table_name</th>'
PRINT '<th>Column_name</th>'
PRINT '<th>Column_id</th>'
PRINT '<th>Type</th>'
PRINT '<th>Nullable</th>'
PRINT '<th>Length</th>'
PRINT '<th>Prec</th>'
PRINT '<th>Scale</th>'
PRINT '<th>Collation</th>'
PRINT '<th>Computed</th>'
PRINT '<th>Filestream</th>'

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY Table_name))					+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name 							),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Column_name		 					),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Column_id 								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Type 									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Nullable								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Length									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Prec									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Scale									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Collation								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Computed								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Filestream								),'NULL')				+ '</td>'	,
   		'</tr>'
  FROM #No_02_01
  ORDER BY Table_name,Column_id;
PRINT '</table>'

PRINT '<h2>インデックス情報</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table_name</th>'	
PRINT '<th>index_name</th>'	
PRINT '<th>index_description</th>'
PRINT '<th>index_keys</th>'

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY Table_name))					+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,index_name								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,index_description						),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,index_keys								),'NULL')				+ '</td>'	,
   		'</tr>'
	FROM #No_02_02
PRINT '</table>'

PRINT '<h2>参照整合性制約情報</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>CONSTRAINT_NAME</th>'
PRINT '<th>DB_name</th>'
PRINT '<th>Schema_name</th>' 
PRINT '<th>Table_name</th>' 	
PRINT '<th>Column_name</th>' 
PRINT '<th>UPDATE_RULE</th>' 
PRINT '<th>DELETE_RULE</th>' 
PRINT '<th>Check_clause</th>' 

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY CONSTRAINT_NAME))					+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,CONSTRAINT_NAME							),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,DB_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Schema_name								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Column_name								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,UPDATE_RULE								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,DELETE_RULE								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Check_clause								),'NULL')				+ '</td>'	,
   		'</tr>'
	FROM #No_02_03
PRINT '</table>'


-- ============================================================
-- report No_03
-- ============================================================
PRINT '<a name="No_03">統計情報</a>'
PRINT '<h2>カラムの統計情報</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table_name</th>'
PRINT '<th>Stat_name</th>'
PRINT '<th>Name</th>'
PRINT '<th>Updated</th>'
PRINT '<th>Rows</th>'
PRINT '<th>Rows Sampled</th>'
PRINT '<th>Steps</th>'
PRINT '<th>Density</th>'
PRINT '<th>Average key length</th>'
PRINT '<th>String Index</th>'
PRINT '<th>Filter Expression</th>'
PRINT '<th>Unfiltered Rows</th>'

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [Table_name]))						+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Stat_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Name										),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Updated									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Rows										),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Rows Sampled]								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Steps										),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Density									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Average key length]						),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[String Index]								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Filter Expression]						),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Unfiltered Rows]							),'NULL')				+ '</td>'	,	
	  '</tr>'
	FROM #STATS_HEADER
PRINT '</table>'

PRINT '<h2>カラムの密集度</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table_name</th>'
PRINT '<th>Stat_name</th>'
PRINT '<th>ALL Density</th>'
PRINT '<th>Average Length</th>'
PRINT '<th>Columns</th>'

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [Table_name]))						+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Stat_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[ALL Density]								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Average Length]							),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Columns									),'NULL')				+ '</td>'	,
		'</tr>'
	FROM #STATS_DENSITY
PRINT '</table>'

PRINT '<h2>カラムのヒストグラム</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table_name</th>'
PRINT '<th>Stat_name</th>'
PRINT '<th>RANGE_HI_KEY</th>'
PRINT '<th>RANGE_ROWS</th>'
PRINT '<th>EQ_ROWS</th>'
PRINT '<th>DISTINCT_RANGE_ROWS</th>'
PRINT '<th>AVG_RANGE_ROWS</th>'

SELECT '<tr>' +
       '<td class="r">' +  CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [Table_name]))						+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,Stat_name									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,RANGE_HI_KEY								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,RANGE_ROWS									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,EQ_ROWS									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,DISTINCT_RANGE_ROWS						),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,AVG_RANGE_ROWS								),'NULL')				+ '</td>'	,
		'</tr>'
	FROM #STATS_HISTOGRAM
PRINT '</table>'

-- ============================================================
-- report No_04
-- ============================================================
PRINT '<a name="No_02">インデックス情報</a>'
PRINT '<h2>インデックス情報</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Table</th>'
PRINT '<th>Column</th>'
PRINT '<th>PK</th>'
PRINT '<th>IX1</th>'
PRINT '<th>IX2</th>'
PRINT '<th>IX3</th>'
PRINT '<th>IX4</th>'
PRINT '<th>IX5</th>'
PRINT '<th>IX6</th>'
PRINT '<th>IX7</th>'
PRINT '<th>IX8</th>'
PRINT '<th>IX9</th>'
PRINT '<th>IX10</th>'
PRINT '<th>IX11</th>'
PRINT '<th>IX12</th>'
PRINT '<th>IX13</th>'
PRINT '<th>IX14</th>'
PRINT '<th>IX15</th>'

SELECT '<tr>' +
       '<td class="r">' 
			   + CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [Table]))									+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Table]								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Column]								),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,PK										),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX1									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX2									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX3									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX4									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX5									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX6									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX7									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX8									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX9									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX10									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX11									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX12									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX13									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX14									),'NULL')				+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,IX15									),'NULL')				+ '</td>'	,
		'</tr>'
	FROM #No_04_01
PRINT '</table>'

PRINT '<h2>不足しているインデックス</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Database</th>'				
PRINT '<th>Table</th>'					
PRINT '<th>avg_user_impact</th>'		
PRINT '<th>avg_total_user_cost</th>'	
PRINT '<th>equality_columns</th>'		
PRINT '<th>inequality_columns</th>'	
PRINT '<th>included_columns</th>'		
PRINT '<th>user_seeks</th>'			
PRINT '<th>last_user_seek</th>'		
PRINT '<th>user_scans</th>'			
PRINT '<th>last_user_scan</th>'		
PRINT '<th>statement</th>'				

SELECT '<tr>' +
       '<td class="r">' 
			   + CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [Database]))							+ '</td>'	,
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Database]							),'NULL')				+ '</td>'	,				
		'<td>' + ISNULL(CONVERT(NVARCHAR,[Table]							),'NULL')				+ '</td>'	,					
		'<td>' + ISNULL(CONVERT(NVARCHAR,avg_user_impact					),'NULL')				+ '</td>'	,		
		'<td>' + ISNULL(CONVERT(NVARCHAR,avg_total_user_cost				),'NULL')				+ '</td>'	,	
		'<td>' + ISNULL(CONVERT(NVARCHAR,equality_columns					),'NULL')				+ '</td>'	,		
		'<td>' + ISNULL(CONVERT(NVARCHAR,inequality_columns					),'NULL')				+ '</td>'	,	
		'<td>' + ISNULL(CONVERT(NVARCHAR,included_columns					),'NULL')				+ '</td>'	,		
		'<td>' + ISNULL(CONVERT(NVARCHAR,user_seeks							),'NULL')				+ '</td>'	,			
		'<td>' + ISNULL(CONVERT(NVARCHAR,last_user_seek						),'NULL')				+ '</td>'	,		
		'<td>' + ISNULL(CONVERT(NVARCHAR,user_scans							),'NULL')				+ '</td>'	,			
		'<td>' + ISNULL(CONVERT(NVARCHAR,last_user_scan						),'NULL')				+ '</td>'	,		
		'<td>' + ISNULL(CONVERT(NVARCHAR,statement							),'NULL')				+ '</td>'	,				
		'</tr>'
	FROM #No_04_02
PRINT '</table>'


PRINT '<h2>インデックス使用状況の取得</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>DB_name</th>'						
PRINT '<th>Schema_name</th>'					
PRINT '<th>Table_name</th>'					
PRINT '<th>Index_name</th>'					
PRINT '<th>Index_type</th>'					
PRINT '<th>alloc_unit_type_desc</th>'			
PRINT '<th>page_count</th>'					
PRINT '<th>avg_fragmentation_in_percent</th>'	
PRINT '<th>Condition</th>'						
PRINT '<th>index_id</th>'						
PRINT '<th>Index_column</th>'					
PRINT '<th>Index_column(include)</th>'			
PRINT '<th>partition_number</th>'				
PRINT '<th>data_compression_desc</th>'			
PRINT '<th>reserved_page_count</th>'			
PRINT '<th>row_count</th>'						
PRINT '<th>user_seeks</th>'					
PRINT '<th>last_user_seek</th>'				
PRINT '<th>user_scans</th>'					
PRINT '<th>last_user_scan</th>'				
PRINT '<th>user_lookups</th>'					
PRINT '<th>last_user_lookup</th>'				
PRINT '<th>leaf_insert_count</th>'				
PRINT '<th>leaf_delete_count</th>'				
PRINT '<th>leaf_ghost_count</th>'				
PRINT '<th>leaf_update_count</th>'				
PRINT '<th>page_io_latch_wait_count</th>'		
PRINT '<th>page_io_latch_wait_in_ms</th>'		
PRINT '<th>page_latch_wait_count</th>'			
PRINT '<th>page_latch_wait_in_ms</th>'			
PRINT '<th>row_lock_count</th>'				
PRINT '<th>row_lock_wait_count</th>'			
PRINT '<th>row_lock_wait_in_ms</th>'			
PRINT '<th>page_lock_count</th>'				
PRINT '<th>page_lock_wait_count</th>'			
PRINT '<th>page_lock_wait_in_ms</th>'			
PRINT '<th>Stats_name</th>'					
PRINT '<th>Stats_date</th>'					
PRINT '<th>auto_created</th>'					
PRINT '<th>user_created</th>'					
PRINT '<th>no_recompute</th>'					
PRINT '<th>create_date</th>'					
PRINT '<th>modify_date</th>'					
SELECT '<tr>' +
       '<td class="r">' 
			   + CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [DB_name]))										+ '</td>'	,
			    '<td>' + ISNULL(CONVERT(NVARCHAR,[DB_name]								),'NULL')				+ '</td>'	,						
				'<td>' + ISNULL(CONVERT(NVARCHAR,[Schema_name]							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,Table_name								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,Index_name								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,Index_type								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,alloc_unit_type_desc					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_count								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,avg_fragmentation_in_percent			),'NULL')				+ '</td>'	,	
				'<td>' + ISNULL(CONVERT(NVARCHAR,Condition								),'NULL')				+ '</td>'	,						
				'<td>' + ISNULL(CONVERT(NVARCHAR,index_id								),'NULL')				+ '</td>'	,						
				'<td>' + ISNULL(CONVERT(NVARCHAR,Index_column							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,[Index_column(include)]				),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,partition_number						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,data_compression_desc					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,reserved_page_count					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,row_count								),'NULL')				+ '</td>'	,						
				'<td>' + ISNULL(CONVERT(NVARCHAR,user_seeks								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,last_user_seek							),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,user_scans								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,last_user_scan							),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,user_lookups							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,last_user_lookup						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,leaf_insert_count						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,leaf_delete_count						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,leaf_ghost_count						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,leaf_update_count						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_io_latch_wait_count				),'NULL')				+ '</td>'	,		
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_io_latch_wait_in_ms				),'NULL')				+ '</td>'	,		
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_latch_wait_count					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_latch_wait_in_ms					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,row_lock_count							),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,row_lock_wait_count					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,row_lock_wait_in_ms					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_lock_count						),'NULL')				+ '</td>'	,				
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_lock_wait_count					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,page_lock_wait_in_ms					),'NULL')				+ '</td>'	,			
				'<td>' + ISNULL(CONVERT(NVARCHAR,Stats_name								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,Stats_date								),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,auto_created							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,user_created							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,no_recompute							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,create_date							),'NULL')				+ '</td>'	,					
				'<td>' + ISNULL(CONVERT(NVARCHAR,modify_date							),'NULL')				+ '</td>'	,					
			'</tr>'
	FROM #No_04_03
PRINT '</table>'
				

-- ============================================================
-- 未作成_report No_05
-- ============================================================
/*
PRINT '<a name="No_02">定義</a>'
PRINT '<h2>テーブル定義</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'

*/


-- ============================================================
-- report No_06
-- ============================================================
PRINT '<a name="No_02">動的管理ビュー</a>'
PRINT '<h2>DMV</h2>'
PRINT '<table>'
PRINT '<tr>'
PRINT '<th>No</th>'
PRINT '<th>Avarage_elapsed_time(ms)</th>'		
PRINT '<th>Avarage_worker_time(ms)</th>'		
PRINT '<th>Avarage_physical_reads_count</th>'	
PRINT '<th>Avarage_logical_reads_count</th>'	
PRINT '<th>Avarage_logical_writes_count</th>'	
PRINT '<th>total_elapsed_time(ms)</th>'		
PRINT '<th>total_worker_time(ms)</th>'			
PRINT '<th>total_wait_time(ms)</th>'			
PRINT '<th>total_physical_reads(8k_page)</th>'	
PRINT '<th>total_logical_reads(8k_page)</th>'	
PRINT '<th>total_logical_writes(8k_page)</th>'	
PRINT '<th>execution_count</th>'				
PRINT '<th>total_rows</th>'					
PRINT '<th>last_rows</th>'						
PRINT '<th>min_rows</th>'						
PRINT '<th>max_rows</th>'						
PRINT '<th>plan_generation_num</th>'			
PRINT '<th>creation_time</th>'					
PRINT '<th>last_execution_time</th>'			
PRINT '<th>db_name</th>'						
PRINT '<th>statement_text</th>'				
PRINT '<th>batch_text</th>'					
PRINT '<th>query_plan</th>'					

SELECT '<tr>' +
       '<td class="r">' 
			   + CONVERT(NVARCHAR,ROW_NUMBER() OVER (ORDER BY [creation_time]))										+ '</td>'	,
        '<td>' + ISNULL(CONVERT(NVARCHAR,[Avarage_elapsed_time(ms)]							),'NULL')				+ '</td>'	,		
        '<td>' + ISNULL(CONVERT(NVARCHAR,[Avarage_worker_time(ms)]							),'NULL')				+ '</td>'	,		
        '<td>' + ISNULL(CONVERT(NVARCHAR,[Avarage_physical_reads_count]						),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[Avarage_logical_reads_count]						),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[Avarage_logical_writes_count]						),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_elapsed_time(ms)]							),'NULL')				+ '</td>'	,		
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_worker_time(ms)]							),'NULL')				+ '</td>'	,			
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_wait_time(ms)]								),'NULL')				+ '</td>'	,			
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_physical_reads(8k_page)]					),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_logical_reads(8k_page)]						),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_logical_writes(8k_page)]					),'NULL')				+ '</td>'	,	
        '<td>' + ISNULL(CONVERT(NVARCHAR,[execution_count]									),'NULL')				+ '</td>'	,				
        '<td>' + ISNULL(CONVERT(NVARCHAR,[total_rows]										),'NULL')				+ '</td>'	,					
        '<td>' + ISNULL(CONVERT(NVARCHAR,[last_rows]										),'NULL')				+ '</td>'	,						
        '<td>' + ISNULL(CONVERT(NVARCHAR,[min_rows]											),'NULL')				+ '</td>'	,						
        '<td>' + ISNULL(CONVERT(NVARCHAR,[max_rows]											),'NULL')				+ '</td>'	,						
        '<td>' + ISNULL(CONVERT(NVARCHAR,[plan_generation_num]								),'NULL')				+ '</td>'	,			
        '<td>' + ISNULL(CONVERT(NVARCHAR,[creation_time]									),'NULL')				+ '</td>'	,					
        '<td>' + ISNULL(CONVERT(NVARCHAR,[last_execution_time]								),'NULL')				+ '</td>'	,			
        '<td>' + ISNULL(CONVERT(NVARCHAR,[db_name]											),'NULL')				+ '</td>'	,						
        '<td>' + ISNULL(CONVERT(NVARCHAR(MAX),[statement_text]								),'NULL')				+ '</td>'	,				
        '<td>' + ISNULL(CONVERT(NVARCHAR(MAX),[batch_text]									),'NULL')				+ '</td>'	,					
        '<td>' + ISNULL(CONVERT(NVARCHAR(MAX),[query_plan]									),'NULL')				+ '</td>'	,					
	'</tr>'
	FROM #No_06_01
PRINT '</table>'


/**********************************************************/
-- 取得内容一覧
-- 01_☑サーバ情報、☑エディション、☑パラメータ情報等
-- 02_☑テーブル定義、テーブル一覧,カラム情報、カーディナリティ
-- 03_☑統計情報　←未インデックス系の統計方法は別の方法で取得
-- 04_☑インデックス情報,インデックス一覧、不足しているインデックス
-- 05_未フルスキャン情報、暗黙型変換等のwarn情報
-- 06_☑一回あたりの動的管理ビュー,statementtext,今回のstatementが含まれるbatchtext
/**********************************************************/
