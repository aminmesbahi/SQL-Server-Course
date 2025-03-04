/**************************************************************
 * SQL Server 2022 Extended Events Tutorial
 * Description: This script demonstrates how to work with Extended Events
 *              in SQL Server 2022. It covers:
 *              - Creating and configuring Extended Events sessions
 *              - Capturing specific events and event data
 *              - Working with different event targets
 *              - Filtering and advanced predicates
 *              - Analyzing the captured data
 *              - Real-world monitoring scenarios
 *              - Performance considerations
 **************************************************************/

-------------------------------------------------
-- Region: 1. Introduction and Setup
-------------------------------------------------
USE master;
GO

/*
  Clean up any existing Extended Events session with the same name
  to avoid errors when running this script multiple times.
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'QueryPerformanceMonitoring')
    DROP EVENT SESSION QueryPerformanceMonitoring ON SERVER;
GO

-------------------------------------------------
-- Region: 2. Creating a Basic Extended Events Session
-------------------------------------------------
/*
  Create a simple Extended Events session to capture SQL statements.
  This session captures completed SQL statements with their duration,
  CPU usage, and I/O statistics.
*/
CREATE EVENT SESSION BasicQueryCapture ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.username
    )
    WHERE duration > 1000000 -- 1 second in microseconds
)
ADD TARGET package0.event_file
(
    SET filename = N'E:\ExtendedEvents\BasicQueryCapture.xel',
    max_file_size = 10, -- 10 MB
    max_rollover_files = 5
);
GO

/*
  Start the Extended Events session.
*/
ALTER EVENT SESSION BasicQueryCapture ON SERVER STATE = START;
GO

-------------------------------------------------
-- Region: 3. Creating an Advanced Monitoring Session
-------------------------------------------------
/*
  Create a more comprehensive session for performance monitoring.
  This captures query timeouts, deadlocks, and long-running queries.
*/
CREATE EVENT SESSION QueryPerformanceMonitoring ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.query_hash,
        sqlserver.query_plan_hash,
        sqlserver.session_id
    )
    WHERE duration > 5000000 -- 5 seconds in microseconds
),
ADD EVENT sqlserver.rpc_completed
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.query_hash,
        sqlserver.query_plan_hash,
        sqlserver.session_id
    )
    WHERE duration > 5000000 -- 5 seconds in microseconds
),
ADD EVENT sqlserver.lock_timeout
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.session_id
    )
),
ADD EVENT sqlserver.xml_deadlock_report
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.session_id
    )
)
ADD TARGET package0.event_file
(
    SET filename = N'E:\ExtendedEvents\QueryPerformanceMonitoring.xel',
    max_file_size = 50, -- 50 MB
    max_rollover_files = 10
),
ADD TARGET package0.ring_buffer
(
    SET max_memory = 4096 -- 4 MB
);
GO

/*
  Start the Extended Events session.
*/
ALTER EVENT SESSION QueryPerformanceMonitoring ON SERVER STATE = START;
GO

-------------------------------------------------
-- Region: 4. Creating a Session with Advanced Filtering
-------------------------------------------------
/*
  Create a session with complex filtering conditions.
  This demonstrates the power of Extended Events predicates.
*/
CREATE EVENT SESSION AdvancedFiltering ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.query_hash
    )
    WHERE 
        -- Filter by database
        (sqlserver.database_name = N'QueryStoreDemo')
        -- And either long duration or high CPU
        AND 
        (
            duration > 1000000 -- 1 second
            OR cpu_time > 500000 -- 0.5 seconds
        )
        -- And not from maintenance jobs
        AND sqlserver.client_app_name <> N'SQLServerAgent'
)
ADD TARGET package0.event_file
(
    SET filename = N'E:\ExtendedEvents\AdvancedFiltering.xel'
);
GO

/*
  Start the Extended Events session.
*/
ALTER EVENT SESSION AdvancedFiltering ON SERVER STATE = START;
GO

-------------------------------------------------
-- Region: 5. Using the Histogram Target
-------------------------------------------------
/*
  Create a session using the histogram target to aggregate event data.
  This is useful for identifying patterns without collecting large amounts of data.
*/
CREATE EVENT SESSION QueryHistogram ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.query_hash
    )
    WHERE duration > 100000 -- 0.1 seconds
)
ADD TARGET package0.histogram
(
    SET 
        -- Group by query_hash
        slots = 64,
        filtering_event_name = 'sqlserver.sql_statement_completed',
        source_type = 1, -- Action
        source = 'sqlserver.query_hash'
);
GO

/*
  Start the Extended Events session.
*/
ALTER EVENT SESSION QueryHistogram ON SERVER STATE = START;
GO

-------------------------------------------------
-- Region: 6. Querying Extended Events Data
-------------------------------------------------
/*
  Query the ring buffer target to see live data without reading XEL files.
*/
SELECT
    event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    event_data.value('(event/@timestamp)[1]', 'datetime2') AS event_timestamp,
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text,
    event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(128)') AS database_name,
    event_data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(128)') AS username,
    event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') / 1000.0 AS duration_ms
FROM
(
    SELECT CAST(target_data AS XML) AS target_data
    FROM sys.dm_xe_session_targets st
    JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
    WHERE s.name = 'QueryPerformanceMonitoring'
    AND st.target_name = 'ring_buffer'
) AS data
CROSS APPLY target_data.nodes('RingBufferTarget/event') AS events(event_data)
ORDER BY event_timestamp DESC;
GO

/*
  Query the histogram target to see aggregated data.
*/
SELECT
    n.value('(@count)[1]', 'bigint') AS event_count,
    n.value('(value)[1]', 'nvarchar(4000)') AS query_hash
FROM
(
    SELECT CAST(target_data AS XML) AS target_data
    FROM sys.dm_xe_session_targets st
    JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
    WHERE s.name = 'QueryHistogram'
    AND st.target_name = 'histogram'
) AS data
CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS slots(n)
ORDER BY event_count DESC;
GO

-------------------------------------------------
-- Region: 7. Reading From XEL Files
-------------------------------------------------
/*
  Create a query to read data from XEL files using sys.fn_xe_file_target_read_file.
  This is useful for analyzing data after it's been collected.
*/
-- Query data from XEL files (adjust the file path as needed)
SELECT
    event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    event_data.value('(event/@timestamp)[1]', 'datetime2') AS event_timestamp,
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text,
    event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(128)') AS database_name,
    event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') / 1000.0 AS duration_ms,
    event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') / 1000.0 AS cpu_time_ms,
    event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads
FROM
(
    SELECT CAST(event_data AS XML) AS event_data
    FROM sys.fn_xe_file_target_read_file
    (
        'E:\ExtendedEvents\BasicQueryCapture*.xel',
        NULL,
        NULL,
        NULL
    )
) AS raw_data
ORDER BY event_timestamp DESC;
GO

-------------------------------------------------
-- Region: 8. Blocking and Wait Statistics Monitoring
-------------------------------------------------
/*
  Create a session to monitor blocking and wait statistics.
  This helps identify performance bottlenecks in the system.
*/
CREATE EVENT SESSION BlockingMonitoring ON SERVER
ADD EVENT sqlserver.blocked_process_report
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_hostname,
        sqlserver.username
    )
),
ADD EVENT sqlos.wait_info
(
    ACTION
    (
        sqlserver.sql_text,
        sqlserver.session_id,
        sqlserver.database_name
    )
    WHERE 
        -- Filter common benign waits
        opcode = 1 -- End of wait
        AND duration > 500000 -- 0.5 seconds
        AND wait_type NOT IN (0, 1, 2, 3, 6) -- Exclude QDS, BROKER, etc.
)
ADD TARGET package0.event_file
(
    SET filename = N'E:\ExtendedEvents\BlockingMonitoring.xel',
    max_file_size = 20,
    max_rollover_files = 5
);
GO

/*
  Configure the blocked process threshold (in seconds)
*/
EXEC sp_configure 'blocked process threshold (s)', 10;
GO
RECONFIGURE;
GO

/*
  Start the Extended Events session.
*/
ALTER EVENT SESSION BlockingMonitoring ON SERVER STATE = START;
GO

-------------------------------------------------
-- Region: 9. Cleanup
-------------------------------------------------
/*
  Stop and drop all Extended Events sessions created in this script.
*/
-- Uncomment the following lines to clean up all sessions
/*
ALTER EVENT SESSION BasicQueryCapture ON SERVER STATE = STOP;
GO
DROP EVENT SESSION BasicQueryCapture ON SERVER;
GO

ALTER EVENT SESSION QueryPerformanceMonitoring ON SERVER STATE = STOP;
GO
DROP EVENT SESSION QueryPerformanceMonitoring ON SERVER;
GO

ALTER EVENT SESSION AdvancedFiltering ON SERVER STATE = STOP;
GO
DROP EVENT SESSION AdvancedFiltering ON SERVER;
GO

ALTER EVENT SESSION QueryHistogram ON SERVER STATE = STOP;
GO
DROP EVENT SESSION QueryHistogram ON SERVER;
GO

ALTER EVENT SESSION BlockingMonitoring ON SERVER STATE = STOP;
GO
DROP EVENT SESSION BlockingMonitoring ON SERVER;
GO

-- Reset blocked process threshold
EXEC sp_configure 'blocked process threshold (s)', 0;
GO
RECONFIGURE;
GO
*/

-------------------------------------------------
-- End of Script
-------------------------------------------------