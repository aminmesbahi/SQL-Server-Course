/**************************************************************
 * SQL Server 2022 BULK INSERT and Batch Operations Tutorial
 * Description: This script demonstrates how to use BULK INSERT and
 *              batch operations in SQL Server 2022. It covers:
 *              - Using BULK INSERT to load data from various file formats
 *              - Working with BCP utility for import/export
 *              - Table-valued parameters for batch operations
 *              - Implementing error handling for bulk operations
 *              - Optimizing performance for large data loads
 *              - Transaction management in batch operations
 *              - Using SQL Server Integration Services (SSIS) basics
 *              - Monitoring bulk operations and performance tuning
 **************************************************************/

-------------------------------------------------
-- Region: 1. Understanding BULK INSERT Basics
-------------------------------------------------
USE master;
GO

/*
  Create a test database for our examples.
*/
IF DB_ID('BulkOperationsDemo') IS NOT NULL
BEGIN
    ALTER DATABASE BulkOperationsDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BulkOperationsDemo;
END
GO

CREATE DATABASE BulkOperationsDemo;
GO

USE BulkOperationsDemo;
GO

/*
  The BULK INSERT statement allows for loading data from external files directly
  into SQL Server tables. It's optimized for performance and can handle
  large volumes of data more efficiently than row-by-row inserts.
*/

-- Create a sample table that we will use for demonstration
CREATE TABLE dbo.Products
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    InStock BIT NOT NULL,
    LastUpdated DATETIME2 DEFAULT GETDATE()
);
GO

-- Create a directory for our data files using xp_cmdshell
-- Note: xp_cmdshell requires appropriate permissions
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- Create a sample CSV file in temp directory
EXEC xp_cmdshell 'mkdir C:\Temp';
GO

DECLARE @csv_content NVARCHAR(MAX) = 
'ProductID,ProductName,Category,Price,InStock
1,Laptop,Electronics,1200.00,1
2,Smartphone,Electronics,800.00,1
3,Desk Chair,Furniture,250.00,1
4,Coffee Maker,Appliances,65.00,0
5,Headphones,Electronics,120.00,1';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @csv_content + ' > C:\Temp\products.csv';
EXEC xp_cmdshell @cmd;
GO

-------------------------------------------------
-- Region: 2. Basic BULK INSERT Operations
-------------------------------------------------
/*
  Basic BULK INSERT with minimal options.
*/
TRUNCATE TABLE dbo.Products;
GO

-- Simple BULK INSERT from CSV file
BULK INSERT dbo.Products
FROM 'C:\Temp\products.csv'
WITH (
    FIRSTROW = 2,             -- Skip header row
    FIELDTERMINATOR = ',',    -- CSV field delimiter
    ROWTERMINATOR = '\n',     -- Row terminator
    KEEPNULLS                 -- Preserve NULL values
);
GO

-- Verify the data was loaded correctly
SELECT * FROM dbo.Products;
GO

/*
  Using more advanced options with BULK INSERT.
*/
-- Create a sample table for order data
CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(20) NOT NULL
);
GO

-- Create a sample tab-delimited file
DECLARE @orders_content NVARCHAR(MAX) = 
'OrderID	CustomerID	OrderDate	TotalAmount	Status
1001	101	2023-01-15	520.75	Completed
1002	102	2023-01-17	340.50	Processing
1003	101	2023-01-20	1250.00	Completed
1004	103	2023-01-25	89.99	Shipped
1005	104	2023-01-30	450.25	Processing';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @orders_content + ' > C:\Temp\orders.tsv';
EXEC xp_cmdshell @cmd;
GO

-- BULK INSERT with additional options
BULK INSERT dbo.Orders
FROM 'C:\Temp\orders.tsv'
WITH (
    FIRSTROW = 2,                -- Skip header row
    FIELDTERMINATOR = '\t',      -- Tab delimiter
    ROWTERMINATOR = '\n',        -- Row terminator
    TABLOCK,                     -- Table lock for better performance
    CHECK_CONSTRAINTS,           -- Validate constraints during import
    FIRE_TRIGGERS                -- Fire any triggers during import
);
GO

-- Verify the order data was loaded correctly
SELECT * FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: 3. Working with Different File Formats
-------------------------------------------------
/*
  BULK INSERT supports various file formats including CSV, TSV,
  fixed-width, and even XML/JSON through format files.
*/

-- Create a table for fixed-width data
CREATE TABLE dbo.Employees
(
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL
);
GO

-- Create a fixed-width format file
DECLARE @format_content NVARCHAR(MAX) = 
'<?xml version="1.0"?>
<BCPFORMAT xmlns="http://schemas.microsoft.com/sqlserver/2004/bulkload/format" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <RECORD>
    <FIELD ID="1" xsi:type="CharFixed" LENGTH="5"/>
    <FIELD ID="2" xsi:type="CharFixed" LENGTH="15"/>
    <FIELD ID="3" xsi:type="CharFixed" LENGTH="15"/>
    <FIELD ID="4" xsi:type="CharFixed" LENGTH="20"/>
    <FIELD ID="5" xsi:type="CharFixed" LENGTH="10"/>
  </RECORD>
  <ROW>
    <COLUMN SOURCE="1" NAME="EmployeeID" xsi:type="SQLINT"/>
    <COLUMN SOURCE="2" NAME="FirstName" xsi:type="SQLNVARCHAR"/>
    <COLUMN SOURCE="3" NAME="LastName" xsi:type="SQLNVARCHAR"/>
    <COLUMN SOURCE="4" NAME="Department" xsi:type="SQLNVARCHAR"/>
    <COLUMN SOURCE="5" NAME="Salary" xsi:type="SQLDECIMAL" PRECISION="10" SCALE="2"/>
  </ROW>
</BCPFORMAT>';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + REPLACE(@format_content, CHAR(10), '') + ' > C:\Temp\employees.fmt';
EXEC xp_cmdshell @cmd;
GO

-- Create a fixed-width data file
DECLARE @fixed_content NVARCHAR(MAX) = 
'10001John       Smith      IT                  75000.00
10002Mary       Jones      Marketing           82500.50
10003Robert     Johnson    Sales              65000.00
10004Sarah      Williams   HR                 70000.00
10005Michael    Brown      IT                  92000.00';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @fixed_content + ' > C:\Temp\employees.dat';
EXEC xp_cmdshell @cmd;
GO

-- BULK INSERT using format file for fixed-width data
BULK INSERT dbo.Employees
FROM 'C:\Temp\employees.dat'
WITH (
    FORMATFILE = 'C:\Temp\employees.fmt',
    TABLOCK
);
GO

-- Verify the employee data was loaded correctly
SELECT * FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 4. Error Handling in Bulk Operations
-------------------------------------------------
/*
  Handle errors that might occur during bulk operations.
*/

-- Create a table with constraints for error demonstration
CREATE TABLE dbo.Customers
(
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    CreditLimit DECIMAL(10, 2) NOT NULL CHECK (CreditLimit >= 0),
    IsActive BIT NOT NULL
);
GO

-- Create a CSV file with some invalid data
DECLARE @customers_content NVARCHAR(MAX) = 
'CustomerID,CustomerName,Email,CreditLimit,IsActive
201,John Doe,john.doe@example.com,5000.00,1
202,Jane Smith,jane.smith@example.com,3000.00,1
203,Invalid Customer,invalid-email,-500.00,1
204,Duplicate Email,john.doe@example.com,2000.00,0
205,Robert Johnson,robert.johnson@example.com,4000.00,1';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @customers_content + ' > C:\Temp\customers.csv';
EXEC xp_cmdshell @cmd;
GO

-- BULK INSERT with error handling options
-- This will fail constraints but we can capture errors
BULK INSERT dbo.Customers
FROM 'C:\Temp\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    MAXERRORS = 2,            -- Allow up to 2 errors before failing
    ERRORFILE = 'C:\Temp\customers_errors.log' -- Log errors to a file
);
GO

-- Alternative approach: Use a staging table without constraints
CREATE TABLE dbo.CustomersStaging
(
    CustomerID INT,
    CustomerName NVARCHAR(100),
    Email NVARCHAR(100),
    CreditLimit DECIMAL(10, 2),
    IsActive BIT
);
GO

-- Bulk insert into staging table first
BULK INSERT dbo.CustomersStaging
FROM 'C:\Temp\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
GO

-- Validate and insert valid records into main table
INSERT INTO dbo.Customers
SELECT s.CustomerID, s.CustomerName, s.Email, s.CreditLimit, s.IsActive
FROM dbo.CustomersStaging s
WHERE s.CreditLimit >= 0
  AND NOT EXISTS (SELECT 1 FROM dbo.Customers c WHERE c.Email = s.Email);
GO

-- List records that were rejected
SELECT * FROM dbo.CustomersStaging s
WHERE s.CreditLimit < 0
   OR EXISTS (SELECT 1 FROM dbo.Customers c WHERE c.Email = s.Email);
GO

-------------------------------------------------
-- Region: 5. Transaction Management for Bulk Operations
-------------------------------------------------
/*
  Managing transactions for bulk operations ensures data integrity.
*/

-- Create a transaction log table
CREATE TABLE dbo.ImportLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ImportType NVARCHAR(50) NOT NULL,
    FileName NVARCHAR(255) NOT NULL,
    RecordsImported INT NOT NULL,
    ImportDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL
);
GO

-- Create a sample CSV file for inventory updates
DECLARE @inventory_content NVARCHAR(MAX) = 
'ProductID,QuantityChange,UpdateType,UpdateDate
1,50,Restock,2023-03-01
2,-15,Sale,2023-03-01
3,30,Restock,2023-03-02
4,100,Restock,2023-03-02
5,-10,Sale,2023-03-02';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @inventory_content + ' > C:\Temp\inventory_updates.csv';
EXEC xp_cmdshell @cmd;
GO

-- Create an inventory table
CREATE TABLE dbo.Inventory
(
    ProductID INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL DEFAULT 0,
    LastUpdated DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID)
);
GO

-- Initialize inventory
INSERT INTO dbo.Inventory (ProductID, QuantityOnHand)
SELECT ProductID, CASE WHEN InStock = 1 THEN 100 ELSE 0 END
FROM dbo.Products;
GO

-- Create a staging table for inventory updates
CREATE TABLE dbo.InventoryUpdatesStaging
(
    ProductID INT,
    QuantityChange INT,
    UpdateType NVARCHAR(50),
    UpdateDate DATE
);
GO

-- Import data and apply updates within a transaction
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Import data to staging
    BULK INSERT dbo.InventoryUpdatesStaging
    FROM 'C:\Temp\inventory_updates.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    
    -- Count records imported
    DECLARE @RecordsImported INT = @@ROWCOUNT;
    
    -- Apply updates to inventory
    UPDATE i
    SET i.QuantityOnHand = i.QuantityOnHand + s.QuantityChange,
        i.LastUpdated = GETDATE()
    FROM dbo.Inventory i
    JOIN dbo.InventoryUpdatesStaging s ON i.ProductID = s.ProductID;
    
    -- Check for negative inventory (business rule)
    IF EXISTS (SELECT 1 FROM dbo.Inventory WHERE QuantityOnHand < 0)
    BEGIN
        RAISERROR('Inventory cannot be negative. Rolling back transaction.', 16, 1);
    END
    
    -- Log successful import
    INSERT INTO dbo.ImportLog (ImportType, FileName, RecordsImported, Status)
    VALUES ('Inventory Update', 'inventory_updates.csv', @RecordsImported, 'Success');
    
    -- If everything succeeded, commit the transaction
    COMMIT TRANSACTION;
    
    PRINT 'Inventory updates applied successfully.';
END TRY
BEGIN CATCH
    -- If an error occurred, roll back the transaction
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    -- Log the error
    INSERT INTO dbo.ImportLog (ImportType, FileName, RecordsImported, Status)
    VALUES ('Inventory Update', 'inventory_updates.csv', 0, 'Failed: ' + ERROR_MESSAGE());
    
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Verify the inventory updates
SELECT p.ProductID, p.ProductName, i.QuantityOnHand, i.LastUpdated
FROM dbo.Products p
JOIN dbo.Inventory i ON p.ProductID = i.ProductID;
GO

-------------------------------------------------
-- Region: 6. Working with BCP Utility
-------------------------------------------------
/*
  BCP (Bulk Copy Program) is a command-line utility that bulk copies data
  between a SQL Server instance and a data file in a specified format.
*/

-- Create a stored procedure to generate BCP commands
CREATE OR ALTER PROCEDURE dbo.GenerateBCPCommands
    @TableName NVARCHAR(128),
    @SchemaName NVARCHAR(128) = 'dbo',
    @FilePath NVARCHAR(256),
    @FormatFile NVARCHAR(256) = NULL,
    @Options NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @BCPExport NVARCHAR(MAX);
    DECLARE @BCPImport NVARCHAR(MAX);
    DECLARE @FullTableName NVARCHAR(256) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME();
    
    -- Generate export command
    SET @BCPExport = 'bcp ' + @FullTableName + ' out ' + @FilePath + 
                     ' -S "' + @@SERVERNAME + '" -d ' + @DatabaseName + ' -T';
                     
    -- Add format file option if provided
    IF @FormatFile IS NOT NULL
        SET @BCPExport = @BCPExport + ' -f "' + @FormatFile + '"';
    
    -- Add any other options
    IF @Options IS NOT NULL
        SET @BCPExport = @BCPExport + ' ' + @Options;
    
    -- Generate import command
    SET @BCPImport = 'bcp ' + @FullTableName + ' in ' + @FilePath + 
                     ' -S "' + @@SERVERNAME + '" -d ' + @DatabaseName + ' -T';
                     
    -- Add format file option if provided
    IF @FormatFile IS NOT NULL
        SET @BCPImport = @BCPImport + ' -f "' + @FormatFile + '"';
    
    -- Add any other options
    IF @Options IS NOT NULL
        SET @BCPImport = @BCPImport + ' ' + @Options;
    
    -- Return the commands
    SELECT 
        @BCPExport AS ExportCommand,
        @BCPImport AS ImportCommand;
END;
GO

-- Generate BCP commands for tables
EXEC dbo.GenerateBCPCommands 
    @TableName = 'Products', 
    @FilePath = 'C:\Temp\products_export.dat',
    @Options = '-c -t, -r\n';
GO

EXEC dbo.GenerateBCPCommands 
    @TableName = 'Employees', 
    @FilePath = 'C:\Temp\employees_export.dat',
    @FormatFile = 'C:\Temp\employees.fmt';
GO

-- Example of what a BCP command execution would look like
-- Note: These are commented out since xp_cmdshell execution of BCP
-- requires specific server configurations
/*
DECLARE @BCPCmd NVARCHAR(MAX) = 'bcp dbo.Products out C:\Temp\products_export.dat -S ' + 
                               @@SERVERNAME + ' -T -c -t, -r\n';
EXEC xp_cmdshell @BCPCmd;
GO
*/

-------------------------------------------------
-- Region: 7. Table-Valued Parameters for Batch Operations
-------------------------------------------------
/*
  Table-Valued Parameters (TVPs) allow you to pass multiple rows of data
  to a stored procedure in a structured way, ideal for batch operations.
*/

-- Create a user-defined table type
CREATE TYPE dbo.ProductUpdateTableType AS TABLE
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Price DECIMAL(10, 2),
    InStock BIT
);
GO

-- Create a stored procedure that accepts a TVP
CREATE OR ALTER PROCEDURE dbo.BulkUpdateProducts
    @ProductUpdates dbo.ProductUpdateTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create a temporary table to track changes
    CREATE TABLE #UpdatedProducts
    (
        ProductID INT PRIMARY KEY,
        OldPrice DECIMAL(10, 2),
        NewPrice DECIMAL(10, 2),
        PriceDifference DECIMAL(10, 2)
    );
    
    -- Update products and capture changes
    UPDATE p
    SET 
        p.ProductName = ISNULL(u.ProductName, p.ProductName),
        p.Category = ISNULL(u.Category, p.Category),
        p.Price = ISNULL(u.Price, p.Price),
        p.InStock = ISNULL(u.InStock, p.InStock),
        p.LastUpdated = GETDATE()
    OUTPUT 
        INSERTED.ProductID,
        DELETED.Price AS OldPrice,
        INSERTED.Price AS NewPrice,
        INSERTED.Price - DELETED.Price AS PriceDifference
    INTO #UpdatedProducts
    FROM dbo.Products p
    INNER JOIN @ProductUpdates u ON p.ProductID = u.ProductID;
    
    -- Return summary of changes
    SELECT 
        COUNT(*) AS TotalProductsUpdated,
        SUM(CASE WHEN PriceDifference > 0 THEN 1 ELSE 0 END) AS PriceIncreases,
        SUM(CASE WHEN PriceDifference < 0 THEN 1 ELSE 0 END) AS PriceDecreases,
        AVG(ABS(PriceDifference)) AS AveragePriceChange
    FROM #UpdatedProducts;
    
    -- Return detailed changes
    SELECT * FROM #UpdatedProducts
    ORDER BY ABS(PriceDifference) DESC;
END;
GO

-- Use the TVP to update multiple products at once
DECLARE @ProductUpdates dbo.ProductUpdateTableType;

-- Populate the table variable
INSERT INTO @ProductUpdates (ProductID, ProductName, Category, Price, InStock)
VALUES
    (1, 'High-End Laptop', 'Electronics', 1500.00, 1),
    (2, 'Premium Smartphone', 'Electronics', 950.00, 1),
    (3, NULL, NULL, 275.00, NULL),
    (4, NULL, NULL, 59.99, 1),
    (5, 'Wireless Headphones', NULL, 149.99, NULL);

-- Execute the stored procedure
EXEC dbo.BulkUpdateProducts @ProductUpdates;
GO

-- Verify the updates
SELECT * FROM dbo.Products;
GO

-------------------------------------------------
-- Region: 8. Bulk Copy Performance Optimization
-------------------------------------------------
/*
  Optimize BULK INSERT operations for maximum performance.
*/

-- Create a large test table for performance testing
CREATE TABLE dbo.LargeDataTable
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Column1 NVARCHAR(100),
    Column2 NVARCHAR(100),
    Column3 NVARCHAR(100),
    Column4 DECIMAL(18,2),
    Column5 DECIMAL(18,2),
    Column6 DATE,
    Column7 BIT
);
GO

-- Generate a larger test data file
CREATE OR ALTER PROCEDURE dbo.GenerateTestDataFile
    @RowCount INT,
    @FilePath NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate CSV header
    DECLARE @header NVARCHAR(MAX) = 'Column1,Column2,Column3,Column4,Column5,Column6,Column7';
    DECLARE @cmd NVARCHAR(MAX) = 'echo ' + @header + ' > ' + @FilePath;
    EXEC xp_cmdshell @cmd;
    
    -- Generate CSV data in batches to avoid memory issues
    DECLARE @i INT = 0;
    DECLARE @batchSize INT = 1000;
    DECLARE @csvData NVARCHAR(MAX);
    
    WHILE @i < @RowCount
    BEGIN
        SET @csvData = '';
        DECLARE @j INT = 0;
        
        WHILE @j < @batchSize AND @i < @RowCount
        BEGIN
            SET @csvData = @csvData + 
                'Value' + CAST(@i AS NVARCHAR(10)) + ',' +
                'Category' + CAST(@i % 10 AS NVARCHAR(10)) + ',' +
                'Description' + CAST(@i % 20 AS NVARCHAR(10)) + ',' +
                CAST((@i * 10.25) AS NVARCHAR(20)) + ',' +
                CAST((@i * 5.75) AS NVARCHAR(20)) + ',' +
                CONVERT(NVARCHAR(10), DATEADD(DAY, @i % 1000, '2020-01-01'), 120) + ',' +
                CAST(@i % 2 AS NVARCHAR(1)) + CHAR(13) + CHAR(10);
                
            SET @i = @i + 1;
            SET @j = @j + 1;
        END
        
        -- Append to the file
        SET @cmd = 'echo ' + @csvData + ' >> ' + @FilePath;
        EXEC xp_cmdshell @cmd;
    END
    
    PRINT 'Generated ' + CAST(@RowCount AS NVARCHAR(10)) + ' rows of test data to ' + @FilePath;
END;
GO

-- Generate a test file with 10,000 rows (adjust as needed)
EXEC dbo.GenerateTestDataFile @RowCount = 10000, @FilePath = 'C:\Temp\large_data.csv';
GO

-- Test different BULK INSERT configurations for performance
-- 1. Basic BULK INSERT
TRUNCATE TABLE dbo.LargeDataTable;
GO

DECLARE @StartTime DATETIME2 = GETDATE();

BULK INSERT dbo.LargeDataTable
FROM 'C:\Temp\large_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

PRINT 'Basic BULK INSERT took: ' + 
      CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + 'ms';
GO

-- 2. Optimized BULK INSERT with TABLOCK and batching
TRUNCATE TABLE dbo.LargeDataTable;
GO

DECLARE @StartTime DATETIME2 = GETDATE();

BULK INSERT dbo.LargeDataTable
FROM 'C:\Temp\large_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,                 -- Table lock for better performance
    ROWS_PER_BATCH = 2500,   -- Number of rows per batch
    BATCHSIZE = 2500,        -- Size of batches in rows
    ORDER (Column1),         -- Order for better memory usage with clustered index
    DATAFILETYPE = 'char'    -- Specify data type for non-Unicode data
);

PRINT 'Optimized BULK INSERT took: ' + 
      CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + 'ms';
GO

-- 3. Minimal logging with simple recovery model
-- Note: In a production environment, consider the implication of changing recovery models
ALTER DATABASE BulkOperationsDemo SET RECOVERY SIMPLE;
GO

TRUNCATE TABLE dbo.LargeDataTable;
GO

DECLARE @StartTime DATETIME2 = GETDATE();

BULK INSERT dbo.LargeDataTable
FROM 'C:\Temp\large_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    ROWS_PER_BATCH = 2500
);

PRINT 'Minimal logging BULK INSERT took: ' + 
      CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS NVARCHAR(10)) + 'ms';
GO

-- Reset recovery model to FULL for normal operations
ALTER DATABASE BulkOperationsDemo SET RECOVERY FULL;
GO

-------------------------------------------------
-- Region: 9. Monitoring Bulk Operations
-------------------------------------------------
/*
  Track and monitor bulk operations for troubleshooting and optimization.
*/

-- Create a monitoring table for bulk operations
CREATE TABLE dbo.BulkOperationsLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    OperationType NVARCHAR(50) NOT NULL,
    TableName NVARCHAR(128) NOT NULL,
    StartTime DATETIME2 NOT NULL,
    EndTime DATETIME2 NULL,
    RowsAffected BIGINT NULL,
    Status NVARCHAR(20) NULL,
    ErrorMessage NVARCHAR(MAX) NULL
);
GO

-- Create a stored procedure to monitor and log bulk operations
CREATE OR ALTER PROCEDURE dbo.LoggedBulkInsert
    @TableName NVARCHAR(128),
    @FilePath NVARCHAR(256),
    @Options NVARCHAR(MAX) = NULL