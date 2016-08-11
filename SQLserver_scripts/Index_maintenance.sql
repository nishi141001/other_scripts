USE sales
SET NOCOUNT ON
GO
/***********************************************/
-- 断片化率が以下のMS推奨値である場合に
-- 自動で断片化の解消を実行する。

-- ============================================
-- 断片化率が5-30%		⇒		REORGANIZE
-- 断片化率が30%以上	⇒		REBUILD(OFFLINE)					⇒⇒@Option_type = 1 or その他
-- 断片化率が30%以上	⇒		REBUILD(ONLINE)(*Enterpriseのみ)	⇒⇒@Option_type = 2	
-- ============================================
DECLARE @Option_type INT ;
	SET @Option_type = 2 ; --####ここで [1 or 2] を選ぶ####--
/***********************************************/
--USE DMV_snapshot_DWH

DECLARE @Option_text NVARCHAR(100)	;
	SET @Option_text = ''			;

SELECT @Option_text  =
				CASE @Option_type
					WHEN 1 THEN N''
					WHEN 2 THEN N'WITH(ONLINE = ON)' 
					ELSE N'' 
				END
	; 


-- TABLE変数の定義
DECLARE @Index_mainte TABLE(
    [SchemaName]		VARCHAR(100)    ,
	[TableName]         VARCHAR(100)    ,
    [IndexName]         VARCHAR(100)    ,
    [Fragmentation]     INT             ,
    [RowCount]          INT             
    ) ;

DECLARE @SchemaName			SYSNAME			,
		@TableName			SYSNAME			,
        @IndexName			SYSNAME			,
        @Fragmentation		INT				,
        @RowCount			INT				,
        @dm_sql_command		NVARCHAR(1000)
        ;

-- TABLE変数への格納
INSERT INTO @Index_mainte (
				[SchemaName]			,
				[TableName]				,	     
				[IndexName]				,
				[Fragmentation]			,
				[RowCount]
				)
		SELECT	sc.name	AS SchemaName									,
				OBJECT_NAME(i.Object_id)								,
				i.name	AS IndexName									,
				indexstats.avg_fragmentation_in_percent					,
				ROW_NUMBER() OVER (ORDER BY i.name DESC) AS [RowCount]	
		FROM sys.dm_db_index_physical_stats(
											DB_ID()	,
											NULL	,
											NULL	,
											NULL	,
											'DETAILED'
											)	AS indexstats
		INNER JOIN	sys.indexes	AS i
				ON	i.object_id = indexstats.object_id
				AND	i.index_id	= indexstats.index_id
		INNER JOIN	sys.objects	AS o
				ON	o.object_id = indexstats.object_id
		INNER JOIN	sys.schemas AS sc
				ON	sc.schema_id = o.schema_id


-- 対象を一行ずつ取り出し、動的SQL生成

DECLARE @count	INT	;
	SET @count	= 0	;

WHILE @count < (SELECT COUNT([RowCount]) FROM @Index_mainte)
	BEGIN 
		SET @count = @count + 1	;
		WITH CTE AS (
			SELECT	[SchemaName]		,
					[TableName]			,			
					[IndexName]			,
					[Fragmentation]		
			FROM @Index_mainte
				WHERE [RowCount] = @count
			)
			SELECT	@SchemaName		=	[SchemaName]		,
					@TableName		=	[TableName]			,       
					@IndexName      =	[IndexName]			,
					@Fragmentation  =	[Fragmentation]		
			FROM CTE
			;
		
		IF @Fragmentation >= 5 AND @Fragmentation <= 30
			BEGIN 
				SET @dm_sql_command = 
					N'ALTER INDEX ' + @IndexName + 
					N' ON ' + @SchemaName +
					N'.' + @TableName +
					N' REORGANIZE';
				PRINT @dm_sql_command 
				EXEC sp_executesql @dm_sql_command;
			END
		ELSE IF @Fragmentation > 30
			BEGIN
				SET @dm_sql_command = 
					N'ALTER INDEX ' + @IndexName + 
					N' ON ' + @SchemaName +
					N'.' + @TableName +
					N' REBUILD ' + @Option_text
					;
				PRINT @dm_sql_command 
				EXEC sp_executesql @dm_sql_command;
			END;
		END;

			






