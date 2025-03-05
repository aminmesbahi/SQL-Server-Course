/**************************************************************
 * SQL Server 2022 In-Memory OLTP Tutorial
 * Description: This script demonstrates how to work with In-Memory OLTP
 *              features in SQL Server 2022. It covers:
 *              - Creating a database with memory-optimized filegroup
 *              - Creating memory-optimized tables with different durability options
 *              - Working with hash and nonclustered indexes
 *              - Creating natively compiled stored procedures
 *              - Performance comparisons between disk-based and memory-optimized tables
 *              - Transaction processing in memory-optimized tables
 *              - Monitoring and troubleshooting memory-optimized objects
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database Setup with Memory-Optimized Filegroup
-------------------------------------------------
USE master;
GO

/*
  Drop the database if it exists for clean testing.
*/
IF DB_ID('InMemoryDemo') IS NOT NULL
BEGIN
    ALTER DATABASE InMemoryDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE InMemoryDemo;
END
GO

/*
  Create a new database with a memory-optimized filegroup.
  The MEMORY_OPTIMIZED_DATA filegroup is required for In-Memory OLTP.
*/
CREATE DATABASE InMemoryDemo
ON PRIMARY 
(
    NAME = InMemoryDemo_Data,
    FILENAME = 'E:\SQLData\InMemoryDemo_Data.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
),
FILEGROUP InMemoryDemo_FG CONTAINS MEMORY_OPTIMIZED_DATA
(
    NAME = InMemoryDemo_InMemoryData,
    FILENAME = 'E:\SQLData\InMemoryDemo_InMemoryData'
)
LOG ON
(
    NAME = InMemoryDemo_Log,
    FILENAME = 'E:\SQLData\InMemoryDemo_Log.ldf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
);
GO

USE InMemoryDemo;
GO

-------------------------------------------------
-- Region: 2. Creating Memory-Optimized Tables
-------------------------------------------------
/*
  Create a memory-optimized table with SCHEMA_AND_DATA durability.
  This table persists both schema and data to disk, surviving server restarts.
*/
CREATE TABLE dbo.Customers
(
    CustomerID INT IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    CreditLimit DECIMAL(10, 2) NOT NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    INDEX ix_Customers_Email HASH (Email) WITH (BUCKET_COUNT = 131072)
)
WITH 
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = SCHEMA_AND_DATA
);
GO

/*
  Create a schema-only memory-optimized table.
  This table's schema persists, but data is lost on server restart.
  Useful for temporary data, staging, or caching scenarios.
*/
CREATE TABLE dbo.SessionData
(
    SessionID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY NONCLUSTERED,
    UserID INT NOT NULL,
    SessionData NVARCHAR(MAX) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    LastAccessedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    INDEX ix_SessionData_UserID HASH (UserID) WITH (BUCKET_COUNT = 16384)
)
WITH 
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = SCHEMA_ONLY
);
GO

/*
  Create a memory-optimized table with a nonclustered index.
  Nonclustered indexes are useful when the key has many duplicates,
  ranges are needed, or when you need ordered scans.
*/
CREATE TABLE dbo.Orders
(
    OrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    TotalAmount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    INDEX ix_Orders_CustomerID NONCLUSTERED (CustomerID),
    INDEX ix_Orders_OrderDate NONCLUSTERED (OrderDate)
)
WITH 
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = SCHEMA_AND_DATA
);
GO

/*
  Create a corresponding disk-based table for performance comparison.
*/
CREATE TABLE dbo.Orders_DiskBased
(
    OrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    TotalAmount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    INDEX ix_Orders_DiskBased_CustomerID (CustomerID),
    INDEX ix_Orders_DiskBased_OrderDate (OrderDate)
);
GO

-------------------------------------------------
-- Region: 3. Natively Compiled Stored Procedures
-------------------------------------------------
/*
  Create a natively compiled stored procedure.
  These procedures are compiled to native code and offer significant performance benefits.
*/
CREATE PROCEDURE dbo.usp_InsertCustomer
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @CreditLimit DECIMAL(10, 2)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    INSERT INTO dbo.Customers (FirstName, LastName, Email, CreditLimit)
    VALUES (@FirstName, @LastName, @Email, @CreditLimit);
END;
GO

/*
  Create a natively compiled stored procedure for retrieving customer details.
*/
CREATE PROCEDURE dbo.usp_GetCustomerByEmail
    @Email NVARCHAR(100)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    SELECT CustomerID, FirstName, LastName, Email, CreditLimit, ModifiedDate
    FROM dbo.Customers
    WHERE Email = @Email;
END;
GO

/*
  Create a natively compiled stored procedure for order processing.
*/
CREATE PROCEDURE dbo.usp_CreateOrder
    @CustomerID INT,
    @TotalAmount DECIMAL(10, 2),
    @OrderID INT OUTPUT
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    INSERT INTO dbo.Orders (CustomerID, TotalAmount, Status)
    VALUES (@CustomerID, @TotalAmount, N'Pending');
    
    SET @OrderID = SCOPE_IDENTITY();
END;
GO

-------------------------------------------------
-- Region: 4. Populating Data and Performance Testing
-------------------------------------------------
/*
  Insert sample data into the Customers table using the natively compiled procedure.
*/
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    EXEC dbo.usp_InsertCustomer 
        @FirstName = CONCAT('FirstName', @i), 
        @LastName = CONCAT('LastName', @i),
        @Email = CONCAT('user', @i, '@example.com'),
        @CreditLimit = 1000.00 + (@i % 10) * 1000;
    SET @i = @i + 1;
END;
GO

/*
  Performance comparison: Insert data into memory-optimized vs. disk-based tables.
*/
SET NOCOUNT ON;

DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @ElapsedMs DECIMAL(10, 2);
DECLARE @i INT;
DECLARE @OrderID INT;

-- Test memory-optimized table with natively compiled stored procedure
SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 10000
BEGIN
    EXEC dbo.usp_CreateOrder 
        @CustomerID = (@i % 1000) + 1, 
        @TotalAmount = 100.00 + (@i % 100),
        @OrderID = @OrderID OUTPUT;
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Memory-Optimized Table Insert: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';

-- Test disk-based table with regular insert
SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 10000
BEGIN
    INSERT INTO dbo.Orders_DiskBased (CustomerID, TotalAmount, Status)
    VALUES ((@i % 1000) + 1, 100.00 + (@i % 100), N'Pending');
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Disk-Based Table Insert: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';
GO

/*
  Performance comparison: Query from memory-optimized vs. disk-based tables.
*/
SET NOCOUNT ON;

DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @ElapsedMs DECIMAL(10, 2);
DECLARE @i INT;
DECLARE @CustomerID INT;
DECLARE @Result TABLE (OrderID INT, OrderDate DATETIME2, TotalAmount DECIMAL(10, 2));

-- Test memory-optimized table query
SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 100
BEGIN
    SET @CustomerID = (@i % 1000) + 1;
    
    INSERT INTO @Result (OrderID, OrderDate, TotalAmount)
    SELECT TOP 10 OrderID, OrderDate, TotalAmount 
    FROM dbo.Orders
    WHERE CustomerID = @CustomerID;

    DELETE FROM @Result;
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Memory-Optimized Table Query: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';

-- Test disk-based table query
SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 100
BEGIN
    SET @CustomerID = (@i % 1000) + 1;
    
    INSERT INTO @Result (OrderID, OrderDate, TotalAmount)
    SELECT TOP 10 OrderID, OrderDate, TotalAmount 
    FROM dbo.Orders_DiskBased
    WHERE CustomerID = @CustomerID;

    DELETE FROM @Result;
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Disk-Based Table Query: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';
GO

-------------------------------------------------
-- Region: 5. Transaction Processing in Memory-Optimized Tables
-------------------------------------------------
/*
  Demonstrate transaction processing in memory-optimized tables.
  Memory-optimized tables support ACID transactions with optimistic concurrency control.
*/
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Update a customer's credit limit
    UPDATE dbo.Customers
    SET CreditLimit = CreditLimit + 5000.00,
        ModifiedDate = SYSUTCDATETIME()
    WHERE CustomerID = 1;
    
    -- Create a new order for the customer
    DECLARE @OrderID INT;
    EXEC dbo.usp_CreateOrder 
        @CustomerID = 1, 
        @TotalAmount = 4500.00,
        @OrderID = @OrderID OUTPUT;
    
    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully. New OrderID: ' + CAST(@OrderID AS NVARCHAR(10));
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Transaction failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-------------------------------------------------
-- Region: 6. Hash Index vs. Nonclustered Index
-------------------------------------------------
/*
  Demonstrate when to use HASH vs. NONCLUSTERED indexes in memory-optimized tables.
*/
-- Hash index is ideal for equality predicates (=)
DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @ElapsedMs DECIMAL(10, 2);
DECLARE @Email NVARCHAR(100);
DECLARE @i INT = 1;

SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 1000
BEGIN
    SET @Email = CONCAT('user', (@i % 1000) + 1, '@example.com');
    
    -- Using hash index for equality search
    SELECT CustomerID 
    FROM dbo.Customers
    WHERE Email = @Email;
    
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Hash Index (Email) Performance: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';

-- Nonclustered index is ideal for range predicates, ordering, and inequality
SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 100
BEGIN
    -- Using nonclustered index for range search
    SELECT TOP 10 OrderID, OrderDate
    FROM dbo.Orders
    WHERE OrderDate BETWEEN DATEADD(DAY, -1, SYSUTCDATETIME()) AND SYSUTCDATETIME()
    ORDER BY OrderDate DESC;
    
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Nonclustered Index (OrderDate) Performance: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';
GO

-------------------------------------------------
-- Region: 7. Monitoring Memory-Optimized Objects
-------------------------------------------------
/*
  Query DMVs to monitor memory usage and performance of memory-optimized objects.
*/
-- Get information about memory-optimized tables
SELECT 
    object_name(object_id) AS table_name, 
    memory_allocated_for_table_kb,
    memory_used_by_table_kb,
    memory_allocated_for_indexes_kb,
    memory_used_by_indexes_kb,
    rows_count
FROM sys.dm_db_xtp_table_memory_stats
WHERE object_id > 0;
GO

-- Get information about hash indexes and their efficiency
SELECT 
    OBJECT_NAME(hs.object_id) AS table_name,
    i.name AS index_name,
    hs.total_bucket_count,
    hs.empty_bucket_count,
    hs.empty_bucket_count * 100.0 / hs.total_bucket_count AS empty_bucket_percent,
    hs.avg_chain_length,
    hs.max_chain_length
FROM sys.dm_db_xtp_hash_index_stats AS hs
JOIN sys.indexes AS i ON hs.object_id = i.object_id AND hs.index_id = i.index_id;
GO

-- Get information about natively compiled stored procedures
SELECT 
    OBJECT_NAME(object_id) AS procedure_name,
    cached_time,
    last_execution_time,
    execution_count,
    total_worker_time / execution_count AS avg_cpu_time_microsec,
    total_elapsed_time / execution_count AS avg_elapsed_time_microsec
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID() 
AND object_id IN (SELECT object_id FROM sys.sql_modules WHERE uses_native_compilation = 1);
GO

-------------------------------------------------
-- Region: 8. Memory-Optimized Table Variables
-------------------------------------------------
/*
  Demonstrate memory-optimized table variables for improved performance.
*/
-- Create a regular table variable
DECLARE @RegularTableVar TABLE
(
    ID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL
);

-- Create a memory-optimized table type
CREATE TYPE dbo.MemoryOptimizedTableType AS TABLE
(
    ID INT NOT NULL PRIMARY KEY NONCLUSTERED,
    Name NVARCHAR(50) NOT NULL,
    INDEX ix_Name HASH(Name) WITH (BUCKET_COUNT = 8192)
)
WITH (MEMORY_OPTIMIZED = ON);
GO

-- Use memory-optimized table variable
DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @ElapsedMs DECIMAL(10, 2);
DECLARE @i INT;

-- Test regular table variable
DECLARE @RegularTableVar TABLE
(
    ID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL
);

SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 10000
BEGIN
    INSERT INTO @RegularTableVar (ID, Name)
    VALUES (@i, CONCAT('Name', @i));
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Regular Table Variable Insert: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';

-- Test memory-optimized table variable
DECLARE @MemoryOptimizedTableVar dbo.MemoryOptimizedTableType;

SET @i = 1;
SET @StartTime = SYSUTCDATETIME();

WHILE @i <= 10000
BEGIN
    INSERT INTO @MemoryOptimizedTableVar (ID, Name)
    VALUES (@i, CONCAT('Name', @i));
    SET @i = @i + 1;
END;

SET @EndTime = SYSUTCDATETIME();
SET @ElapsedMs = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Memory-Optimized Table Variable Insert: ' + CAST(@ElapsedMs AS NVARCHAR(20)) + ' ms';
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
-- DROP DATABASE InMemoryDemo;
-- GO