-- ===============================================
-- ring bufferのdeadlock情報
-- ===============================================

SELECT
		XEventData.XEvent.query('.')												AS [XEvent]
	FROM (SELECT
						CAST(target_data AS XML)						AS [TargetData]
			FROM			[sys].[dm_xe_session_targets]		AS [targets]	WITH(NOLOCK)
			INNER JOIN 	[sys].[dm_xe_sessions]					AS [sessions] WITH(NOLOCK)
			ON 			[sessions].[address] = [targets].[event_session_address]
			WHERE		[sessions].[name]			= N'system_health'
			AND			[targets].[target_name] = N'ring_buffer'
		) AS [system_health]
	CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(XEvent)