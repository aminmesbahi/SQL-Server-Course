-------------------------------------
-- 14: Statements and Indexes
-------------------------------------
/*
Collecting workspace information

Here is a full set of runnable queries to demonstrate how indexes support various types of queries, along with explanations as comments. Additionally, some queries show the priority of statement processing in SQL Server.

```sql
-------------------------------------
-- 14: Statements and Indexes
-------------------------------------

USE TestDB;
GO

-- Create a sample table with indexes
CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT,
    CreatedDate DATETIME
);
GO

-- Create indexes on the table
CREATE NONCLUSTERED INDEX IX_SampleData_Name ON dbo.SampleData(Name);
CREATE NONCLUSTERED INDEX IX_SampleData_Age ON dbo.SampleData(Age);
CREATE NONCLUSTERED INDEX IX_SampleData_CreatedDate ON dbo.SampleData(CreatedDate);
GO

-- Insert sample data
INSERT INTO dbo.SampleData (ID, Name, Age, CreatedDate)
VALUES
    (1, 'Alice', 30, '2023-01-01'),
    (2, 'Bob', 25, '2023-02-01'),
    (3, 'Charlie', 35, '2023-03-01'),
    (4, 'David', 40, '2023-04-01'),
    (5, 'Eve', 28, '2023-05-01');
GO

-- Query using equality operator (=)
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name = 'Alice';
GO

-- Query using inequality operator (>=)
-- This query will use the index on the Age column
SELECT * FROM dbo.SampleData
WHERE Age >= 30;
GO

-- Query using BETWEEN operator
-- This query will use the index on the CreatedDate column
SELECT * FROM dbo.SampleData
WHERE CreatedDate BETWEEN '2023-01-01' AND '2023-03-31';
GO

-- Query using IN operator
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name IN ('Alice', 'Bob');
GO

-- Query using string function (NOT supported by indexes)
-- This query will NOT use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE LEFT(Name, 1) = 'A';
GO

-- Query using date function (NOT supported by indexes)
-- This query will NOT use the index on the CreatedDate column
SELECT * FROM dbo.SampleData
WHERE YEAR(CreatedDate) = 2023;
GO

-- Query using LIKE operator (supported by indexes if not starting with wildcard)
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name LIKE 'A%';
GO

-- Query using LIKE operator with leading wildcard (NOT supported by indexes)
-- This query will NOT use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name LIKE '%e';
GO

-- Query using ORDER BY clause
-- This query will use the index on the Age column for sorting
SELECT * FROM dbo.SampleData
ORDER BY Age;
GO

-- Query using WHERE clause with multiple conditions
-- This query will use the indexes on the Age and CreatedDate columns
SELECT * FROM dbo.SampleData
WHERE Age >= 30 AND CreatedDate <= '2023-04-01';
GO

-- Query using JOIN (indexes on join columns will be used)
-- This query will use the index on the ID column of both tables
CREATE TABLE dbo.OtherData
(
    ID INT PRIMARY KEY,
    Description NVARCHAR(100)
);
GO

INSERT INTO dbo.OtherData (ID, Description)
VALUES
    (1, 'Description 1'),
    (2, 'Description 2'),
    (3, 'Description 3'),
    (4, 'Description 4'),
    (5, 'Description 5');
GO

SELECT sd.Name, od.Description
FROM dbo.SampleData sd
JOIN dbo.OtherData od ON sd.ID = od.ID;
GO

-- Demonstrating priority of statement processing
-- The order of processing is: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY
SELECT Name, COUNT(*) AS Count
FROM dbo.SampleData
WHERE Age >= 30
GROUP BY Name
HAVING COUNT(*) > 0
ORDER BY Name;
GO

-- Demonstrating the use of aliases
-- Aliases are processed in the SELECT clause
SELECT sd.Name AS PersonName, sd.Age AS PersonAge
FROM dbo.SampleData sd
WHERE sd.Age >= 30
ORDER BY PersonName;
GO
```

### Explanation:
1. **Indexes and Queries**:
   - Equality (`=`) and inequality (`>=`, `<=`) operators are supported by indexes.
   - The `BETWEEN` operator is supported by indexes.
   - The `IN` operator is supported by indexes.
   - String functions (e.g., `LEFT`) and date functions (e.g., `YEAR`) are NOT supported by indexes.
   - The `LIKE` operator is supported by indexes if it does not start with a wildcard (`%`).
   - The `ORDER BY` clause can use indexes for sorting.
   - Multiple conditions in the `WHERE` clause can use multiple indexes.
   - Joins can use indexes on join columns.

2. **Priority of Statement Processing**:
   - The order of processing in SQL Server is: `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `ORDER BY`.
   - Aliases are processed in the `SELECT` clause.

These queries and explanations demonstrate how indexes support various types of queries and the priority of statement processing in SQL Server.
*/


USE TestDB;
GO

-- Create a sample table with indexes
CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT,
    CreatedDate DATETIME
);
GO

-- Create indexes on the table
CREATE NONCLUSTERED INDEX IX_SampleData_Name ON dbo.SampleData(Name);
CREATE NONCLUSTERED INDEX IX_SampleData_Age ON dbo.SampleData(Age);
CREATE NONCLUSTERED INDEX IX_SampleData_CreatedDate ON dbo.SampleData(CreatedDate);
GO

-- Insert sample data
INSERT INTO dbo.SampleData (ID, Name, Age, CreatedDate)
VALUES
    (1, 'Alice', 30, '2023-01-01'),
    (2, 'Bob', 25, '2023-02-01'),
    (3, 'Charlie', 35, '2023-03-01'),
    (4, 'David', 40, '2023-04-01'),
    (5, 'Eve', 28, '2023-05-01');
GO

-- Query using equality operator (=)
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name = 'Alice';
GO

-- Query using inequality operator (>=)
-- This query will use the index on the Age column
SELECT * FROM dbo.SampleData
WHERE Age >= 30;
GO

-- Query using BETWEEN operator
-- This query will use the index on the CreatedDate column
SELECT * FROM dbo.SampleData
WHERE CreatedDate BETWEEN '2023-01-01' AND '2023-03-31';
GO

-- Query using IN operator
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name IN ('Alice', 'Bob');
GO

-- Query using string function (NOT supported by indexes)
-- This query will NOT use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE LEFT(Name, 1) = 'A';
GO

-- Query using date function (NOT supported by indexes)
-- This query will NOT use the index on the CreatedDate column
SELECT * FROM dbo.SampleData
WHERE YEAR(CreatedDate) = 2023;
GO

-- Query using LIKE operator (supported by indexes if not starting with wildcard)
-- This query will use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name LIKE 'A%';
GO

-- Query using LIKE operator with leading wildcard (NOT supported by indexes)
-- This query will NOT use the index on the Name column
SELECT * FROM dbo.SampleData
WHERE Name LIKE '%e';
GO

-- Query using ORDER BY clause
-- This query will use the index on the Age column for sorting
SELECT * FROM dbo.SampleData
ORDER BY Age;
GO

-- Query using WHERE clause with multiple conditions
-- This query will use the indexes on the Age and CreatedDate columns
SELECT * FROM dbo.SampleData
WHERE Age >= 30 AND CreatedDate <= '2023-04-01';
GO

-- Query using JOIN (indexes on join columns will be used)
-- This query will use the index on the ID column of both tables
CREATE TABLE dbo.OtherData
(
    ID INT PRIMARY KEY,
    Description NVARCHAR(100)
);
GO

INSERT INTO dbo.OtherData (ID, Description)
VALUES
    (1, 'Description 1'),
    (2, 'Description 2'),
    (3, 'Description 3'),
    (4, 'Description 4'),
    (5, 'Description 5');
GO

SELECT sd.Name, od.Description
FROM dbo.SampleData sd
JOIN dbo.OtherData od ON sd.ID = od.ID;
GO

-- Demonstrating priority of statement processing
-- The order of processing is: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY
SELECT Name, COUNT(*) AS Count
FROM dbo.SampleData
WHERE Age >= 30
GROUP BY Name
HAVING COUNT(*) > 0
ORDER BY Name;
GO

-- Demonstrating the use of aliases
-- Aliases are processed in the SELECT clause
SELECT sd.Name AS PersonName, sd.Age AS PersonAge
FROM dbo.SampleData sd
WHERE sd.Age >= 30
ORDER BY PersonName;
GO