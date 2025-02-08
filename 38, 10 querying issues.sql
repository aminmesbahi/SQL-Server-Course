/*
  Script: QueryingBadPracticesAndOptimalApproaches.sql
  Description: This script demonstrates 10 common querying bad practices (or mistakes)
               and provides the correct (optimal) approaches for SQL Server 2022.
  Note: These examples use simple sample tables and data. Always test scripts in a development
        or staging environment before applying changes to production.
-------------------------------------------------------------
*/

/*=============================================================================
  1. Using SELECT * Versus Specifying Needed Columns
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Using SELECT * retrieves all columns even if only a few are needed.
    - This can lead to unnecessary I/O and maintenance issues when table schemas change.
    
  CORRECT APPROACH:
    - Explicitly list only the columns required by the query.
=============================================================================*/

-- Create sample table: Employees
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL 
    DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees (
    EmployeeID INT IDENTITY PRIMARY KEY,
    FirstName  VARCHAR(50),
    LastName   VARCHAR(50),
    Email      VARCHAR(100),
    HireDate   DATETIME
);
GO

-- BAD: Retrieve all columns
SELECT * FROM dbo.Employees;
GO

-- GOOD: Retrieve only the needed columns
SELECT EmployeeID, FirstName, LastName FROM dbo.Employees;
GO

/*=============================================================================
  2. Non-SARGable Queries: Using Functions on Indexed Columns
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Wrapping an indexed column in a function (e.g., YEAR(OrderDate)) prevents index usage.
    
  CORRECT APPROACH:
    - Rewrite the predicate to use range conditions so that the index can be used.
=============================================================================*/

-- Create sample table: Orders
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL 
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders (
    OrderID   INT IDENTITY PRIMARY KEY,
    OrderDate DATETIME,
    Amount    DECIMAL(10,2)
);
GO

-- BAD: Using a function on the column in the WHERE clause
SELECT * FROM dbo.Orders
WHERE YEAR(OrderDate) = 2020;
GO

-- GOOD: Use range predicates on the column
SELECT * FROM dbo.Orders
WHERE OrderDate >= '2020-01-01' AND OrderDate < '2021-01-01';
GO

/*=============================================================================
  3. Correlated Subqueries Versus JOINs
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Using a correlated subquery to calculate an aggregate per row can be inefficient.
    
  CORRECT APPROACH:
    - Use a JOIN with GROUP BY to compute aggregates in a set-based manner.
=============================================================================*/

-- Create sample tables: Products and OrderDetails
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL 
    DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL 
    DROP TABLE dbo.OrderDetails;
GO

CREATE TABLE dbo.Products (
    ProductID   INT IDENTITY PRIMARY KEY,
    ProductName VARCHAR(100)
);
GO

CREATE TABLE dbo.OrderDetails (
    OrderDetailID INT IDENTITY PRIMARY KEY,
    ProductID     INT,
    Price         DECIMAL(10,2)
);
GO

-- BAD: Correlated subquery to calculate average price for each product
SELECT ProductID, 
       (SELECT AVG(Price) FROM dbo.OrderDetails OD WHERE OD.ProductID = P.ProductID) AS AvgPrice
FROM dbo.Products P;
GO

-- GOOD: Use JOIN with GROUP BY for set-based aggregation
SELECT P.ProductID, AVG(OD.Price) AS AvgPrice
FROM dbo.Products P
JOIN dbo.OrderDetails OD ON P.ProductID = OD.ProductID
GROUP BY P.ProductID;
GO

/*=============================================================================
  4. Row-by-Row Processing Using Cursors Versus Set-Based Operations
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Using cursors to process rows one at a time is much slower than set-based operations.
    
  CORRECT APPROACH:
    - Replace cursor-based logic with a single set-based statement.
=============================================================================*/

-- Create sample table: Inventory
IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL 
    DROP TABLE dbo.Inventory;
GO

CREATE TABLE dbo.Inventory (
    ProductID INT PRIMARY KEY,
    Quantity  INT
);
GO

-- Insert sample data
INSERT INTO dbo.Inventory (ProductID, Quantity)
VALUES (1, 100), (2, 200), (3, 300);
GO

-- BAD: Update using a cursor (row-by-row processing)
DECLARE @ProdID INT, @Qty INT;

DECLARE inventory_cursor CURSOR FOR
    SELECT ProductID, Quantity FROM dbo.Inventory WHERE Quantity < 250;

OPEN inventory_cursor;
FETCH NEXT FROM inventory_cursor INTO @ProdID, @Qty;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE dbo.Inventory
    SET Quantity = Quantity + 10
    WHERE ProductID = @ProdID;

    FETCH NEXT FROM inventory_cursor INTO @ProdID, @Qty;
END;

CLOSE inventory_cursor;
DEALLOCATE inventory_cursor;
GO

-- Reset data for demonstration purposes
UPDATE dbo.Inventory
SET Quantity = CASE ProductID WHEN 1 THEN 100 WHEN 2 THEN 200 WHEN 3 THEN 300 END;
GO

-- GOOD: Set-based update
UPDATE dbo.Inventory
SET Quantity = Quantity + 10
WHERE Quantity < 250;
GO

/*=============================================================================
  5. Dynamic SQL: Concatenation Versus Parameterized Queries
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Building dynamic SQL via string concatenation can lead to SQL injection vulnerabilities.
    
  CORRECT APPROACH:
    - Use parameterized dynamic SQL with sp_executesql.
=============================================================================*/

-- Create sample table: Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL 
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    UserID   INT IDENTITY PRIMARY KEY,
    Username VARCHAR(100),
    IsActive BIT
);
GO

-- Insert sample data
INSERT INTO dbo.Users (Username, IsActive)
VALUES ('alice', 1), ('bob', 0), ('charlie', 1);
GO

DECLARE @UserName NVARCHAR(100) = 'alice';

-- BAD: Dynamic SQL built by concatenating strings
DECLARE @SQLBad NVARCHAR(MAX);
SET @SQLBad = N'SELECT * FROM dbo.Users WHERE Username = ''' + @UserName + N'''';
EXEC(@SQLBad);
GO

-- GOOD: Parameterized dynamic SQL using sp_executesql
DECLARE @SQLGood NVARCHAR(MAX);
SET @SQLGood = N'SELECT * FROM dbo.Users WHERE Username = @UserNameParam';
EXEC sp_executesql @SQLGood, N'@UserNameParam NVARCHAR(100)', @UserNameParam = @UserName;
GO

/*=============================================================================
  6. Unnecessary Use of DISTINCT Versus Proper JOINs
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Using DISTINCT to eliminate duplicates that result from an improper join.
    
  CORRECT APPROACH:
    - Write explicit JOINs with proper join conditions to avoid duplicates.
=============================================================================*/

-- Create sample tables: Categories and Products
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL 
    DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL 
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Categories (
    CategoryID   INT IDENTITY PRIMARY KEY,
    CategoryName VARCHAR(100)
);
GO

CREATE TABLE dbo.Products (
    ProductID   INT IDENTITY PRIMARY KEY,
    ProductName VARCHAR(100),
    CategoryID  INT
);
GO

-- BAD: Using DISTINCT with an implicit join (old-style join syntax)
SELECT DISTINCT P.ProductName, C.CategoryName
FROM dbo.Products P, dbo.Categories C
WHERE P.CategoryID = C.CategoryID;
GO

-- GOOD: Using an explicit INNER JOIN
SELECT P.ProductName, C.CategoryName
FROM dbo.Products P
INNER JOIN dbo.Categories C ON P.CategoryID = C.CategoryID;
GO

/*=============================================================================
  7. Using COUNT(*) to Check for Existence Versus EXISTS
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Checking for the existence of rows by counting them (which scans all matching rows).
    
  CORRECT APPROACH:
    - Use the EXISTS predicate, which stops at the first match.
=============================================================================*/

-- BAD: Using COUNT(*) to check if active users exist
IF ((SELECT COUNT(*) FROM dbo.Users WHERE IsActive = 1) > 0)
    PRINT 'Active user exists (using COUNT)';
GO

-- GOOD: Using EXISTS for existence check
IF EXISTS (SELECT 1 FROM dbo.Users WHERE IsActive = 1)
    PRINT 'Active user exists (using EXISTS)';
GO

/*=============================================================================
  8. Avoiding Implicit Data Type Conversions
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Comparing values of different data types (e.g., an INT column to a VARCHAR literal)
      can cause implicit conversions that may hinder index usage.
    
  CORRECT APPROACH:
    - Ensure that the compared literals or parameters use the same data type as the column.
=============================================================================*/

-- BAD: OrderID is INT, but comparing with a VARCHAR literal
SELECT * FROM dbo.Orders
WHERE OrderID = '1';  -- Implicit conversion from VARCHAR to INT may occur
GO

-- GOOD: Compare using the correct data type
SELECT * FROM dbo.Orders
WHERE OrderID = 1;
GO

/*=============================================================================
  9. Improper Use of NOLOCK Hints
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Overusing the NOLOCK hint can lead to dirty reads and inconsistent results.
    
  CORRECT APPROACH:
    - Use proper isolation levels (e.g., READ COMMITTED SNAPSHOT) or omit NOLOCK when accuracy is critical.
=============================================================================*/

-- BAD: Using NOLOCK indiscriminately (may return uncommitted data)
SELECT * FROM dbo.Orders WITH (NOLOCK)
WHERE Amount > 50;
GO

-- GOOD: Remove NOLOCK to ensure data consistency (or configure proper isolation levels)
SELECT * FROM dbo.Orders
WHERE Amount > 50;
GO

/*=============================================================================
 10. Overuse of Scalar User-Defined Functions (UDFs) in Queries
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Calling scalar UDFs in the SELECT list (or WHERE clause) for every row can cause performance degradation.
    
  CORRECT APPROACH:
    - Inline the logic directly in the query or use computed columns when possible.
=============================================================================*/

-- Create a scalar UDF (for demonstration purposes)
IF OBJECT_ID('dbo.ufn_GetFullName', 'FN') IS NOT NULL 
    DROP FUNCTION dbo.ufn_GetFullName;
GO

CREATE FUNCTION dbo.ufn_GetFullName (@FirstName VARCHAR(50), @LastName VARCHAR(50))
RETURNS VARCHAR(101)
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName;
END;
GO

-- Create sample table: Employees2
IF OBJECT_ID('dbo.Employees2', 'U') IS NOT NULL 
    DROP TABLE dbo.Employees2;
GO

CREATE TABLE dbo.Employees2 (
    EmployeeID INT IDENTITY PRIMARY KEY,
    FirstName  VARCHAR(50),
    LastName   VARCHAR(50),
    Department VARCHAR(50)
);
GO

-- Insert sample data
INSERT INTO dbo.Employees2 (FirstName, LastName, Department)
VALUES ('John', 'Doe', 'Sales'),
       ('Jane', 'Smith', 'HR'),
       ('Bob', 'Brown', 'IT');
GO

-- BAD: Using a scalar UDF in the SELECT list for every row
SELECT EmployeeID, dbo.ufn_GetFullName(FirstName, LastName) AS FullName, Department
FROM dbo.Employees2;
GO

-- GOOD: Inline the expression (SQL Server can optimize simple concatenations better)
SELECT EmployeeID, FirstName + ' ' + LastName AS FullName, Department
FROM dbo.Employees2;
GO

