/*********************************************/
-- tmp_datedimentionTBL
-- 歯抜けタイムスタンプは0として集計
-- add datetime_type
-- 1 : 1year
-- 2 : 1month
-- 3 : 1day
-- 4 : 1hour
-- 5 : 15minute
-- 6 : 10minute
-- 7 : 1minute
/*********************************************/
-- datetime_sample
-- DECLARE @DateFrom datetime = '2016-03-01 00:00:00.000' ;
-- DECLARE @DateTo datetime   = '2016-03-01 00:00:00.000' ;
/*********************************************/
USE master
GO
SET NOCOUNT ON
GO

DECLARE @Date_type int = 2 ;
DECLARE @DateFrom datetime = '1996-03-01 02:30:52.800' ;
DECLARE @DateTo datetime = '1997-03-01 14:00:29.380' ;

WITH Dates AS 
  (SELECT 
	CASE @Date_type 
		WHEN 1 THEN FORMAT(@DateFrom, 'yyyy')
		WHEN 2 THEN FORMAT(@DateFrom, 'yyyy-MM-dd')
		WHEN 3 THEN FORMAT(@DateFrom, 'yyyy-MM-dd')
		WHEN 4 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:mm')
		WHEN 5 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:mm')
		WHEN 6 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:mm')
		WHEN 7 THEN FORMAT(@DateFrom, 'yyyy-MM-dd HH:mm')
		ELSE FORMAT(@DateFrom, 'yyyy')
  END AS [analyze_date]
    UNION ALL
   SELECT 
		CASE @Date_type 
			WHEN 1 THEN FORMAT(DATEADD (yyyy, 1 ,[analyze_date] ),'yyyy')
			WHEN 2 THEN FORMAT(DATEADD (MM, 1 ,[analyze_date] ),'yyyy-MM-dd')
			WHEN 3 THEN FORMAT(DATEADD (dd, 1 ,[analyze_date] ),'yyyy-MM-dd')
			WHEN 4 THEN FORMAT(DATEADD (MI, 60 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 5 THEN FORMAT(DATEADD (MI, 15 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 6 THEN FORMAT(DATEADD (MI, 10 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 7 THEN FORMAT(DATEADD (MI, 1 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
    ELSE FORMAT(DATEADD (yyyy, 1 ,[analyze_date] ),'yyyy')
    END
   FROM Dates
    WHERE 
      (CASE @Date_type
			WHEN 1 THEN FORMAT(DATEADD (yyyy, 1 ,[analyze_date] ),'yyyy') 
			WHEN 2 THEN FORMAT(DATEADD (MM, 1 ,[analyze_date] ),'yyyy-MM-dd') 
			WHEN 3 THEN FORMAT(DATEADD (dd, 1 ,[analyze_date] ),'yyyy-MM-dd')
			WHEN 4 THEN FORMAT(DATEADD (hh, 1 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 5 THEN FORMAT(DATEADD (MI, 15 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 6 THEN FORMAT(DATEADD (MI, 10 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			WHEN 7 THEN FORMAT(DATEADD (MI, 1 ,[analyze_date] ),'yyyy-MM-dd HH:mm')
			ELSE FORMAT(DATEADD (yyyy, 1 ,@DateFrom),'yyyy')
		END ) < @DateTo
  )
/*********************************************/
-- check datedimention interval
-- SELECT top(10000)* FROM Dates OPTION (MAXRECURSION 30000);
/*********************************************/
SELECT [DT].[analyze_date] AS 日付,
       ISNULL([T_calc].[cnt], 0) AS calc_result
       FROM Dates AS [DT]
  LEFT OUTER JOIN (
/*********************************************/
-- change 
--        column LEFT([name1], x)
--    AND GROUP BY LEFT([name1], x)
--    AND ) AS [T_calc] ON LEFT([DT].[analyze_date], x)
-- datetime_type
-- 1 : 1year    >>> LEFT([name1], 4)
-- 2 : 1month   >>> LEFT([name1], 7)
-- 3 : 1day     >>> LEFT([name1], 10)
-- 4 : 1hour    >>> LEFT([name1], 16)
-- 5 : 15minute >>> LEFT([name1], 16)
-- 6 : 10minute >>> LEFT([name1], 16)
-- 7 : 1minute  >>> LEFT([name1], 16)
-- join sample_calc_table
--                   SELECT [a1],
--                          COUNT([a1]) AS [COUNT]
--                    FROM Table
--                    GROUP BY [a1]
--                 )  AS [T_calc]
/*********************************************/
                    SELECT  LEFT([HIRE_DATE], 7) AS [HIRE_Month], -- need change
                            COUNT([HIRE_DATE]) AS [cnt]
                            FROM [sales].[dbo].[EMPLOYEES]
                               GROUP BY LEFT([HIRE_DATE], 7)      -- need change
                  )  AS [T_calc]
  ON LEFT([DT].[analyze_date],7)                                  -- need change
  = [T_calc].[HIRE_Month]

/*再帰回数指定(∞に注意)*/
OPTION (MAXRECURSION 30000)
;

