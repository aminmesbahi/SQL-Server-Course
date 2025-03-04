/**************************************************************
 * SQL Server 2022 Query Store Tutorial
 * Description: This script demonstrates how to work with Query Store
 *              in SQL Server 2022. It covers:
 *              - Enabling and configuring Query Store
 *              - Monitoring query performance
 *              - Identifying problematic queries
 *              - Forcing execution plans
 *              - Query Store DMVs
 *              - Analyzing plan regressions
 *              - Query Store maintenance and cleanup
 **************************************************************/

-------------------------------------------------
-- Region: 1. Enabling and Configuring Query Store
-------------------------------------------------
USE master;
GO

/*
  Create a test database for Query Store examples.
*/
IF DB_ID('QueryStoreDemo') IS NOT NULL
    DROP DATABASE QueryStoreDemo;
GO

CREATE DATABASE QueryStoreDemo;
GO

USE QueryStoreDemo;
GO

/*
  Enable Query Store with custom settings.
  - OPERATION_MODE = READ_WRITE: Actively collect query data
  - MAX_STORAGE_SIZE_MB = 1024: 1GB storage limit
  - INTERVAL_LENGTH_MINUTES = 15: Capture stats every 15 minutes
  - STALE_QUERY_THRESHOLD_DAYS = 30: Keep query data for 30 days
  - QUERY_CAPTURE_MODE = ALL: Capture all queries (can also use AUTO or CUSTOM)
*/
ALTER DATABASE QueryStoreDemo
SET QUERY_STORE = ON
    (OPERATION_MODE = READ_WRITE,
     MAX_STORAGE_SIZE_MB = 1024,
     INTERVAL_LENGTH_MINUTES = 15,
     SIZE_BASED_CLEANUP_MODE = AUTO,
     STALE_QUERY_THRESHOLD_DAYS = 30,
     QUERY_CAPTURE_MODE = ALL,
     DATA_FLUSH_INTERVAL_SECONDS = 900,
     MAX_PLANS_PER_QUERY = 200,
     WAIT_STATS_CAPTURE_MODE = ON);
GO

/*
  Verify Query Store configuration.
*/
SELECT actual_state_desc, desired_state_desc,
       current_storage_size_mb, max_storage_size_mb,
       interval_length_minutes, stale_query_threshold_days,
       query_capture_mode_desc, size_based_cleanup_mode_desc,
       wait_stats_capture_mode_desc
FROM sys.database_query_store_options;
GO

-------------------------------------------------
-- Region: 2. Creating Sample Schema and Data
-------------------------------------------------
/*
  Create a simple schema with sample data for Query Store testing.
*/
CREATE TABLE dbo.Products
(
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    InventoryCount INT NOT NULL,
    DateAdded DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_Products_Category ON dbo.Products(Category);
CREATE INDEX IX_Products_Price ON dbo.Products(Price);
GO

/*
  Insert sample data with enough rows to generate interesting query plans.
*/
INSERT INTO dbo.Products (ProductName, Category, Price, InventoryCount, DateAdded)
SELECT 
    'Product ' + CAST(n AS NVARCHAR(10)),
    CASE (ABS(CHECKSUM(NEWID())) % 5)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Food'
        WHEN 3 THEN 'Books'
        WHEN 4 THEN 'Toys'
    END,
    (ABS(CHECKSUM(NEWID())) % 100) + 0.99,
    (ABS(CHECKSUM(NEWID())) % 1000),
    DATEADD(DAY, -1 * (ABS(CHECKSUM(NEWID())) % 365), GETDATE())
FROM 
    sys.objects a
CROSS JOIN 
    sys.objects b
WHERE 
    a.object_id < 100 AND b.object_id < 100;
GO

-- Update statistics
UPDATE STATISTICS dbo.Products;
GO

-------------------------------------------------
-- Region: 3. Generating Query Workload
-------------------------------------------------
/*
  Execute a variety of queries to generate data for Query Store.
*/

-- Simple query with index scan
SELECT * FROM dbo.Products WHERE Price < 50.00;
GO 5

-- Query with aggregation
SELECT Category, AVG(Price) AS AvgPrice, SUM(InventoryCount) AS TotalInventory
FROM dbo.Products
GROUP BY Category;
GO 5

-- Join with sorting
SELECT p1.ProductName, p1.Category, p1.Price
FROM dbo.Products p1
INNER JOIN dbo.Products p2 ON p1.Category = p2.Category AND p1.ProductID <> p2.ProductID
WHERE p1.Price > 75.00
ORDER BY p1.Price DESC;
GO 5

-- Query with parameter sniffing scenario
DECLARE @PriceThreshold DECIMAL(10,2) = 50.00;
SELECT * FROM dbo.Products WHERE Price < @PriceThreshold;
GO 5

SET @PriceThreshold = 25.00;
SELECT * FROM dbo.Products WHERE Price < @PriceThreshold;
GO 5

-- Force a deliberate sub-optimal plan by adding hints
SELECT * FROM dbo.Products WITH (INDEX=IX_Products_Price)
WHERE Category = 'Electronics';
GO 5

-------------------------------------------------
-- Region: 4. Querying Query Store Views
-------------------------------------------------
/*
  Query the Query Store views to analyze performance data.
*/

-- Top 10 queries by execution count
SELECT TOP 10 
    q.query_id,
    qt.query_sql_text,
    rs.count_executions,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.avg_cpu_time / 1000.0 AS avg_cpu_time_ms,
    rs.avg_logical_io_reads,
    rs.avg_logical_io_writes,
    rs.avg_physical_io_reads,
    rs.last_execution_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
ORDER BY rs.count_executions DESC;
GO

-- Top 10 queries by average CPU time
SELECT TOP 10 
    q.query_id,
    qt.query_sql_text,
    rs.count_executions,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.avg_cpu_time / 1000.0 AS avg_cpu_time_ms,
    rs.avg_logical_io_reads,
    rs.avg_logical_io_writes,
    p.plan_id
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_cpu_time DESC;
GO

-- Queries with multiple plans (potential plan choice regression)
SELECT 
    q.query_id,
    qt.query_sql_text,
    COUNT(DISTINCT p.plan_id) AS number_of_plans
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
GROUP BY q.query_id, qt.query_sql_text
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY COUNT(DISTINCT p.plan_id) DESC;
GO

-- Wait statistics for queries
SELECT TOP 20
    q.query_id,
    qt.query_sql_text,
    wait_category_desc,
    SUM(ws.avg_query_wait_time_ms) AS total_wait_time_ms
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_wait_stats ws ON p.plan_id = ws.plan_id
GROUP BY q.query_id, qt.query_sql_text, wait_category_desc
ORDER BY SUM(ws.avg_query_wait_time_ms) DESC;
GO

-------------------------------------------------
-- Region: 5. Forcing Execution Plans
-------------------------------------------------
/*
  Identify a query with multiple plans and force the better plan.
*/

-- Find a query with multiple plans (from our previous queries)
DECLARE @QueryID INT;
DECLARE @BestPlanID INT;

-- Get a query with multiple plans
SELECT TOP 1 
    @QueryID = q.query_id
FROM sys.query_store_query q
JOIN sys.query_store_plan p ON q.query_id = p.query_id
GROUP BY q.query_id
HAVING COUNT(DISTINCT p.plan_id) > 1;

-- Find the plan with the best average performance
SELECT TOP 1 
    @BestPlanID = p.plan_id
FROM sys.query_store_plan p
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.query_id = @QueryID
ORDER BY rs.avg_duration ASC;

-- Force the best plan
IF @QueryID IS NOT NULL AND @BestPlanID IS NOT NULL
BEGIN
    EXEC sp_query_store_force_plan @query_id = @QueryID, @plan_id = @BestPlanID;
    
    PRINT 'Forced plan ' + CAST(@BestPlanID AS NVARCHAR(10)) + 
          ' for query ' + CAST(@QueryID AS NVARCHAR(10));
END
ELSE
    PRINT 'No suitable query found for plan forcing.';
GO

-- View forced plans
SELECT 
    q.query_id, 
    qt.query_sql_text,
    p.plan_id,
    p.is_forced_plan,
    p.force_failure_count,
    p.last_force_failure_reason_desc
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
WHERE p.is_forced_plan = 1;
GO

-- Unforce a plan (if needed)
DECLARE @QueryID INT;

SELECT TOP 1 @QueryID = query_id
FROM sys.query_store_plan
WHERE is_forced_plan = 1;

IF @QueryID IS NOT NULL
BEGIN
    EXEC sp_query_store_unforce_plan @query_id = @QueryID, @plan_id = NULL;
    PRINT 'Unforced plan for query ' + CAST(@QueryID AS NVARCHAR(10));
END
GO

-------------------------------------------------
-- Region: 6. Finding Regressed Queries
-------------------------------------------------
/*
  Find queries whose performance has regressed over time.
*/
WITH QueryRuntimeStats AS
(
    SELECT 
        q.query_id,
        qt.query_sql_text,
        rsi.start_time AS interval_start,
        rsi.end_time AS interval_end,
        AVG(rs.avg_duration) AS avg_duration_microsec
    FROM sys.query_store_query q
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
    JOIN sys.query_store_plan p ON q.query_id = p.query_id
    JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    GROUP BY q.query_id, qt.query_sql_text, rsi.start_time, rsi.end_time
)
SELECT 
    q1.query_id,
    q1.query_sql_text,
    q1.interval_start AS older_interval_start,
    q2.interval_start AS newer_interval_start,
    q1.avg_duration_microsec / 1000.0 AS older_avg_duration_ms,
    q2.avg_duration_microsec / 1000.0 AS newer_avg_duration_ms,
    (q2.avg_duration_microsec - q1.avg_duration_microsec) / 1000.0 AS duration_difference_ms,
    (q2.avg_duration_microsec * 100.0 / NULLIF(q1.avg_duration_microsec, 0)) - 100 AS pct_change
FROM QueryRuntimeStats q1
JOIN QueryRuntimeStats q2 ON q1.query_id = q2.query_id AND q1.interval_start < q2.interval_start
WHERE (q2.avg_duration_microsec * 100.0 / NULLIF(q1.avg_duration_microsec, 0)) - 100 > 20 -- More than 20% regression
ORDER BY (q2.avg_duration_microsec - q1.avg_duration_microsec) DESC;
GO

-------------------------------------------------
-- Region: 7. Query Store Maintenance
-------------------------------------------------
/*
  Query Store maintenance tasks such as purging old data, 
  checking storage usage, and configuring retention policies.
*/

-- Check Query Store size and space usage
SELECT DB_NAME(database_id) AS DatabaseName,
       current_storage_size_mb,
       max_storage_size_mb,
       (current_storage_size_mb * 100.0 / NULLIF(max_storage_size_mb, 0)) AS pct_used
FROM sys.database_query_store_options;
GO

-- Purge old data manually if needed
ALTER DATABASE QueryStoreDemo 
SET QUERY_STORE CLEAR;
GO

-- Purge data for a specific query
DECLARE @QueryID INT = 1; -- Replace with actual query_id
EXEC sp_query_store_remove_query @query_id = @QueryID;
GO

-- Purge data for a specific time period
DECLARE @StartTime DATETIME = DATEADD(DAY, -7, GETDATE());
DECLARE @EndTime DATETIME = DATEADD(DAY, -5, GETDATE());
EXEC sp_query_store_remove_query @from_start_time = @StartTime, @to_end_time = @EndTime;
GO

-- Reconfigure Query Store settings to optimize for your workload
ALTER DATABASE QueryStoreDemo
SET QUERY_STORE = ON
    (OPERATION_MODE = READ_WRITE,
     MAX_STORAGE_SIZE_MB = 2048,            -- Increased to 2GB
     INTERVAL_LENGTH_MINUTES = 30,          -- Changed to 30 min intervals
     SIZE_BASED_CLEANUP_MODE = AUTO,
     STALE_QUERY_THRESHOLD_DAYS = 60,       -- Keep data for 60 days
     QUERY_CAPTURE_MODE = AUTO,             -- AUTO mode to focus on relevant queries
     DATA_FLUSH_INTERVAL_SECONDS = 900,
     MAX_PLANS_PER_QUERY = 200,
     WAIT_STATS_CAPTURE_MODE = ON);
GO

-------------------------------------------------
-- Region: 8. Advanced Query Store Features
-------------------------------------------------
/*
  Advanced Query Store features introduced in SQL Server 2019 and 2022.
*/

-- Configure custom capture policy (SQL Server 2019+)
ALTER DATABASE QueryStoreDemo 
SET QUERY_STORE = ON
(
    QUERY_CAPTURE_MODE = CUSTOM,
    CUSTOMIZED_CAPTURING_POLICY = (
        EXECUTION_COUNT >= 2,
        TOTAL_COMPILE_CPU_TIME_MS >= 1000,
        TOTAL_EXECUTION_CPU_TIME_MS >= 100
    )
);
GO

-- Query Optimization stats (SQL Server 2022+)
SELECT TOP 10
    q.query_id,
    qt.query_sql_text,
    p.plan_id,
    p.query_plan,
    p.compile_cpu_time_ms,
    p.compile_memory_kb,
    p.compile_duration_ms,
    p.optimization_level_desc
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
ORDER BY p.compile_cpu_time_ms DESC;
GO

-------------------------------------------------
-- Region: 9. Cleanup
-------------------------------------------------
USE master;
GO

/*
  Clean up resources by dropping the test database.
*/
-- Uncomment the following line to clean up resources:
-- DROP DATABASE QueryStoreDemo;
-- GO