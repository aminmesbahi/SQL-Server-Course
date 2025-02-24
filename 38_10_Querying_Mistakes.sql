/**************************************************************
 * SQL Server 2022: Querying Bad Practices and Optimal Approaches
 * Description: This script demonstrates 10 common querying bad 
 *              practices and provides optimal approaches for each.
 *              The examples cover:
 *              1. Using SELECT * versus specifying needed columns.
 *              2. Avoiding non-SARGable queries.
 *              3. Using JOINs instead of correlated subqueries.
 *              4. Set-based operations versus row-by-row processing.
 *              5. Dynamic SQL: String concatenation versus parameterized queries.
 *              6. Avoiding unnecessary DISTINCT usage.
 *              7. Using EXISTS rather than COUNT(*) for existence checks.
 *              8. Preventing implicit data type conversions.
 *              9. Proper use of NOLOCK hints.
 *             10. Reducing overuse of scalar UDFs in queries.
 **************************************************************/

-------------------------------------------------
-- Region 1: Using SELECT * vs. Specifying Needed Columns
-------------------------------------------------
/*
  BAD PRACTICE: Using SELECT * retrieves all columns even if only a few are needed.
  CORRECT APPROACH: List only the required columns.
*/

-- Setup sample table: Employees
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

-------------------------------------------------
-- Region 2: Avoiding Non-SARGable Queries
-------------------------------------------------
/*
  BAD PRACTICE: Wrapping an indexed column in a function (e.g., YEAR(OrderDate)) prevents index usage.
  CORRECT APPROACH: Use range conditions to allow index usage.
*/

-- Setup sample table: Orders
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

-- GOOD: Use range predicates
SELECT * FROM dbo.Orders
WHERE OrderDate >= '2020-01-01' AND OrderDate < '2021-01-01';
GO

-------------------------------------------------
-- Region 3: Correlated Subqueries vs. JOINs
-------------------------------------------------
/*
  BAD PRACTICE: Using a correlated subquery to compute an aggregate per row.
  CORRECT APPROACH: Use JOIN with GROUP BY for set-based aggregation.
*/

-- Setup sample tables: Products and OrderDetails
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

-- BAD: Correlated subquery for each product
SELECT ProductID, 
       (SELECT AVG(Price) FROM dbo.OrderDetails OD WHERE OD.ProductID = P.ProductID) AS AvgPrice
FROM dbo.Products P;
GO

-- GOOD: JOIN with GROUP BY for set-based aggregation
SELECT P.ProductID, AVG(OD.Price) AS AvgPrice
FROM dbo.Products P
JOIN dbo.OrderDetails OD ON P.ProductID = OD.ProductID
GROUP BY P.ProductID;
GO

-------------------------------------------------
-- Region 4: Row-by-Row Processing vs. Set-Based Operations
-------------------------------------------------
/*
  BAD PRACTICE: Using cursors to update rows one by one.
  CORRECT APPROACH: Use set-based updates.
*/

-- Setup sample table: Inventory
IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL 
    DROP TABLE dbo.Inventory;
GO

CREATE TABLE dbo.Inventory (
    ProductID INT PRIMARY KEY,
    Quantity  INT
);
GO

INSERT INTO dbo.Inventory (ProductID, Quantity)
VALUES (1, 100), (2, 200), (3, 300);
GO

-- BAD: Cursor-based update
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

-- Reset data for demonstration
UPDATE dbo.Inventory
SET Quantity = CASE ProductID WHEN 1 THEN 100 WHEN 2 THEN 200 WHEN 3 THEN 300 END;
GO

-- GOOD: Set-based update
UPDATE dbo.Inventory
SET Quantity = Quantity + 10
WHERE Quantity < 250;
GO

-------------------------------------------------
-- Region 5: Dynamic SQL: Concatenation vs. Parameterized Queries
-------------------------------------------------
/*
  BAD PRACTICE: Building dynamic SQL via string concatenation (vulnerable to SQL injection).
  CORRECT APPROACH: Use parameterized dynamic SQL with sp_executesql.
*/

-- Setup sample table: Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL 
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    UserID   INT IDENTITY PRIMARY KEY,
    Username VARCHAR(100),
    IsActive BIT
);
GO

INSERT INTO dbo.Users (Username, IsActive)
VALUES ('alice', 1), ('bob', 0), ('charlie', 1);
GO

DECLARE @UserName NVARCHAR(100) = 'alice';

-- BAD: Dynamic SQL via concatenation
DECLARE @SQLBad NVARCHAR(MAX);
SET @SQLBad = N'SELECT * FROM dbo.Users WHERE Username = ''' + @UserName + N''''; 
EXEC(@SQLBad);
GO

-- GOOD: Parameterized dynamic SQL
DECLARE @SQLGood NVARCHAR(MAX);
SET @SQLGood = N'SELECT * FROM dbo.Users WHERE Username = @UserNameParam';
EXEC sp_executesql @SQLGood, N'@UserNameParam NVARCHAR(100)', @UserNameParam = @UserName;
GO

-------------------------------------------------
-- Region 6: Unnecessary Use of DISTINCT vs. Proper JOINs
-------------------------------------------------
/*
  BAD PRACTICE: Using DISTINCT to remove duplicates from an improper join.
  CORRECT APPROACH: Write explicit JOINs with proper join conditions.
*/

-- Setup sample tables: Categories and Products
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

-- BAD: Using DISTINCT with implicit join syntax
SELECT DISTINCT P.ProductName, C.CategoryName
FROM dbo.Products P, dbo.Categories C
WHERE P.CategoryID = C.CategoryID;
GO

-- GOOD: Using explicit INNER JOIN
SELECT P.ProductName, C.CategoryName
FROM dbo.Products P
INNER JOIN dbo.Categories C ON P.CategoryID = C.CategoryID;
GO

-------------------------------------------------
-- Region 7: Using COUNT(*) vs. EXISTS for Existence Checks
-------------------------------------------------
/*
  BAD PRACTICE: Using COUNT(*) to check for the existence of rows (scans all rows).
  CORRECT APPROACH: Use EXISTS, which stops after the first match.
*/

-- BAD: Existence check using COUNT(*)
IF ((SELECT COUNT(*) FROM dbo.Users WHERE IsActive = 1) > 0)
    PRINT 'Active user exists (using COUNT)';
GO

-- GOOD: Existence check using EXISTS
IF EXISTS (SELECT 1 FROM dbo.Users WHERE IsActive = 1)
    PRINT 'Active user exists (using EXISTS)';
GO

-------------------------------------------------
-- Region 8: Avoiding Implicit Data Type Conversions
-------------------------------------------------
/*
  BAD PRACTICE: Comparing values of different data types (e.g., INT vs. VARCHAR) may force conversions.
  CORRECT APPROACH: Use matching data types in comparisons.
*/

-- BAD: Implicit conversion from VARCHAR to INT
SELECT * FROM dbo.Orders
WHERE OrderID = '1';
GO

-- GOOD: Use the correct data type
SELECT * FROM dbo.Orders
WHERE OrderID = 1;
GO

-------------------------------------------------
-- Region 9: Proper Use of NOLOCK Hints
-------------------------------------------------
/*
  BAD PRACTICE: Overusing NOLOCK can lead to dirty reads.
  CORRECT APPROACH: Use NOLOCK judiciously or rely on appropriate isolation levels.
*/

-- BAD: Using NOLOCK indiscriminately
SELECT * FROM dbo.Orders WITH (NOLOCK)
WHERE Amount > 50;
GO

-- GOOD: Remove NOLOCK for data consistency (or configure proper isolation levels)
SELECT * FROM dbo.Orders
WHERE Amount > 50;
GO

-------------------------------------------------
-- Region 10: Overuse of Scalar UDFs in Queries
-------------------------------------------------
/*
  BAD PRACTICE: Calling scalar UDFs for every row can cause performance degradation.
  CORRECT APPROACH: Inline simple logic or use computed columns.
*/

-- Create a scalar UDF (for demonstration)
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

-- Setup sample table: Employees2
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

INSERT INTO dbo.Employees2 (FirstName, LastName, Department)
VALUES ('John', 'Doe', 'Sales'),
       ('Jane', 'Smith', 'HR'),
       ('Bob', 'Brown', 'IT');
GO

-- BAD: Using a scalar UDF in the SELECT list for every row
SELECT EmployeeID, dbo.ufn_GetFullName(FirstName, LastName) AS FullName, Department
FROM dbo.Employees2;
GO

-- GOOD: Inline the expression for better performance
SELECT EmployeeID, FirstName + ' ' + LastName AS FullName, Department
FROM dbo.Employees2;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------