/**************************************************************
 * SQL Server 2022 Advanced Partitioning Tutorial
 * Description: This script demonstrates comprehensive table 
 *              partitioning techniques in SQL Server 2022. It covers:
 *              - Multiple filegroups for partition storage
 *              - Date-based partitioning strategies
 *              - Sliding window partition management
 *              - Partitioned columnstore indexes
 *              - Filtered indexes on partitions
 *              - Partition compression strategies
 *              - Partition alignment for multiple tables
 *              - Dynamic partition management
 *              - Partition-level operations and maintenance
 **************************************************************/

-------------------------------------------------
-- Region: 1. Advanced Database and Storage Setup
-------------------------------------------------
/*
  Create a database with multiple filegroups for partition storage.
  Each filegroup can be placed on different storage devices for performance.
*/
CREATE DATABASE PartitionAdvancedDB
ON PRIMARY 
(
    NAME = PartitionAdvancedDB_Primary,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Primary.mdf',
    SIZE = 100MB
),
FILEGROUP FG_Archive
(
    NAME = PartitionAdvancedDB_Archive,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Archive.ndf',
    SIZE = 100MB
),
FILEGROUP FG_Current
(
    NAME = PartitionAdvancedDB_Current,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Current.ndf',
    SIZE = 100MB
),
FILEGROUP FG_Future
(
    NAME = PartitionAdvancedDB_Future,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Future.ndf',
    SIZE = 100MB
)
LOG ON
(
    NAME = PartitionAdvancedDB_Log,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Log.ldf',
    SIZE = 100MB
);
GO

USE PartitionAdvancedDB;
GO

-------------------------------------------------
-- Region: 2. Date-Based Partitioning for Sales Data
-------------------------------------------------
/*
  Create a partition function that partitions data by month.
  This is ideal for time-series data like sales or logs.
*/
CREATE PARTITION FUNCTION PF_Monthly (DATE)
AS RANGE RIGHT FOR VALUES (
    '2022-01-01', '2022-02-01', '2022-03-01', 
    '2022-04-01', '2022-05-01', '2022-06-01',
    '2022-07-01', '2022-08-01', '2022-09-01',
    '2022-10-01', '2022-11-01', '2022-12-01',
    '2023-01-01'
);
GO

/*
  Create a partition scheme that maps different date ranges to different filegroups.
  - Archive data (older than 6 months) goes to the archive filegroup
  - Current data (recent 6 months) goes to the current filegroup
  - Future data (next month) goes to the future filegroup
*/
CREATE PARTITION SCHEME PS_Monthly
AS PARTITION PF_Monthly
TO (
    FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, -- Jan-Jul 2022 (Archive)
    FG_Current, FG_Current, FG_Current, FG_Current, FG_Current,                         -- Aug-Dec 2022 (Current)
    FG_Future                                                                           -- Jan 2023+ (Future)
);
GO

/*
  Create a partitioned sales fact table with date-based partitioning.
*/
CREATE TABLE Sales_Fact
(
    SaleID INT IDENTITY(1,1) NOT NULL,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    StoreID INT NOT NULL,
    CustomerID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_Sales_Fact PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
) ON PS_Monthly(SaleDate);
GO

/*
  Create dimension tables to support the sales fact table.
*/
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Stores (
    StoreID INT PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    Region NVARCHAR(50) NOT NULL
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    State NVARCHAR(50) NOT NULL
);
GO

/*
  Create indexes with partition alignment to improve query performance.
  The indexes are aligned with the same partition scheme as the table.
*/
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact 
ON Sales_Fact
WITH (DROP_EXISTING = OFF)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Product
ON Sales_Fact(ProductID, SaleDate)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Store
ON Sales_Fact(StoreID, SaleDate)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Customer
ON Sales_Fact(CustomerID, SaleDate)
ON PS_Monthly(SaleDate);
GO

-------------------------------------------------
-- Region: 3. Populating Partitioned Tables
-------------------------------------------------
/*
  Insert sample data into dimension tables.
*/
INSERT INTO Products (ProductID, ProductName, Category, Price)
VALUES 
    (1, 'Laptop', 'Electronics', 1200.00),
    (2, 'Smartphone', 'Electronics', 800.00),
    (3, 'Desk Chair', 'Furniture', 250.00),
    (4, 'Coffee Maker', 'Appliances', 65.00),
    (5, 'Headphones', 'Electronics', 120.00);
GO

INSERT INTO Stores (StoreID, StoreName, Region)
VALUES 
    (1, 'Downtown Store', 'East'),
    (2, 'Mall Location', 'West'),
    (3, 'Online Store', 'Online');
GO

INSERT INTO Customers (CustomerID, CustomerName, City, State)
VALUES
    (1, 'Alice Johnson', 'Seattle', 'WA'),
    (2, 'Bob Smith', 'Portland', 'OR'),
    (3, 'Charlie Davis', 'San Francisco', 'CA'),
    (4, 'Diana Miller', 'Chicago', 'IL'),
    (5, 'Edward Wilson', 'New York', 'NY');
GO

/*
  Create a procedure to generate realistic sales data across multiple partitions.
*/
CREATE OR ALTER PROCEDURE Generate_Sales_Data
    @StartDate DATE,
    @EndDate DATE,
    @RowCount INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = @StartDate;
    DECLARE @CurrentCount INT = 0;
    DECLARE @MaxProduct INT = (SELECT MAX(ProductID) FROM Products);
    DECLARE @MaxStore INT = (SELECT MAX(StoreID) FROM Stores);
    DECLARE @MaxCustomer INT = (SELECT MAX(CustomerID) FROM Customers);
    
    WHILE @CurrentDate <= @EndDate AND @CurrentCount < @RowCount
    BEGIN
        DECLARE @BatchSize INT = 1000;
        DECLARE @BatchCount INT = 0;
        
        WHILE @BatchCount < @BatchSize AND @CurrentCount < @RowCount
        BEGIN
            INSERT INTO Sales_Fact (SaleDate, ProductID, StoreID, CustomerID, Quantity, Amount)
            SELECT 
                @CurrentDate,
                ABS(CHECKSUM(NEWID())) % @MaxProduct + 1,
                ABS(CHECKSUM(NEWID())) % @MaxStore + 1,
                ABS(CHECKSUM(NEWID())) % @MaxCustomer + 1,
                ABS(CHECKSUM(NEWID())) % 10 + 1,  -- Quantity between 1 and 10
                CAST(ABS(CHECKSUM(NEWID()) % 100000) / 100.0 + 10.0 AS DECIMAL(10,2))  -- Amount between $10 and $1000
            
            SET @BatchCount = @BatchCount + 1;
            SET @CurrentCount = @CurrentCount + 1;
        END
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END
    
    PRINT 'Generated ' + CAST(@CurrentCount AS VARCHAR(10)) + ' sales records';
END;
GO

/*
  Generate sample sales data for each month in 2022.
*/
EXEC Generate_Sales_Data '2022-01-01', '2022-12-31', 10000;
GO

-------------------------------------------------
-- Region: 4. Partition Information and Maintenance
-------------------------------------------------
/*
  Query to show the partition distribution of the Sales_Fact table.
*/
SELECT 
    p.partition_number AS PartitionNumber,
    fg.name AS FileGroupName,
    p.rows AS RowCount,
    CAST(prv.value AS DATE) AS BoundaryValue,
    CASE
        WHEN p.partition_number = 1 THEN 'First Partition'
        WHEN prv.value IS NULL THEN 'Last Partition'
        ELSE ''
    END AS Notes
FROM sys.partitions p
INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
INNER JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id 
    AND p.partition_number = dds.destination_id
INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
    AND p.partition_number = prv.boundary_id + 1
WHERE i.object_id = OBJECT_ID('Sales_Fact') AND i.index_id = 1
ORDER BY p.partition_number;
GO

/*
  Procedure to rebuild and reorganize indexes for specific partitions.
*/
CREATE OR ALTER PROCEDURE Maintain_Partition_Indexes
    @TableName NVARCHAR(128),
    @PartitionNumber INT,
    @Action NVARCHAR(20) -- REBUILD or REORGANIZE
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @IndexName NVARCHAR(128);
    
    DECLARE index_cursor CURSOR FOR
    SELECT i.name
    FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(@TableName) 
    AND i.index_id > 0; -- Skip heaps
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @IndexName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Action = 'REBUILD'
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                       ' ON ' + QUOTENAME(@TableName) + 
                       ' REBUILD PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10)) + 
                       ' WITH (ONLINE = ON, DATA_COMPRESSION = PAGE)';
        END
        ELSE IF @Action = 'REORGANIZE'
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                       ' ON ' + QUOTENAME(@TableName) + 
                       ' REORGANIZE PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10));
        END
        
        PRINT 'Executing: ' + @SQL;
        EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM index_cursor INTO @IndexName;
    END
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
END;
GO

/*
  Apply index maintenance to specific partitions.
*/
EXEC Maintain_Partition_Indexes 'Sales_Fact', 8, 'REBUILD';  -- Rebuild current month partition
GO

-------------------------------------------------
-- Region: 5. Sliding Window Implementation
-------------------------------------------------
/*
  Create a procedure to implement the sliding window pattern.
  This pattern is commonly used for managing time-series data:
  1. Create a staging table for the new partition
  2. Add a new boundary to the partition function
  3. Switch in the new partition
  4. Switch out the oldest partition to an archive table
  5. Optionally remove the oldest boundary
*/
CREATE OR ALTER PROCEDURE Implement_Sliding_Window
    @NewBoundaryDate DATE,
    @RemoveOldestBoundary BIT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @OldestBoundaryValue DATE;
        
        -- 1. Get the oldest boundary value if we need to remove it
        IF @RemoveOldestBoundary = 1
        BEGIN
            SELECT TOP 1 @OldestBoundaryValue = CAST(prv.value AS DATE)
            FROM sys.partition_range_values prv
            INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
            WHERE pf.name = 'PF_Monthly'
            ORDER BY boundary_id;
        END
        
        -- 2. Create staging table for the next month data
        IF OBJECT_ID('dbo.Sales_Fact_Next', 'U') IS NOT NULL
            DROP TABLE dbo.Sales_Fact_Next;
            
        CREATE TABLE dbo.Sales_Fact_Next
        (
            SaleID INT IDENTITY(1,1) NOT NULL,
            SaleDate DATE NOT NULL,
            ProductID INT NOT NULL,
            StoreID INT NOT NULL,
            CustomerID INT NOT NULL,
            Quantity INT NOT NULL,
            Amount DECIMAL(10, 2) NOT NULL,
            CONSTRAINT PK_Sales_Fact_Next PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
        );
        
        -- 3. Create constraints and indexes identical to the main table
        CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Next 
        ON dbo.Sales_Fact_Next;
        
        -- 4. Split the partition function to add a new boundary
        ALTER PARTITION FUNCTION PF_Monthly() 
        SPLIT RANGE (@NewBoundaryDate);
        
        -- 5. Prepare archive table if needed
        IF @RemoveOldestBoundary = 1
        BEGIN
            IF OBJECT_ID('dbo.Sales_Fact_Archive', 'U') IS NOT NULL
                DROP TABLE dbo.Sales_Fact_Archive;
                
            SELECT *
            INTO dbo.Sales_Fact_Archive
            FROM dbo.Sales_Fact
            WHERE 1 = 0;
            
            -- Add identical constraints and indexes
            ALTER TABLE dbo.Sales_Fact_Archive 
            ADD CONSTRAINT PK_Sales_Fact_Archive PRIMARY KEY NONCLUSTERED (SaleID, SaleDate);
            
            CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Archive 
            ON dbo.Sales_Fact_Archive;
        END
        
        -- 6. Prepare metadata for the newest partition (highest partition number)
        DECLARE @PartitionCount INT;
        SELECT @PartitionCount = COUNT(*) 
        FROM sys.partitions 
        WHERE object_id = OBJECT_ID('Sales_Fact') AND index_id = 1;
        
        -- 7. Add data to the sales_fact_next table (would typically come from ETL)
        INSERT INTO dbo.Sales_Fact_Next (SaleDate, ProductID, StoreID, CustomerID, Quantity, Amount)
        SELECT 
            DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, @NewBoundaryDate),  -- Random day in the month
            ABS(CHECKSUM(NEWID())) % 5 + 1,  -- ProductID
            ABS(CHECKSUM(NEWID())) % 3 + 1,  -- StoreID
            ABS(CHECKSUM(NEWID())) % 5 + 1,  -- CustomerID
            ABS(CHECKSUM(NEWID())) % 10 + 1,  -- Quantity
            CAST(ABS(CHECKSUM(NEWID()) % 100000) / 100.0 + 10.0 AS DECIMAL(10,2))  -- Amount
        FROM sys.all_objects 
        CROSS JOIN (SELECT TOP 10 n = ROW_NUMBER() OVER (ORDER BY [object_id]) FROM sys.all_objects) AS nums
        WHERE [type] IN ('U', 'V')
        AND DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, @NewBoundaryDate) < DATEADD(MONTH, 1, @NewBoundaryDate);
        
        -- 8. Switch in the new partition
        ALTER TABLE dbo.Sales_Fact_Next
        SWITCH TO dbo.Sales_Fact PARTITION @PartitionCount;
        
        -- 9. If requested, switch out the oldest partition to the archive table
        IF @RemoveOldestBoundary = 1
        BEGIN
            ALTER TABLE dbo.Sales_Fact
            SWITCH PARTITION 1 TO dbo.Sales_Fact_Archive;
            
            -- 10. Merge the oldest boundary to remove it
            ALTER PARTITION FUNCTION PF_Monthly()
            MERGE RANGE (@OldestBoundaryValue);
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Sliding window operation completed successfully.';
        PRINT 'New boundary added: ' + CAST(@NewBoundaryDate AS NVARCHAR(20));
        IF @RemoveOldestBoundary = 1
            PRINT 'Oldest boundary removed: ' + CAST(@OldestBoundaryValue AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

/*
  Execute the sliding window procedure to add a new month.
*/
EXEC Implement_Sliding_Window '2023-02-01', 0;  -- Add February 2023, don't remove oldest
GO

EXEC Implement_Sliding_Window '2023-03-01', 1;  -- Add March 2023, remove January 2022
GO

-------------------------------------------------
-- Region: 6. Advanced Partition-Level Operations
-------------------------------------------------
/*
  Implement partition-level compression strategies based on data age.
*/
CREATE OR ALTER PROCEDURE Apply_Partition_Compression_Strategy
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PartitionNumber INT = 1;
    DECLARE @MaxPartition INT;
    
    -- Get the maximum partition number
    SELECT @MaxPartition = COUNT(*) 
    FROM sys.partitions 
    WHERE object_id = OBJECT_ID('Sales_Fact') AND index_id = 1;
    
    -- Apply compression strategies based on partition position
    WHILE @PartitionNumber <= @MaxPartition
    BEGIN
        -- Archive partitions (older): Use PAGE compression for best storage efficiency
        IF @PartitionNumber <= @MaxPartition - 6
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = PAGE)';
        END
        -- Current partitions (middle): Use ROW compression for balance
        ELSE IF @PartitionNumber <= @MaxPartition - 1
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = ROW)';
        END
        -- Latest partition: No compression for best insert performance
        ELSE
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = NONE)';
        END
        
        PRINT 'Applying compression to partition ' + CAST(@PartitionNumber AS NVARCHAR(10)) + ':';
        PRINT @SQL;
        EXEC sp_executesql @SQL;
        
        SET @PartitionNumber = @PartitionNumber + 1;
    END
END;
GO

/*
  Apply the compression strategy.
*/
EXEC Apply_Partition_Compression_Strategy;
GO

/*
  Create filtered indexes on specific partitions for specialized queries.
  This is achieved by combining partition scheme with WHERE predicates.
*/
CREATE NONCLUSTERED INDEX IX_Sales_Fact_HighValue
ON Sales_Fact (ProductID, Amount)
INCLUDE (SaleDate, CustomerID)
WHERE Amount > 500.00
ON PS_Monthly(SaleDate);
GO

-------------------------------------------------
-- Region: 7. Monitoring and Diagnostics
-------------------------------------------------
/*
  Create a view to monitor partition usage statistics.
*/
CREATE OR ALTER VIEW vw_Partition_Statistics
AS
WITH PartitionStats AS (
    SELECT 
        OBJECT_NAME(p.object_id) AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        p.partition_number,
        fg.name AS FileGroupName,
        CAST(prv.value AS DATE) AS BoundaryPoint,
        p.rows AS RowCount,
        SUM(a.total_pages) * 8 / 1024.0 AS TotalSizeMB,
        SUM(a.used_pages) * 8 / 1024.0 AS UsedSizeMB,
        SUM(a.data_pages) * 8 / 1024.0 AS DataSizeMB,
        (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024.0 AS UnusedSizeMB,
        CASE 
            WHEN p.data_compression = 0 THEN 'NONE'
            WHEN p.data_compression = 1 THEN 'ROW'
            WHEN p.data_compression = 2 THEN 'PAGE'
            WHEN p.data_compression = 3 THEN 'COLUMNSTORE'
            WHEN p.data_compression = 4 THEN 'COLUMNSTORE_ARCHIVE'
            ELSE 'UNKNOWN'
        END AS CompressionType
    FROM sys.partitions p
    INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
    INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
    INNER JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id 
        AND p.partition_number = dds.destination_id
    INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
        AND p.partition_number = prv.boundary_id + 1
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    WHERE i.object_id = OBJECT_ID('Sales_Fact')
    GROUP BY 
        OBJECT_NAME(p.object_id),
        i.name,
        i.type_desc,
        p.partition_number,
        fg.name,
        prv.value,
        p.rows,
        p.data_compression
)
SELECT * FROM PartitionStats;
GO

/*
  Query the view to see partition statistics.
*/
SELECT * FROM vw_Partition_Statistics ORDER BY partition_number;
GO

-------------------------------------------------
-- Region: 8. Dynamic Partition Management
-------------------------------------------------
/*
  Create a procedure for automated partition management based on date ranges.
  This is useful for long-term maintenance of time-partitioned tables.
*/
CREATE OR ALTER PROCEDURE Auto_Manage_Partitions
    @RetentionMonths INT = 24,  -- How many months of history to keep
    @FutureMonths INT = 3       -- How many months ahead to pre-allocate
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = GETDATE();
    DECLARE @OldestToKeep DATE = DATEADD(MONTH, -@RetentionMonths, @CurrentDate);
    DECLARE @FutureDate DATE = DATEADD(MONTH, @FutureMonths, @CurrentDate);
    
    -- 1. First day of current month
    DECLARE @CurrentMonth DATE = DATEFROMPARTS(YEAR(@CurrentDate), MONTH(@CurrentDate), 1);
    
    -- 2. Get the oldest boundary in the partition function
    DECLARE @OldestBoundary DATE;
    SELECT TOP 1 @OldestBoundary = CAST(prv.value AS DATE)
    FROM sys.partition_range_values prv
    INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
    WHERE pf.name = 'PF_Monthly'
    ORDER BY boundary_id;
    
    -- 3. Get the newest boundary in the partition function
    DECLARE @NewestBoundary DATE;
    SELECT TOP 1 @NewestBoundary = CAST(prv.value AS DATE)
    FROM sys.partition_range_values prv
    INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
    WHERE pf.name = 'PF_Monthly'
    ORDER BY boundary_id DESC;
    
    PRINT 'Current date: ' + CAST(@CurrentDate AS VARCHAR(20));
    PRINT 'Oldest boundary: ' + CAST(@OldestBoundary AS VARCHAR(20));
    PRINT 'Newest boundary: ' + CAST(@NewestBoundary AS VARCHAR(20));
    PRINT 'Retention threshold: ' + CAST(@OldestToKeep AS VARCHAR(20));
    PRINT 'Future threshold: ' + CAST(@FutureDate AS VARCHAR(20));
    
    -- 4. Remove partitions older than retention period
    WHILE @OldestBoundary < @OldestToKeep
    BEGIN
        PRINT 'Removing old partition boundary: ' + CAST(@OldestBoundary AS VARCHAR(20));
        
        -- Create archive table if it doesn't exist
        IF OBJECT_ID('dbo.Sales_Fact_Archive', 'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Sales_Fact_Archive
            (
                SaleID INT NOT NULL,
                SaleDate DATE NOT NULL,
                ProductID INT NOT NULL,
                StoreID INT NOT NULL,
                CustomerID INT NOT NULL,
                Quantity INT NOT NULL,
                Amount DECIMAL(10, 2) NOT NULL,
                CONSTRAINT PK_Sales_Fact_Archive PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
            );
            
            CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Archive 
            ON dbo.Sales_Fact_Archive;
        END
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Switch out oldest partition to archive
            ALTER TABLE dbo.Sales_Fact
            SWITCH PARTITION 1 TO dbo.Sales_Fact_Archive;
            
            -- Merge the range to remove the boundary
            ALTER PARTITION FUNCTION PF_Monthly()
            MERGE RANGE (@OldestBoundary);
            
            COMMIT TRANSACTION;
            
            -- Get the new oldest boundary
            SELECT TOP 1 @OldestBoundary = CAST(prv.value AS DATE)
            FROM sys.partition_range_values prv
            INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
            WHERE pf.name = 'PF_Monthly'
            ORDER BY boundary_id;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
                
            PRINT 'Error removing partition: ' + ERROR_MESSAGE();
            BREAK;
        END CATCH
    END
    
    -- 5. Add new partitions for future dates
    DECLARE @NextDate DATE = DATEADD(MONTH, 1, @NewestBoundary);
    
    WHILE @NextDate <= @FutureDate
    BEGIN
        PRINT 'Adding new partition boundary: ' + CAST(@NextDate AS VARCHAR(20));
        
        BEGIN TRY
            -- Split the range to add a new boundary
            ALTER PARTITION FUNCTION PF_Monthly()
            SPLIT RANGE (@NextDate);
            
            SET @NextDate = DATEADD(MONTH, 1, @NextDate);
            SET @NewestBoundary = @NextDate;
        END TRY
        BEGIN CATCH
            PRINT 'Error adding partition: ' + ERROR_MESSAGE();
            BREAK;
        END CATCH
    END
END;
GO

/*
  Execute the automated partition management procedure.
*/
EXEC Auto_Manage_Partitions @RetentionMonths = 12, @FutureMonths = 6;
GO

-------------------------------------------------
-- Region: 9. Partition-Aligned Table Joins
-------------------------------------------------
/*
  Create another partitioned table with the same partition scheme for efficient joins.
*/
CREATE TABLE Sales_Returns
(
    ReturnID INT IDENTITY(1,1) NOT NULL,
    SaleID INT NOT NULL,
    ReturnDate DATE NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Reason NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_Sales_Returns PRIMARY KEY NONCLUSTERED (ReturnID, ReturnDate)
) ON PS_Monthly(ReturnDate);
GO

/*
  Create a clustered columnstore index for the Returns table.
*/
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Returns
ON Sales_Returns
ON PS_Monthly(ReturnDate);
GO/**************************************************************
 * SQL Server 2022 Advanced Partitioning Tutorial
 * Description: This script demonstrates comprehensive table 
 *              partitioning techniques in SQL Server 2022. It covers:
 *              - Multiple filegroups for partition storage
 *              - Date-based partitioning strategies
 *              - Sliding window partition management
 *              - Partitioned columnstore indexes
 *              - Filtered indexes on partitions
 *              - Partition compression strategies
 *              - Partition alignment for multiple tables
 *              - Dynamic partition management
 *              - Partition-level operations and maintenance
 **************************************************************/

-------------------------------------------------
-- Region: 1. Advanced Database and Storage Setup
-------------------------------------------------
/*
  Create a database with multiple filegroups for partition storage.
  Each filegroup can be placed on different storage devices for performance.
*/
CREATE DATABASE PartitionAdvancedDB
ON PRIMARY 
(
    NAME = PartitionAdvancedDB_Primary,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Primary.mdf',
    SIZE = 100MB
),
FILEGROUP FG_Archive
(
    NAME = PartitionAdvancedDB_Archive,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Archive.ndf',
    SIZE = 100MB
),
FILEGROUP FG_Current
(
    NAME = PartitionAdvancedDB_Current,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Current.ndf',
    SIZE = 100MB
),
FILEGROUP FG_Future
(
    NAME = PartitionAdvancedDB_Future,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Future.ndf',
    SIZE = 100MB
)
LOG ON
(
    NAME = PartitionAdvancedDB_Log,
    FILENAME = 'E:\SQLData\PartitionAdvancedDB_Log.ldf',
    SIZE = 100MB
);
GO

USE PartitionAdvancedDB;
GO

-------------------------------------------------
-- Region: 2. Date-Based Partitioning for Sales Data
-------------------------------------------------
/*
  Create a partition function that partitions data by month.
  This is ideal for time-series data like sales or logs.
*/
CREATE PARTITION FUNCTION PF_Monthly (DATE)
AS RANGE RIGHT FOR VALUES (
    '2022-01-01', '2022-02-01', '2022-03-01', 
    '2022-04-01', '2022-05-01', '2022-06-01',
    '2022-07-01', '2022-08-01', '2022-09-01',
    '2022-10-01', '2022-11-01', '2022-12-01',
    '2023-01-01'
);
GO

/*
  Create a partition scheme that maps different date ranges to different filegroups.
  - Archive data (older than 6 months) goes to the archive filegroup
  - Current data (recent 6 months) goes to the current filegroup
  - Future data (next month) goes to the future filegroup
*/
CREATE PARTITION SCHEME PS_Monthly
AS PARTITION PF_Monthly
TO (
    FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, FG_Archive, -- Jan-Jul 2022 (Archive)
    FG_Current, FG_Current, FG_Current, FG_Current, FG_Current,                         -- Aug-Dec 2022 (Current)
    FG_Future                                                                           -- Jan 2023+ (Future)
);
GO

/*
  Create a partitioned sales fact table with date-based partitioning.
*/
CREATE TABLE Sales_Fact
(
    SaleID INT IDENTITY(1,1) NOT NULL,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    StoreID INT NOT NULL,
    CustomerID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_Sales_Fact PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
) ON PS_Monthly(SaleDate);
GO

/*
  Create dimension tables to support the sales fact table.
*/
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Stores (
    StoreID INT PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    Region NVARCHAR(50) NOT NULL
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    State NVARCHAR(50) NOT NULL
);
GO

/*
  Create indexes with partition alignment to improve query performance.
  The indexes are aligned with the same partition scheme as the table.
*/
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact 
ON Sales_Fact
WITH (DROP_EXISTING = OFF)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Product
ON Sales_Fact(ProductID, SaleDate)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Store
ON Sales_Fact(StoreID, SaleDate)
ON PS_Monthly(SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Sales_Fact_Customer
ON Sales_Fact(CustomerID, SaleDate)
ON PS_Monthly(SaleDate);
GO

-------------------------------------------------
-- Region: 3. Populating Partitioned Tables
-------------------------------------------------
/*
  Insert sample data into dimension tables.
*/
INSERT INTO Products (ProductID, ProductName, Category, Price)
VALUES 
    (1, 'Laptop', 'Electronics', 1200.00),
    (2, 'Smartphone', 'Electronics', 800.00),
    (3, 'Desk Chair', 'Furniture', 250.00),
    (4, 'Coffee Maker', 'Appliances', 65.00),
    (5, 'Headphones', 'Electronics', 120.00);
GO

INSERT INTO Stores (StoreID, StoreName, Region)
VALUES 
    (1, 'Downtown Store', 'East'),
    (2, 'Mall Location', 'West'),
    (3, 'Online Store', 'Online');
GO

INSERT INTO Customers (CustomerID, CustomerName, City, State)
VALUES
    (1, 'Alice Johnson', 'Seattle', 'WA'),
    (2, 'Bob Smith', 'Portland', 'OR'),
    (3, 'Charlie Davis', 'San Francisco', 'CA'),
    (4, 'Diana Miller', 'Chicago', 'IL'),
    (5, 'Edward Wilson', 'New York', 'NY');
GO

/*
  Create a procedure to generate realistic sales data across multiple partitions.
*/
CREATE OR ALTER PROCEDURE Generate_Sales_Data
    @StartDate DATE,
    @EndDate DATE,
    @RowCount INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = @StartDate;
    DECLARE @CurrentCount INT = 0;
    DECLARE @MaxProduct INT = (SELECT MAX(ProductID) FROM Products);
    DECLARE @MaxStore INT = (SELECT MAX(StoreID) FROM Stores);
    DECLARE @MaxCustomer INT = (SELECT MAX(CustomerID) FROM Customers);
    
    WHILE @CurrentDate <= @EndDate AND @CurrentCount < @RowCount
    BEGIN
        DECLARE @BatchSize INT = 1000;
        DECLARE @BatchCount INT = 0;
        
        WHILE @BatchCount < @BatchSize AND @CurrentCount < @RowCount
        BEGIN
            INSERT INTO Sales_Fact (SaleDate, ProductID, StoreID, CustomerID, Quantity, Amount)
            SELECT 
                @CurrentDate,
                ABS(CHECKSUM(NEWID())) % @MaxProduct + 1,
                ABS(CHECKSUM(NEWID())) % @MaxStore + 1,
                ABS(CHECKSUM(NEWID())) % @MaxCustomer + 1,
                ABS(CHECKSUM(NEWID())) % 10 + 1,  -- Quantity between 1 and 10
                CAST(ABS(CHECKSUM(NEWID()) % 100000) / 100.0 + 10.0 AS DECIMAL(10,2))  -- Amount between $10 and $1000
            
            SET @BatchCount = @BatchCount + 1;
            SET @CurrentCount = @CurrentCount + 1;
        END
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END
    
    PRINT 'Generated ' + CAST(@CurrentCount AS VARCHAR(10)) + ' sales records';
END;
GO

/*
  Generate sample sales data for each month in 2022.
*/
EXEC Generate_Sales_Data '2022-01-01', '2022-12-31', 10000;
GO

-------------------------------------------------
-- Region: 4. Partition Information and Maintenance
-------------------------------------------------
/*
  Query to show the partition distribution of the Sales_Fact table.
*/
SELECT 
    p.partition_number AS PartitionNumber,
    fg.name AS FileGroupName,
    p.rows AS RowCount,
    CAST(prv.value AS DATE) AS BoundaryValue,
    CASE
        WHEN p.partition_number = 1 THEN 'First Partition'
        WHEN prv.value IS NULL THEN 'Last Partition'
        ELSE ''
    END AS Notes
FROM sys.partitions p
INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
INNER JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id 
    AND p.partition_number = dds.destination_id
INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
    AND p.partition_number = prv.boundary_id + 1
WHERE i.object_id = OBJECT_ID('Sales_Fact') AND i.index_id = 1
ORDER BY p.partition_number;
GO

/*
  Procedure to rebuild and reorganize indexes for specific partitions.
*/
CREATE OR ALTER PROCEDURE Maintain_Partition_Indexes
    @TableName NVARCHAR(128),
    @PartitionNumber INT,
    @Action NVARCHAR(20) -- REBUILD or REORGANIZE
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @IndexName NVARCHAR(128);
    
    DECLARE index_cursor CURSOR FOR
    SELECT i.name
    FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(@TableName) 
    AND i.index_id > 0; -- Skip heaps
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @IndexName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Action = 'REBUILD'
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                       ' ON ' + QUOTENAME(@TableName) + 
                       ' REBUILD PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10)) + 
                       ' WITH (ONLINE = ON, DATA_COMPRESSION = PAGE)';
        END
        ELSE IF @Action = 'REORGANIZE'
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                       ' ON ' + QUOTENAME(@TableName) + 
                       ' REORGANIZE PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10));
        END
        
        PRINT 'Executing: ' + @SQL;
        EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM index_cursor INTO @IndexName;
    END
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
END;
GO

/*
  Apply index maintenance to specific partitions.
*/
EXEC Maintain_Partition_Indexes 'Sales_Fact', 8, 'REBUILD';  -- Rebuild current month partition
GO

-------------------------------------------------
-- Region: 5. Sliding Window Implementation
-------------------------------------------------
/*
  Create a procedure to implement the sliding window pattern.
  This pattern is commonly used for managing time-series data:
  1. Create a staging table for the new partition
  2. Add a new boundary to the partition function
  3. Switch in the new partition
  4. Switch out the oldest partition to an archive table
  5. Optionally remove the oldest boundary
*/
CREATE OR ALTER PROCEDURE Implement_Sliding_Window
    @NewBoundaryDate DATE,
    @RemoveOldestBoundary BIT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @OldestBoundaryValue DATE;
        
        -- 1. Get the oldest boundary value if we need to remove it
        IF @RemoveOldestBoundary = 1
        BEGIN
            SELECT TOP 1 @OldestBoundaryValue = CAST(prv.value AS DATE)
            FROM sys.partition_range_values prv
            INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
            WHERE pf.name = 'PF_Monthly'
            ORDER BY boundary_id;
        END
        
        -- 2. Create staging table for the next month data
        IF OBJECT_ID('dbo.Sales_Fact_Next', 'U') IS NOT NULL
            DROP TABLE dbo.Sales_Fact_Next;
            
        CREATE TABLE dbo.Sales_Fact_Next
        (
            SaleID INT IDENTITY(1,1) NOT NULL,
            SaleDate DATE NOT NULL,
            ProductID INT NOT NULL,
            StoreID INT NOT NULL,
            CustomerID INT NOT NULL,
            Quantity INT NOT NULL,
            Amount DECIMAL(10, 2) NOT NULL,
            CONSTRAINT PK_Sales_Fact_Next PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
        );
        
        -- 3. Create constraints and indexes identical to the main table
        CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Next 
        ON dbo.Sales_Fact_Next;
        
        -- 4. Split the partition function to add a new boundary
        ALTER PARTITION FUNCTION PF_Monthly() 
        SPLIT RANGE (@NewBoundaryDate);
        
        -- 5. Prepare archive table if needed
        IF @RemoveOldestBoundary = 1
        BEGIN
            IF OBJECT_ID('dbo.Sales_Fact_Archive', 'U') IS NOT NULL
                DROP TABLE dbo.Sales_Fact_Archive;
                
            SELECT *
            INTO dbo.Sales_Fact_Archive
            FROM dbo.Sales_Fact
            WHERE 1 = 0;
            
            -- Add identical constraints and indexes
            ALTER TABLE dbo.Sales_Fact_Archive 
            ADD CONSTRAINT PK_Sales_Fact_Archive PRIMARY KEY NONCLUSTERED (SaleID, SaleDate);
            
            CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Archive 
            ON dbo.Sales_Fact_Archive;
        END
        
        -- 6. Prepare metadata for the newest partition (highest partition number)
        DECLARE @PartitionCount INT;
        SELECT @PartitionCount = COUNT(*) 
        FROM sys.partitions 
        WHERE object_id = OBJECT_ID('Sales_Fact') AND index_id = 1;
        
        -- 7. Add data to the sales_fact_next table (would typically come from ETL)
        INSERT INTO dbo.Sales_Fact_Next (SaleDate, ProductID, StoreID, CustomerID, Quantity, Amount)
        SELECT 
            DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, @NewBoundaryDate),  -- Random day in the month
            ABS(CHECKSUM(NEWID())) % 5 + 1,  -- ProductID
            ABS(CHECKSUM(NEWID())) % 3 + 1,  -- StoreID
            ABS(CHECKSUM(NEWID())) % 5 + 1,  -- CustomerID
            ABS(CHECKSUM(NEWID())) % 10 + 1,  -- Quantity
            CAST(ABS(CHECKSUM(NEWID()) % 100000) / 100.0 + 10.0 AS DECIMAL(10,2))  -- Amount
        FROM sys.all_objects 
        CROSS JOIN (SELECT TOP 10 n = ROW_NUMBER() OVER (ORDER BY [object_id]) FROM sys.all_objects) AS nums
        WHERE [type] IN ('U', 'V')
        AND DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, @NewBoundaryDate) < DATEADD(MONTH, 1, @NewBoundaryDate);
        
        -- 8. Switch in the new partition
        ALTER TABLE dbo.Sales_Fact_Next
        SWITCH TO dbo.Sales_Fact PARTITION @PartitionCount;
        
        -- 9. If requested, switch out the oldest partition to the archive table
        IF @RemoveOldestBoundary = 1
        BEGIN
            ALTER TABLE dbo.Sales_Fact
            SWITCH PARTITION 1 TO dbo.Sales_Fact_Archive;
            
            -- 10. Merge the oldest boundary to remove it
            ALTER PARTITION FUNCTION PF_Monthly()
            MERGE RANGE (@OldestBoundaryValue);
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Sliding window operation completed successfully.';
        PRINT 'New boundary added: ' + CAST(@NewBoundaryDate AS NVARCHAR(20));
        IF @RemoveOldestBoundary = 1
            PRINT 'Oldest boundary removed: ' + CAST(@OldestBoundaryValue AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

/*
  Execute the sliding window procedure to add a new month.
*/
EXEC Implement_Sliding_Window '2023-02-01', 0;  -- Add February 2023, don't remove oldest
GO

EXEC Implement_Sliding_Window '2023-03-01', 1;  -- Add March 2023, remove January 2022
GO

-------------------------------------------------
-- Region: 6. Advanced Partition-Level Operations
-------------------------------------------------
/*
  Implement partition-level compression strategies based on data age.
*/
CREATE OR ALTER PROCEDURE Apply_Partition_Compression_Strategy
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PartitionNumber INT = 1;
    DECLARE @MaxPartition INT;
    
    -- Get the maximum partition number
    SELECT @MaxPartition = COUNT(*) 
    FROM sys.partitions 
    WHERE object_id = OBJECT_ID('Sales_Fact') AND index_id = 1;
    
    -- Apply compression strategies based on partition position
    WHILE @PartitionNumber <= @MaxPartition
    BEGIN
        -- Archive partitions (older): Use PAGE compression for best storage efficiency
        IF @PartitionNumber <= @MaxPartition - 6
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = PAGE)';
        END
        -- Current partitions (middle): Use ROW compression for balance
        ELSE IF @PartitionNumber <= @MaxPartition - 1
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = ROW)';
        END
        -- Latest partition: No compression for best insert performance
        ELSE
        BEGIN
            SET @SQL = 'ALTER INDEX ALL ON Sales_Fact REBUILD PARTITION = ' + 
                      CAST(@PartitionNumber AS NVARCHAR(10)) + 
                      ' WITH (DATA_COMPRESSION = NONE)';
        END
        
        PRINT 'Applying compression to partition ' + CAST(@PartitionNumber AS NVARCHAR(10)) + ':';
        PRINT @SQL;
        EXEC sp_executesql @SQL;
        
        SET @PartitionNumber = @PartitionNumber + 1;
    END
END;
GO

/*
  Apply the compression strategy.
*/
EXEC Apply_Partition_Compression_Strategy;
GO

/*
  Create filtered indexes on specific partitions for specialized queries.
  This is achieved by combining partition scheme with WHERE predicates.
*/
CREATE NONCLUSTERED INDEX IX_Sales_Fact_HighValue
ON Sales_Fact (ProductID, Amount)
INCLUDE (SaleDate, CustomerID)
WHERE Amount > 500.00
ON PS_Monthly(SaleDate);
GO

-------------------------------------------------
-- Region: 7. Monitoring and Diagnostics
-------------------------------------------------
/*
  Create a view to monitor partition usage statistics.
*/
CREATE OR ALTER VIEW vw_Partition_Statistics
AS
WITH PartitionStats AS (
    SELECT 
        OBJECT_NAME(p.object_id) AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        p.partition_number,
        fg.name AS FileGroupName,
        CAST(prv.value AS DATE) AS BoundaryPoint,
        p.rows AS RowCount,
        SUM(a.total_pages) * 8 / 1024.0 AS TotalSizeMB,
        SUM(a.used_pages) * 8 / 1024.0 AS UsedSizeMB,
        SUM(a.data_pages) * 8 / 1024.0 AS DataSizeMB,
        (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024.0 AS UnusedSizeMB,
        CASE 
            WHEN p.data_compression = 0 THEN 'NONE'
            WHEN p.data_compression = 1 THEN 'ROW'
            WHEN p.data_compression = 2 THEN 'PAGE'
            WHEN p.data_compression = 3 THEN 'COLUMNSTORE'
            WHEN p.data_compression = 4 THEN 'COLUMNSTORE_ARCHIVE'
            ELSE 'UNKNOWN'
        END AS CompressionType
    FROM sys.partitions p
    INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
    INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
    INNER JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id 
        AND p.partition_number = dds.destination_id
    INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
        AND p.partition_number = prv.boundary_id + 1
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    WHERE i.object_id = OBJECT_ID('Sales_Fact')
    GROUP BY 
        OBJECT_NAME(p.object_id),
        i.name,
        i.type_desc,
        p.partition_number,
        fg.name,
        prv.value,
        p.rows,
        p.data_compression
)
SELECT * FROM PartitionStats;
GO

/*
  Query the view to see partition statistics.
*/
SELECT * FROM vw_Partition_Statistics ORDER BY partition_number;
GO

-------------------------------------------------
-- Region: 8. Dynamic Partition Management
-------------------------------------------------
/*
  Create a procedure for automated partition management based on date ranges.
  This is useful for long-term maintenance of time-partitioned tables.
*/
CREATE OR ALTER PROCEDURE Auto_Manage_Partitions
    @RetentionMonths INT = 24,  -- How many months of history to keep
    @FutureMonths INT = 3       -- How many months ahead to pre-allocate
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = GETDATE();
    DECLARE @OldestToKeep DATE = DATEADD(MONTH, -@RetentionMonths, @CurrentDate);
    DECLARE @FutureDate DATE = DATEADD(MONTH, @FutureMonths, @CurrentDate);
    
    -- 1. First day of current month
    DECLARE @CurrentMonth DATE = DATEFROMPARTS(YEAR(@CurrentDate), MONTH(@CurrentDate), 1);
    
    -- 2. Get the oldest boundary in the partition function
    DECLARE @OldestBoundary DATE;
    SELECT TOP 1 @OldestBoundary = CAST(prv.value AS DATE)
    FROM sys.partition_range_values prv
    INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
    WHERE pf.name = 'PF_Monthly'
    ORDER BY boundary_id;
    
    -- 3. Get the newest boundary in the partition function
    DECLARE @NewestBoundary DATE;
    SELECT TOP 1 @NewestBoundary = CAST(prv.value AS DATE)
    FROM sys.partition_range_values prv
    INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
    WHERE pf.name = 'PF_Monthly'
    ORDER BY boundary_id DESC;
    
    PRINT 'Current date: ' + CAST(@CurrentDate AS VARCHAR(20));
    PRINT 'Oldest boundary: ' + CAST(@OldestBoundary AS VARCHAR(20));
    PRINT 'Newest boundary: ' + CAST(@NewestBoundary AS VARCHAR(20));
    PRINT 'Retention threshold: ' + CAST(@OldestToKeep AS VARCHAR(20));
    PRINT 'Future threshold: ' + CAST(@FutureDate AS VARCHAR(20));
    
    -- 4. Remove partitions older than retention period
    WHILE @OldestBoundary < @OldestToKeep
    BEGIN
        PRINT 'Removing old partition boundary: ' + CAST(@OldestBoundary AS VARCHAR(20));
        
        -- Create archive table if it doesn't exist
        IF OBJECT_ID('dbo.Sales_Fact_Archive', 'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Sales_Fact_Archive
            (
                SaleID INT NOT NULL,
                SaleDate DATE NOT NULL,
                ProductID INT NOT NULL,
                StoreID INT NOT NULL,
                CustomerID INT NOT NULL,
                Quantity INT NOT NULL,
                Amount DECIMAL(10, 2) NOT NULL,
                CONSTRAINT PK_Sales_Fact_Archive PRIMARY KEY NONCLUSTERED (SaleID, SaleDate)
            );
            
            CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Fact_Archive 
            ON dbo.Sales_Fact_Archive;
        END
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Switch out oldest partition to archive
            ALTER TABLE dbo.Sales_Fact
            SWITCH PARTITION 1 TO dbo.Sales_Fact_Archive;
            
            -- Merge the range to remove the boundary
            ALTER PARTITION FUNCTION PF_Monthly()
            MERGE RANGE (@OldestBoundary);
            
            COMMIT TRANSACTION;
            
            -- Get the new oldest boundary
            SELECT TOP 1 @OldestBoundary = CAST(prv.value AS DATE)
            FROM sys.partition_range_values prv
            INNER JOIN sys.partition_functions pf ON prv.function_id = pf.function_id
            WHERE pf.name = 'PF_Monthly'
            ORDER BY boundary_id;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
                
            PRINT 'Error removing partition: ' + ERROR_MESSAGE();
            BREAK;
        END CATCH
    END
    
    -- 5. Add new partitions for future dates
    DECLARE @NextDate DATE = DATEADD(MONTH, 1, @NewestBoundary);
    
    WHILE @NextDate <= @FutureDate
    BEGIN
        PRINT 'Adding new partition boundary: ' + CAST(@NextDate AS VARCHAR(20));
        
        BEGIN TRY
            -- Split the range to add a new boundary
            ALTER PARTITION FUNCTION PF_Monthly()
            SPLIT RANGE (@NextDate);
            
            SET @NextDate = DATEADD(MONTH, 1, @NextDate);
            SET @NewestBoundary = @NextDate;
        END TRY
        BEGIN CATCH
            PRINT 'Error adding partition: ' + ERROR_MESSAGE();
            BREAK;
        END CATCH
    END
END;
GO

/*
  Execute the automated partition management procedure.
*/
EXEC Auto_Manage_Partitions @RetentionMonths = 12, @FutureMonths = 6;
GO

-------------------------------------------------
-- Region: 9. Partition-Aligned Table Joins
-------------------------------------------------
/*
  Create another partitioned table with the same partition scheme for efficient joins.
*/
CREATE TABLE Sales_Returns
(
    ReturnID INT IDENTITY(1,1) NOT NULL,
    SaleID INT NOT NULL,
    ReturnDate DATE NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Reason NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_Sales_Returns PRIMARY KEY NONCLUSTERED (ReturnID, ReturnDate)
) ON PS_Monthly(ReturnDate);
GO

/*
  Create a clustered columnstore index for the Returns table.
*/
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales_Returns
ON Sales_Returns
ON PS_Monthly(ReturnDate);
GO