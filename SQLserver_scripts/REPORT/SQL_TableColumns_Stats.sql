
SET NOCOUNT ON
GO
DECLARE @get_sql_handle VARBINARY(64);

-- *********************************************************
-- 枠内に対象①②を入力してから実行
-- ①今回対象となるDBの名前

	USE sales; --ここに調査対象のDB名を入力
	-- ex)USE sales
-- ②今回対象となるSQLハンドル

	SET @get_sql_handle = 0x0200000016129604DA2434989FA70C64AF3A9BD8830DDBF40000000000000000000000000000000000000000 
						-- ↑ここに調査対象のSQLハンドルを入力

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
DROP TABLE #Server_prop
DROP TABLE #REF_TABLE_COLUMN ;
DROP TABLE #REF_TABLE_COLUMN_LIST ;
DROP TABLE #No_02_01	;
DROP TABLE #No_02_02_01	;
DROP TABLE #No_02_02	;
DROP TABLE #No_02_03	;
DROP TABLE #Index_info;
DROP TABLE #STATS;
DROP TABLE #STATS_HEADER_TEMP;
DROP TABLE #STATS_DENSITY_TEMP;
DROP TABLE #STATS_HISTOGRAM_TEMP;
DROP TABLE #STATS_HEADER;
DROP TABLE #STATS_DENSITY;
DROP TABLE #STATS_HISTOGRAM;

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
CREATE TABLE #Server_prop(
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

INSERT INTO #Server_prop EXEC sp_executesql @prop_exec_sql;
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

PRINT '参照したテーブルに存在する統計情報の詳細'

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
	SET @index_exec_sql		= REPLACE(@index_exec_sql	,'temp_@objname' , @objname)	
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

CREATE TABLE #Index_info (
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

						FROM		SYS.INDEXES T1
						INNER JOIN	SYS.INDEX_COLUMNS T2
							ON	T1.OBJECT_ID = T2.OBJECT_ID
							AND	T1.INDEX_ID	 = T2.INDEX_ID
						INNER JOIN	SYS.COLUMNS T3
							ON	T2.OBJECT_ID = T3.OBJECT_ID
							AND	T2.COLUMN_ID = T3.COLUMN_ID
						INNER JOIN	SYS.TABLES T4
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
	INSERT INTO #Index_info 
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


-- ============================================================
-- 04_03.インデックス使用状況の取得
-- ============================================================
SELECT 
	DB_NAME() as db_name
	, SCHEMA_NAME(so.schema_id) AS [schema_name]
	, OBJECT_NAME(si.object_id) AS [Table_name]
	, si.name
	, si.type_desc
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
	END AS [Condition]
	, si.index_id
	, SUBSTRING(idxcolinfo.idxcolname,1,LEN(idxcolinfo.idxcolname) -1) AS idxcolname
	, SUBSTRING(idxinccolinfo.idxinccolname,1,LEN(idxinccolinfo.idxinccolname) -1) AS idxinccolname
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
	, ss.name AS stats_name
	, STATS_DATE(si.object_id, si.index_id) AS [stats_date]
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


-- ============================================================



SELECT 
	[Table_name] 	,
	[Column_name] 	,
	[Type]			,
	[Nullable]		,
	[Length]		,
	[Prec]			,
	[Scale]			,
	[Collation]		,
	[Computed]		,
	[Filestream]	
 FROM #No_02_01
ORDER BY column_id;

SELECT * FROM #No_02_02;
SELECT * FROM #No_02_03;
SELECT * FROM #STATS_HEADER;
SELECT * FROM #STATS_DENSITY;
SELECT * FROM #STATS_HISTOGRAM;
SELECT * FROM #STATS	
SELECT * FROM #REF_TABLE_COLUMN_LIST
SELECT * FROM #Index_info;
SELECT * FROM #Server_prop;

/**********************************************************/
-- 06_選択したsql_handleと類似内容のクエリを持つSQLの一回あたりの動的管理ビュー
/**********************************************************/
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

/**********************************************************/

-- 01_サーバ情報、エディション、パラメータ情報等
-- 02_テーブル定義、テーブル一覧

PRINT 'このSQLが参照しているテーブルとカラムの情報';
-- 03_統計情報
PRINT '参照したテーブルに存在する統計情報の詳細'
-- 04_01.インデックス情報
PRINT '参照テーブルに付与させているINDEX詳細'
-- 04_02.不足しているインデックス
PRINT '不足しているインデックス'
-- 06_選択したsql_handleと類似内容のクエリを持つSQLの一回あたりの動的管理ビュー



/*********************************************************/
-- 残課題
/*********************************************************/
-- インデックスの断片化、インデックスの行数、ページ数
-- HTML化




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
--PRINT '<h1><a target='MOS' href='^^doc_link.^^mos_doc.'>^^mos_doc.</a> ^^method.'
--PRINT '^^doc_ver. Report: ^^files_prefix._1_health_check.html</h1>'
PRINT ''

PRINT '<ul>'
PRINT '<li><a href="#obs">01_サーバ情報、エディション、パラメータ情報</a></li>'
PRINT '<li><a href="#text">02_テーブル定義、テーブル一覧</a></li>'
PRINT '<li><a href="#tbl_sum">Tables Summary</a></li>'
PRINT '<li><a href="#idx_sum">Indexes Summary</a></li>'
PRINT '</ul>'

