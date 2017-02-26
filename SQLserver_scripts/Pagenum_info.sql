/***************************************************/
-- レコードが格納されているページ番号を取得
/***************************************************/

SELECT * FROM dbo.Lock_test
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS fPLC
ORDER BY 
	fPLC.file_id,
	fPLC.page_id,
	fPLC.slot_id


/***************************************************/
-- リーフ、ルートノードが格納されているページ番号を取得
/***************************************************/
  SELECT	
    [dpa].[page_level] AS [page_level],
	[dpa].[allocated_page_page_id] AS [page_id],
	[i].[name] AS [index_name],
	[dpa].[page_type_desc],
	[dpa].[previous_page_page_id],
	[dpa].[next_page_page_id]
　　FROM  sys.dm_db_database_page_allocations(	DB_ID('Param_testDB'),	
						OBJECT_ID('dbo.Lock_test'),
						1,
						1,
						'DETAILED'
　　　　　　　　				) AS [dpa]
　　INNER JOIN sys.indexes AS [i]
	ON	[dpa].[object_id] = [i].[object_id]
	AND [dpa].[index_id] = [i].[index_id]
　　WHERE [dpa].[page_level] IS NOT NULL
　　ORDER BY	[dpa].[page_level] DESC,
		[dpa].[allocated_page_page_id]
