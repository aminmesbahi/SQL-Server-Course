/**************************************************************
 * SQL Server 2022 Resource Governor Tutorial
 * Description: This script demonstrates how to implement and use
 *              Resource Governor in SQL Server 2022. It covers:
 *              - Creating and configuring resource pools
 *              - Creating and configuring workload groups
 *              - Creating a classifier function
 *              - Enabling and testing Resource Governor
 *              - Monitoring resource usage
 *              - Managing external resources
 **************************************************************/

-------------------------------------------------
-- Region: 1. Setup and Configuration
-------------------------------------------------
USE master;
GO

/*
  Create a classifier function that will route connections to specific workload groups.
  This function uses the APP_NAME() to determine which group a connection belongs to.
*/
CREATE FUNCTION dbo.ClassifierFunction()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @WorkloadGroup SYSNAME;
    
    IF APP_NAME() LIKE 'ReportingApp%'
        SET @WorkloadGroup = 'ReportingWorkloadGroup';
    ELSE IF APP_NAME() LIKE 'ProcessingApp%'
        SET @WorkloadGroup = 'ProcessingWorkloadGroup';
    ELSE
        SET @WorkloadGroup = 'DefaultWorkloadGroup';
        
    RETURN @WorkloadGroup;
END;
GO

-------------------------------------------------
-- Region: 2. Creating Resource Pools
-------------------------------------------------
/*
  Create resource pools to allocate specific resources to different workloads.
  - ReportingPool: For reporting queries, limited to 30% CPU and 30% memory
  - ProcessingPool: For data processing, limited to 40% CPU and 40% memory
*/
CREATE RESOURCE POOL ReportingPool 
WITH (
    MIN_CPU_PERCENT = 10,
    MAX_CPU_PERCENT = 30,
    MIN_MEMORY_PERCENT = 10,
    MAX_MEMORY_PERCENT = 30
);
GO

CREATE RESOURCE POOL ProcessingPool 
WITH (
    MIN_CPU_PERCENT = 20,
    MAX_CPU_PERCENT = 40,
    MIN_MEMORY_PERCENT = 20,
    MAX_MEMORY_PERCENT = 40
);
GO

-------------------------------------------------
-- Region: 3. Creating Workload Groups
-------------------------------------------------
/*
  Create workload groups within the resource pools to categorize different types of workloads.
  Each group has specific resource allocations and request limits.
*/
CREATE WORKLOAD GROUP ReportingWorkloadGroup
WITH (
    IMPORTANCE = MEDIUM,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 25,
    REQUEST_MAX_CPU_TIME_SEC = 60,
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 30,
    MAX_DOP = 4,
    GROUP_MAX_REQUESTS = 100
) USING ReportingPool;
GO

CREATE WORKLOAD GROUP ProcessingWorkloadGroup
WITH (
    IMPORTANCE = HIGH,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 35,
    REQUEST_MAX_CPU_TIME_SEC = 120,
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 60,
    MAX_DOP = 8,
    GROUP_MAX_REQUESTS = 50
) USING ProcessingPool;
GO

CREATE WORKLOAD GROUP DefaultWorkloadGroup
WITH (
    IMPORTANCE = LOW,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 10,
    REQUEST_MAX_CPU_TIME_SEC = 30,
    MAX_DOP = 2,
    GROUP_MAX_REQUESTS = 200
) USING "default";
GO

-------------------------------------------------
-- Region: 4. Configuring and Enabling Resource Governor
-------------------------------------------------
/*
  Configure Resource Governor to use the classifier function and then enable it.
*/
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.ClassifierFunction);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-------------------------------------------------
-- Region: 5. Testing Resource Governor
-------------------------------------------------
/*
  Test the Resource Governor by executing queries with different application names.
*/

-- Simulate a reporting application
EXEC sp_executesql N'
SET NOCOUNT ON;
DECLARE @AppName NVARCHAR(128) = ''ReportingApp1'';
EXEC sp_set_session_context ''APP_NAME'', @AppName;

-- Reporting query
SELECT TOP 1000 * 
FROM sys.objects a
CROSS JOIN sys.objects b
ORDER BY a.object_id;
';
GO

-- Simulate a processing application
EXEC sp_executesql N'
SET NOCOUNT ON;
DECLARE @AppName NVARCHAR(128) = ''ProcessingApp1'';
EXEC sp_set_session_context ''APP_NAME'', @AppName;

-- Processing query
SELECT TOP 1000 * 
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c
ORDER BY a.object_id;
';
GO

-------------------------------------------------
-- Region: 6. Monitoring Resource Governor Usage
-------------------------------------------------
/*
  Query DMVs to monitor resource usage by pool and workload group.
*/
SELECT 
    pool_name,
    min_cpu_percent,
    max_cpu_percent,
    min_memory_percent,
    max_memory_percent,
    used_memory_kb,
    max_memory_kb
FROM sys.dm_resource_governor_resource_pools;
GO

SELECT 
    group_name,
    pool_name,
    total_request_count,
    active_request_count,
    queued_request_count,
    total_cpu_usage_ms,
    total_cpu_limit_violation_count
FROM sys.dm_resource_governor_workload_groups wg
JOIN sys.dm_resource_governor_resource_pools rp
    ON wg.pool_id = rp.pool_id;
GO

-------------------------------------------------
-- Region: 7. External Resource Pools (SQL Server 2019+)
-------------------------------------------------
/*
  Configure external resource pools for R, Python, or Java workloads.
*/
CREATE EXTERNAL RESOURCE POOL ExtRPool
WITH (
    MAX_CPU_PERCENT = 20,
    MAX_MEMORY_PERCENT = 20,
    MAX_PROCESSES = 10
);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-------------------------------------------------
-- Region: 8. Cleanup (Optional)
-------------------------------------------------
/*
  Disable Resource Governor and drop the created objects.
*/
-- Uncomment the following lines to clean up:
/*
ALTER RESOURCE GOVERNOR DISABLE;
GO

IF EXISTS (SELECT 1 FROM sys.workload_management_workload_groups 
           WHERE name = 'ReportingWorkloadGroup')
    DROP WORKLOAD GROUP ReportingWorkloadGroup;
GO

IF EXISTS (SELECT 1 FROM sys.workload_management_workload_groups 
           WHERE name = 'ProcessingWorkloadGroup')
    DROP WORKLOAD GROUP ProcessingWorkloadGroup;
GO

IF EXISTS (SELECT 1 FROM sys.workload_management_workload_groups 
           WHERE name = 'DefaultWorkloadGroup')
    DROP WORKLOAD GROUP DefaultWorkloadGroup;
GO

IF EXISTS (SELECT 1 FROM sys.dm_resource_governor_resource_pools 
           WHERE name = 'ReportingPool')
    DROP RESOURCE POOL ReportingPool;
GO

IF EXISTS (SELECT 1 FROM sys.dm_resource_governor_resource_pools 
           WHERE name = 'ProcessingPool')
    DROP RESOURCE POOL ProcessingPool;
GO

IF EXISTS (SELECT 1 FROM sys.external_resource_pools 
           WHERE name = 'ExtRPool')
    DROP EXTERNAL RESOURCE POOL ExtRPool;
GO

DROP FUNCTION dbo.ClassifierFunction;
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
*/