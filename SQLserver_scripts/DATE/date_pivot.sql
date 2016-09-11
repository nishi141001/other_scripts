/*********************************************/
-- 先月一か月間の処理件数をPIVOTで歯抜けなく
-- 表示する。

-- add Date_type
-- 1 : 1year
-- 2 : 1month
-- 3 : 1day
-- 4 : 1hour
-- 5 : 1minute
/*********************************************/
USE master
GO
SET NOCOUNT ON
GO

/********[1,2,3,4,5]のうちいずれかを入力********/
DECLARE @Date_type int = 3				;
/***********************************************/

DECLARE @DateFrom DATETIME				;
DECLARE @DateTo   DATETIME				;
DECLARE @Date_TBL TABLE (
		[Date]			VARCHAR(MAX))	;
DECLARE @Date			VARCHAR(MAX)	;
DECLARE @Exec_sql		NVARCHAR(MAX)	;
DECLARE @PIVOT_COLUMNS	VARCHAR(MAX)	;

SET		@DateFrom		= DATEADD(MM, DATEDIFF(MM,  0, GETDATE()) - 1,  0)		;
SET		@DateTo			= DATEADD(MM, DATEDIFF(MM, -1, GETDATE()) - 1, -1)		;
SET		@DateTo			= FORMAT(@DateTo, 'yyyyMMdd 23:59:59.000')				;
SET		@PIVOT_COLUMNS	= ''													;
SET		@Exec_sql		= ''													;

IF OBJECT_ID(N'tempdb..#prePIVOT_TBL' , N'U') IS NOT NULL DROP TABLE #prePIVOT_TBL;
CREATE TABLE #prePIVOT_TBL (
		[Data]			VARCHAR(MAX)	,
		[Date]			VARCHAR(MAX)	
)	;


WITH Dates AS 
  (SELECT 
		CASE @Date_type 
			WHEN 1 THEN FORMAT(@DateFrom, 'yyyy')
			WHEN 2 THEN FORMAT(@DateFrom, 'yyyy-MM-dd')
			WHEN 3 THEN FORMAT(@DateFrom, 'yyyy-MM-dd')
			WHEN 4 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:00')
			WHEN 5 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:mm')
			ELSE FORMAT(@DateFrom, 'yyyy')
		END AS [Date]
    UNION ALL
   SELECT 
		CASE @Date_type 
			WHEN 1 THEN FORMAT(DATEADD (yyyy, 1 ,[Date] ),'yyyy')
			WHEN 2 THEN FORMAT(DATEADD (MM, 1 ,[Date] ),'yyyy-MM-dd')
			WHEN 3 THEN FORMAT(DATEADD (dd, 1 ,[Date] ),'yyyy-MM-dd')
			WHEN 4 THEN FORMAT(DATEADD (MI, 60 ,[Date] ),'yyyy-MM-dd HH:00')
			WHEN 5 THEN FORMAT(DATEADD (MI, 1 ,[Date] ),'yyyy-MM-dd HH:mm')
			ELSE FORMAT(DATEADD (yyyy, 1 ,[Date] ),'yyyy')
		END
   FROM Dates
    WHERE 
      (CASE @Date_type
			WHEN 1 THEN FORMAT(DATEADD (yyyy, 1 ,[Date] ),'yyyy') 
			WHEN 2 THEN FORMAT(DATEADD (MM, 1 ,[Date] ),'yyyy-MM-dd') 
			WHEN 3 THEN FORMAT(DATEADD (dd, 1 ,[Date] ),'yyyy-MM-dd')
			WHEN 4 THEN FORMAT(DATEADD (hh, 1 ,[Date] ),'yyyy-MM-dd HH:00')
			WHEN 5 THEN FORMAT(DATEADD (MI, 1 ,[Date] ),'yyyy-MM-dd HH:mm')
			ELSE FORMAT(DATEADD (yyyy, 1 ,@DateFrom),'yyyy')
		END ) < @DateTo
  )

	INSERT INTO @Date_TBL
		SELECT * FROM [Dates] AS [DT]
			OPTION (MAXRECURSION 30000) ;
	
	DECLARE DateList CURSOR FORWARD_ONLY FOR 
		SELECT [Date] FROM @Date_TBL
		FOR READ ONLY;

	OPEN DateList ;

		FETCH NEXT FROM DateList INTO @Date	;
	
	-- ==================================================
	-- PIVOTで使用する列をリスト形式で動的に生成
	-- ==================================================
		WHILE @@FETCH_STATUS = 0
			BEGIN 
				SET @PIVOT_COLUMNS = @PIVOT_COLUMNS + '[' + @Date + '],'	;
				FETCH NEXT FROM DateList INTO @Date			;
			END;
		CLOSE DateList ;
		SET @PIVOT_COLUMNS = SUBSTRING(@PIVOT_COLUMNS, 1, LEN(@PIVOT_COLUMNS) -1)
	DEALLOCATE DateList ;

	INSERT INTO #prePIVOT_TBL	
			SELECT  
					[EMAIL]										,
					-- ==================================================
					-- Date_typeに応じて以下に変更
						-- datetime_type
						-- 1 : 1year    >>> FORMAT([name1], 'yyyy')
						-- 2 : 1month   >>> FORMAT([name1], 'yyyy-MM-01')
						-- 3 : 1day     >>> FORMAT([name1], 'yyyy-MM-dd')
						-- 4 : 1hour    >>> FORMAT([name1], 'yyyy-MM-dd HH:00')
						-- 5 : 1minute  >>> FORMAT([name1], 'yyyy-MM-dd HH:mm')
					-- ==================================================
					FORMAT([HIRE_DATE], 'yyyy-MM-dd') AS [HIRE_Month_day]
				FROM [sales].[dbo].[EMPLOYEES]
			
	SET @Exec_sql =   N' SELECT * FROM #prePIVOT_TBL ' 
					+ N' PIVOT (COUNT([Date]) FOR [Date] IN ( '
					+ @PIVOT_COLUMNS 
					+ N' )) AS P'
	EXEC sp_executesql @Exec_sql
	
