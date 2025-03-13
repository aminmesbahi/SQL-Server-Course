/**************************************************************
 * SQL Server 2022 OPENROWSET Tutorial
 * Description: This script demonstrates how to use OPENROWSET and
 *              BULK operations in SQL Server 2022. It covers:
 *              - Using OPENROWSET to query remote SQL Server instances
 *              - Importing data from various file formats (CSV, XML, JSON)
 *              - Working with BULK import operations
 *              - Querying Azure Blob Storage
 *              - Using OPENROWSET with structured file formats
 *              - Transforming and filtering external data
 *              - Performance considerations and best practices
 **************************************************************/

-------------------------------------------------
-- Region: 1. Understanding OPENROWSET Basics
-------------------------------------------------
USE master;
GO

/*
  Enable Ad Hoc Distributed Queries configuration option.
  This is required for OPENROWSET to work properly.
*/
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

/*
  Create a test database for our examples.
*/
IF DB_ID('OpenRowsetDemo') IS NOT NULL
BEGIN
    ALTER DATABASE OpenRowsetDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OpenRowsetDemo;
END
GO

CREATE DATABASE OpenRowsetDemo;
GO

USE OpenRowsetDemo;
GO

/*
  OPENROWSET provides a way to access remote data from OLE DB data sources.
  The basic syntax is:
  
  SELECT *
  FROM OPENROWSET(
       'provider_name',
       'provider_string',
       {table_name | query}
  )
*/

-- Create a sample table that we will use for demonstration
CREATE TABLE dbo.LocalSalesData
(
    SaleID INT PRIMARY KEY,
    ProductName NVARCHAR(50),
    Quantity INT,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
);
GO

-- Insert some sample data
INSERT INTO dbo.LocalSalesData (SaleID, ProductName, Quantity, SaleDate, Amount)
VALUES 
    (1, 'Laptop', 2, '2023-01-15', 2400.00),
    (2, 'Monitor', 3, '2023-01-20', 750.00),
    (3, 'Keyboard', 5, '2023-02-05', 350.00),
    (4, 'Mouse', 10, '2023-02-10', 300.00),
    (5, 'Headphones', 7, '2023-02-15', 490.00);
GO

-------------------------------------------------
-- Region: 2. Querying Remote SQL Server Databases
-------------------------------------------------
/*
  The following example demonstrates how to query a SQL Server instance using OPENROWSET.
  Replace 'ServerName' with your actual server name.
  Make sure to enable SQL Server authentication if using SQL Server authentication.
*/

-- Using SQL Server Authentication:
-- This example queries the local instance, but you can replace with remote server name
-- Note: We're using 'sqlncli11' provider which is SQL Server Native Client 11.0
SELECT *
FROM OPENROWSET(
    'SQLNCLI11',
    'Server=localhost;Trusted_Connection=yes;',
    'SELECT * FROM OpenRowsetDemo.dbo.LocalSalesData'
);
GO

-- Using Windows Authentication with linked server name
-- This example shows how to query from a specific table
SELECT *
FROM OPENROWSET(
    'SQLNCLI11',
    'Server=localhost;Trusted_Connection=yes;',
    'OpenRowsetDemo.dbo.LocalSalesData'
);
GO

-- Query with filtering condition
SELECT *
FROM OPENROWSET(
    'SQLNCLI11',
    'Server=localhost;Trusted_Connection=yes;',
    'SELECT * FROM OpenRowsetDemo.dbo.LocalSalesData WHERE Amount > 500'
);
GO

-------------------------------------------------
-- Region: 3. Importing Data from CSV Files
-------------------------------------------------
/*
  OPENROWSET with BULK option allows importing data from files.
  The following example demonstrates importing from a CSV file.
  Make sure the path to the file exists before running this example.
*/

-- First, let's create a sample CSV file using xp_cmdshell
-- Note: xp_cmdshell requires appropriate permissions
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- Create a sample CSV file in temp directory (make sure the path exists)
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

-- Read data from CSV file using OPENROWSET with BULK option
SELECT *
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    SINGLE_CLOB
) AS FileContent;
GO

-- Parse CSV content with proper data types using FORMAT = 'CSV'
-- SQL Server 2017 and later supports this option
SELECT *
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMATFILE = 'C:\Temp\products.fmt',
    FIRSTROW = 2
) AS Products;
GO

-- Format file (products.fmt) content should be:
-- Note: You need to create this file separately
/*
<?xml version="1.0"?>
<BCPFORMAT xmlns="http://schemas.microsoft.com/sqlserver/2004/bulkload/format" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <RECORD>
    <FIELD ID="1" xsi:type="CharTerm" TERMINATOR="," MAX_LENGTH="10"/>
    <FIELD ID="2" xsi:type="CharTerm" TERMINATOR="," MAX_LENGTH="50"/>
    <FIELD ID="3" xsi:type="CharTerm" TERMINATOR="," MAX_LENGTH="50"/>
    <FIELD ID="4" xsi:type="CharTerm" TERMINATOR="," MAX_LENGTH="10"/>
    <FIELD ID="5" xsi:type="CharTerm" TERMINATOR="\r\n" MAX_LENGTH="1"/>
  </RECORD>
  <ROW>
    <COLUMN SOURCE="1" NAME="ProductID" xsi:type="SQLINT"/>
    <COLUMN SOURCE="2" NAME="ProductName" xsi:type="SQLNVARCHAR"/>
    <COLUMN SOURCE="3" NAME="Category" xsi:type="SQLNVARCHAR"/>
    <COLUMN SOURCE="4" NAME="Price" xsi:type="SQLDECIMAL" PRECISION="10" SCALE="2"/>
    <COLUMN SOURCE="5" NAME="InStock" xsi:type="SQLBIT"/>
  </ROW>
</BCPFORMAT>
*/

-- Alternative using WITH clause for CSV (SQL Server 2022+)
-- This automatically handles CSV headers and data types
SELECT *
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS Products;
GO

-- Creating a permanent table from the CSV data
SELECT *
INTO dbo.Products
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS Products;
GO

-------------------------------------------------
-- Region: 4. Working with JSON Files
-------------------------------------------------
/*
  OPENROWSET can also be used to import JSON data.
  Let's create and import a JSON file.
*/

-- Create a sample JSON file
DECLARE @json_content NVARCHAR(MAX) = N'[
    {"CustomerID": 1, "Name": "John Smith", "Email": "john.smith@example.com", "Orders": [{"OrderID": 101, "Amount": 450.00}, {"OrderID": 102, "Amount": 290.00}]},
    {"CustomerID": 2, "Name": "Jane Doe", "Email": "jane.doe@example.com", "Orders": [{"OrderID": 103, "Amount": 820.00}]},
    {"CustomerID": 3, "Name": "Robert Johnson", "Email": "robert.johnson@example.com", "Orders": []}
]';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + REPLACE(@json_content, CHAR(10), '') + ' > C:\Temp\customers.json';
EXEC xp_cmdshell @cmd;
GO

-- Read JSON file as a whole
SELECT BulkColumn
FROM OPENROWSET(
    BULK 'C:\Temp\customers.json',
    SINGLE_CLOB
) AS JsonFile;
GO

-- Parse JSON content to extract specific data
SELECT 
    JSON_VALUE(customer.value, '$.CustomerID') AS CustomerID,
    JSON_VALUE(customer.value, '$.Name') AS Name,
    JSON_VALUE(customer.value, '$.Email') AS Email,
    JSON_QUERY(customer.value, '$.Orders') AS Orders
FROM OPENROWSET(
    BULK 'C:\Temp\customers.json',
    SINGLE_CLOB
) AS JsonFile
CROSS APPLY OPENJSON(BulkColumn) AS customer;
GO

-- Extract nested elements (orders)
SELECT 
    JSON_VALUE(customer.value, '$.CustomerID') AS CustomerID,
    JSON_VALUE(customer.value, '$.Name') AS Name,
    JSON_VALUE(order.value, '$.OrderID') AS OrderID,
    JSON_VALUE(order.value, '$.Amount') AS OrderAmount
FROM OPENROWSET(
    BULK 'C:\Temp\customers.json',
    SINGLE_CLOB
) AS JsonFile
CROSS APPLY OPENJSON(BulkColumn) AS customer
CROSS APPLY OPENJSON(JSON_QUERY(customer.value, '$.Orders')) AS order
WHERE JSON_VALUE(order.value, '$.OrderID') IS NOT NULL;
GO

-------------------------------------------------
-- Region: 5. Working with XML Files
-------------------------------------------------
/*
  OPENROWSET can be used with XML files too.
  Let's create and import an XML file.
*/

-- Create a sample XML file
DECLARE @xml_content NVARCHAR(MAX) = N'<?xml version="1.0" encoding="utf-8"?>
<Employees>
    <Employee ID="1">
        <Name>Alice Johnson</Name>
        <Position>Software Engineer</Position>
        <Department>IT</Department>
        <Salary>85000</Salary>
    </Employee>
    <Employee ID="2">
        <Name>Bob Smith</Name>
        <Position>Database Administrator</Position>
        <Department>IT</Department>
        <Salary>92000</Salary>
    </Employee>
    <Employee ID="3">
        <Name>Carol Davis</Name>
        <Position>Project Manager</Position>
        <Department>Operations</Department>
        <Salary>105000</Salary>
    </Employee>
</Employees>';

DECLARE @cmd NVARCHAR(MAX) = 'echo ' + REPLACE(REPLACE(@xml_content, CHAR(10), ''), '"', '\"') + ' > C:\Temp\employees.xml';
EXEC xp_cmdshell @cmd;
GO

-- Read XML file as a whole
SELECT BulkColumn
FROM OPENROWSET(
    BULK 'C:\Temp\employees.xml',
    SINGLE_CLOB
) AS XmlFile;
GO

-- Parse XML content using .nodes method
DECLARE @xml XML;

SELECT @xml = BulkColumn
FROM OPENROWSET(
    BULK 'C:\Temp\employees.xml',
    SINGLE_CLOB
) AS XmlFile;

SELECT 
    Employee.value('@ID', 'INT') AS EmployeeID,
    Employee.value('Name[1]', 'NVARCHAR(100)') AS Name,
    Employee.value('Position[1]', 'NVARCHAR(100)') AS Position,
    Employee.value('Department[1]', 'NVARCHAR(50)') AS Department,
    Employee.value('Salary[1]', 'DECIMAL(10,2)') AS Salary
FROM @xml.nodes('/Employees/Employee') AS EmployeeTable(Employee);
GO

-------------------------------------------------
-- Region: 6. BULK Import Operations
-------------------------------------------------
/*
  BULK INSERT is an alternative to OPENROWSET(BULK...) for importing data.
  The following examples demonstrate various BULK operations.
*/

-- Simple BULK INSERT from CSV to existing table
CREATE TABLE dbo.BulkProducts
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(50),
    Category NVARCHAR(50),
    Price DECIMAL(10, 2),
    InStock BIT
);
GO

-- BULK INSERT with options
BULK INSERT dbo.BulkProducts
FROM 'C:\Temp\products.csv'
WITH (
    FIRSTROW = 2,             -- Skip header row
    FIELDTERMINATOR = ',',    -- CSV field delimiter
    ROWTERMINATOR = '\n',     -- Row terminator
    TABLOCK,                  -- Table lock for better performance
    CHECK_CONSTRAINTS         -- Check constraints during load
);
GO

-- Create a format file for more control (BCP utility)
-- Note: This would be run from command prompt, not SQL Server
/*
bcp OpenRowsetDemo.dbo.BulkProducts format nul -c -t, -f C:\Temp\products_format.fmt -S localhost -T
*/

-- BULK INSERT with a format file
BULK INSERT dbo.BulkProducts
FROM 'C:\Temp\products.csv'
WITH (
    FORMATFILE = 'C:\Temp\products_format.fmt',
    FIRSTROW = 2,
    TABLOCK
);
GO

-------------------------------------------------
-- Region: 7. Querying Data from Excel
-------------------------------------------------
/*
  The following examples show how to query Excel files using OPENROWSET.
  Note: This requires Excel OLEDB provider to be installed on the server.
*/

-- Query an Excel spreadsheet
-- Note: This requires the 'Microsoft.ACE.OLEDB.12.0' provider to be installed
-- and 'DisallowAdhocAccess' set to 0 for this provider in SQL Server
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Temp\SalesData.xlsx;HDR=YES',
    'SELECT * FROM [Sheet1$]'
) AS ExcelData;
GO

-- Import a specific range from Excel
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Temp\SalesData.xlsx;HDR=YES',
    'SELECT * FROM [Sheet1$A1:E10]'
) AS ExcelData;
GO

-------------------------------------------------
-- Region: 8. Working with Azure Storage (SQL Server 2022)
-------------------------------------------------
/*
  SQL Server 2022 enhances OPENROWSET support for Azure Storage.
  The following examples demonstrate querying data in Azure Storage.
  Note: These examples require appropriate Azure Storage configuration.
*/

-- To enable Azure storage access, create a database scoped credential
-- Replace with your own Azure storage account information
CREATE DATABASE SCOPED CREDENTIAL [https://yourstorageaccount.blob.core.windows.net/]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = '?sv=2021-06-08&ss=b&srt=co&sp=rl&se=2023-12-31T00:00:00Z&st=2023-01-01T00:00:00Z&spr=https&sig=XXXXX';
GO

-- Query CSV file in Azure Blob Storage
SELECT TOP 10 *
FROM OPENROWSET(
    BULK 'https://yourstorageaccount.blob.core.windows.net/data/sales.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS [sales];
GO

-- Query Parquet file in Azure Blob Storage
SELECT TOP 10 *
FROM OPENROWSET(
    BULK 'https://yourstorageaccount.blob.core.windows.net/data/sales.parquet',
    FORMAT = 'PARQUET'
) AS [sales];
GO

-- Query JSON file in Azure Blob Storage
SELECT *
FROM OPENROWSET(
    BULK 'https://yourstorageaccount.blob.core.windows.net/data/customers.json',
    FORMAT = 'CSV',
    FIELDQUOTE = '0x0b',
    FIELDTERMINATOR ='0x0b',
    ROWTERMINATOR = '0x0a'
) WITH (
    jsonContent varchar(MAX)
) AS [result]
CROSS APPLY OPENJSON(jsonContent) WITH (
    CustomerID INT,
    Name NVARCHAR(100),
    Email NVARCHAR(100)
) AS customers;
GO

-------------------------------------------------
-- Region: 9. Advanced Transformations and Filtering
-------------------------------------------------
/*
  The following examples demonstrate advanced operations with OPENROWSET results.
*/

-- Join OPENROWSET results with local tables
SELECT 
    p.ProductName,
    p.Category,
    s.Quantity,
    s.SaleDate,
    s.Amount
FROM dbo.LocalSalesData s
JOIN OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS p
ON s.ProductName = p.ProductName;
GO

-- Apply aggregation to external data
SELECT 
    Category,
    COUNT(*) AS ProductCount,
    AVG(CAST(Price AS DECIMAL(10,2))) AS AveragePrice,
    SUM(CAST(Price AS DECIMAL(10,2))) AS TotalValue
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS p
GROUP BY Category
ORDER BY TotalValue DESC;
GO

-- Using OPENROWSET in a CTE
WITH ProductData AS (
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        InStock
    FROM OPENROWSET(
        BULK 'C:\Temp\products.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
    ) AS p
)
SELECT 
    Category,
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN InStock = 1 THEN 1 ELSE 0 END) AS InStockProducts
FROM ProductData
GROUP BY Category;
GO

-- Using OPENROWSET in a derived table
SELECT 
    Category,
    ProductCount,
    InStockCount,
    CAST((InStockCount * 100.0 / ProductCount) AS DECIMAL(5,2)) AS InStockPercentage
FROM (
    SELECT 
        Category,
        COUNT(*) AS ProductCount,
        SUM(CASE WHEN InStock = 1 THEN 1 ELSE 0 END) AS InStockCount
    FROM OPENROWSET(
        BULK 'C:\Temp\products.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
    ) AS p
    GROUP BY Category
) AS CategoryStats;
GO

-------------------------------------------------
-- Region: 10. Performance Considerations and Best Practices
-------------------------------------------------
/*
  The following points are important for optimal OPENROWSET performance.
*/

-- 1. Always specify the exact columns you need rather than SELECT *
SELECT ProductID, ProductName, Price
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS Products;
GO

-- 2. Add WITH clause to define explicit schema when possible
SELECT ProductID, ProductName, Price 
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) WITH (
    ProductID INT,
    ProductName NVARCHAR(50),
    Category NVARCHAR(50),
    Price DECIMAL(10,2),
    InStock BIT
) AS Products;
GO

-- 3. For frequently accessed external data, consider importing into temporary or permanent tables
SELECT *
INTO #TempProducts
FROM OPENROWSET(
    BULK 'C:\Temp\products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) WITH (
    ProductID INT,
    ProductName NVARCHAR(50),
    Category NVARCHAR(50),
    Price DECIMAL(10,2),
    InStock BIT
) AS Products;

-- Now query from the temp table for better performance
SELECT * FROM #TempProducts WHERE Price > 100;
GO

-- 4. Use TABLOCK when bulk importing large datasets
BULK INSERT dbo.BulkProducts
FROM 'C:\Temp\products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    BATCHSIZE = 5000,
    MAXERRORS = 10
);
GO

-------------------------------------------------
-- Region: 11. Security Considerations
-------------------------------------------------
/*
  Security is important when using OPENROWSET to access external data.
*/

-- Create a login and user with limited permissions
CREATE LOGIN OpenRowsetUser WITH PASSWORD = 'StrongPassword123!';
GO

CREATE USER OpenRowsetUser FOR LOGIN OpenRowsetUser;
GO

-- Grant only necessary permissions
GRANT SELECT ON dbo.LocalSalesData TO OpenRowsetUser;
GRANT ADMINISTER BULK OPERATIONS TO OpenRowsetUser; -- For BULK operations
GO

-- Create a database master key for encryption (required for credentials)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongMasterKeyPassword123!';
GO

-- Create a database scoped credential for secure external access
CREATE DATABASE SCOPED CREDENTIAL ExternalDataCredential 
WITH IDENTITY = 'ExternalUser',
SECRET = 'StrongExternalPassword123!';
GO

-------------------------------------------------
-- Region: 12. Cleanup
-------------------------------------------------
/*
  Clean up the resources created in this tutorial.
*/

-- Drop the tables
DROP TABLE IF EXISTS dbo.LocalSalesData;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.BulkProducts;
DROP TABLE IF EXISTS #TempProducts;
GO

-- Disable Ad Hoc Distributed Queries
EXEC sp_configure 'Ad Hoc Distributed Queries', 0;
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
GO

-- Remove the database scoped credential
DROP DATABASE SCOPED CREDENTIAL IF EXISTS ExternalDataCredential;
GO

-- Remove the user and login
DROP USER IF EXISTS OpenRowsetUser;
GO

-- In master database:
-- DROP LOGIN OpenRowsetUser;

-- Drop the database if desired
USE master;
GO

-- Uncomment the following line to drop the database
-- ALTER DATABASE OpenRowsetDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- DROP DATABASE OpenRowsetDemo;
-- GO