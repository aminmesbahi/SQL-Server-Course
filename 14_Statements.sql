/**************************************************************
 * SQL Server 2022 Statements and Indexes Tutorial
 * Description: This script demonstrates how indexes support 
 *              various query types, along with the order of 
 *              statement processing in SQL Server. It covers:
 *              - Table creation with indexes.
 *              - Inserting sample data.
 *              - Query examples using equality, inequality, 
 *                BETWEEN, IN, LIKE, and functions.
 *              - JOIN operations and multi-condition queries.
 *              - Priority of processing (FROM, WHERE, GROUP BY, 
 *                HAVING, SELECT, ORDER BY).
 *              - Use of aliases in the SELECT clause.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating the Sample Table and Indexes
-------------------------------------------------
/*
  1.1 Create a sample table to demonstrate various query types.
*/
IF OBJECT_ID(N'dbo.SampleData', N'U') IS NOT NULL
    DROP TABLE dbo.SampleData;
GO

CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT,
    CreatedDate DATETIME
);
GO

/*
  1.2 Create nonclustered indexes on columns that will be used in queries.
*/
CREATE NONCLUSTERED INDEX IX_SampleData_Name ON dbo.SampleData(Name);
CREATE NONCLUSTERED INDEX IX_SampleData_Age ON dbo.SampleData(Age);
CREATE NONCLUSTERED INDEX IX_SampleData_CreatedDate ON dbo.SampleData(CreatedDate);
GO

-------------------------------------------------
-- Region: 2. Inserting Sample Data
-------------------------------------------------
/*
  2.1 Insert sample records into the table.
*/
INSERT INTO dbo.SampleData (ID, Name, Age, CreatedDate)
VALUES
    (1, 'Alice', 30, '2023-01-01'),
    (2, 'Bob', 25, '2023-02-01'),
    (3, 'Charlie', 35, '2023-03-01'),
    (4, 'David', 40, '2023-04-01'),
    (5, 'Eve', 28, '2023-05-01');
GO

-------------------------------------------------
-- Region: 3. Query Examples Using Various Operators
-------------------------------------------------
/*
  3.1 Query using equality operator (=)
       This query will use the index on the Name column.
*/
SELECT * 
FROM dbo.SampleData
WHERE Name = 'Alice';
GO

/*
  3.2 Query using inequality operator (>=)
       This query will use the index on the Age column.
*/
SELECT * 
FROM dbo.SampleData
WHERE Age >= 30;
GO

/*
  3.3 Query using BETWEEN operator
       This query will use the index on the CreatedDate column.
*/
SELECT * 
FROM dbo.SampleData
WHERE CreatedDate BETWEEN '2023-01-01' AND '2023-03-31';
GO

/*
  3.4 Query using IN operator
       This query will use the index on the Name column.
*/
SELECT * 
FROM dbo.SampleData
WHERE Name IN ('Alice', 'Bob');
GO

/*
  3.5 Query using a string function (NOT supported by indexes)
       This query will NOT use the index on the Name column.
*/
SELECT * 
FROM dbo.SampleData
WHERE LEFT(Name, 1) = 'A';
GO

/*
  3.6 Query using a date function (NOT supported by indexes)
       This query will NOT use the index on the CreatedDate column.
*/
SELECT * 
FROM dbo.SampleData
WHERE YEAR(CreatedDate) = 2023;
GO

/*
  3.7 Query using LIKE operator (supported by indexes if not starting with a wildcard)
       This query will use the index on the Name column.
*/
SELECT * 
FROM dbo.SampleData
WHERE Name LIKE 'A%';
GO

/*
  3.8 Query using LIKE operator with a leading wildcard (NOT supported by indexes)
       This query will NOT use the index on the Name column.
*/
SELECT * 
FROM dbo.SampleData
WHERE Name LIKE '%e';
GO

-------------------------------------------------
-- Region: 4. Query Examples Using Sorting and Multiple Conditions
-------------------------------------------------
/*
  4.1 Query using ORDER BY clause
       This query may use the index on the Age column for sorting.
*/
SELECT * 
FROM dbo.SampleData
ORDER BY Age;
GO

/*
  4.2 Query using WHERE clause with multiple conditions
       This query will use the indexes on both Age and CreatedDate columns.
*/
SELECT * 
FROM dbo.SampleData
WHERE Age >= 30 AND CreatedDate <= '2023-04-01';
GO

-------------------------------------------------
-- Region: 5. JOIN Operations and Aliases
-------------------------------------------------
/*
  5.1 Create another table to demonstrate JOIN operations.
*/
IF OBJECT_ID(N'dbo.OtherData', N'U') IS NOT NULL
    DROP TABLE dbo.OtherData;
GO

CREATE TABLE dbo.OtherData
(
    ID INT PRIMARY KEY,
    Description NVARCHAR(100)
);
GO

/*
  5.2 Insert sample records into the OtherData table.
*/
INSERT INTO dbo.OtherData (ID, Description)
VALUES
    (1, 'Description 1'),
    (2, 'Description 2'),
    (3, 'Description 3'),
    (4, 'Description 4'),
    (5, 'Description 5');
GO

/*
  5.3 JOIN query using indexes on join columns.
       This query uses the index on the ID column of both tables.
*/
SELECT sd.Name, od.Description
FROM dbo.SampleData sd
JOIN dbo.OtherData od ON sd.ID = od.ID;
GO

/*
  5.4 Demonstrating priority of statement processing.
       The processing order is: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY.
*/
SELECT Name, COUNT(*) AS Count
FROM dbo.SampleData
WHERE Age >= 30
GROUP BY Name
HAVING COUNT(*) > 0
ORDER BY Name;
GO

/*
  5.5 Demonstrating the use of aliases.
       Aliases are processed in the SELECT clause.
*/
SELECT sd.Name AS PersonName, sd.Age AS PersonAge
FROM dbo.SampleData sd
WHERE sd.Age >= 30
ORDER BY PersonName;
GO
