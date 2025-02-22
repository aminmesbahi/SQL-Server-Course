/**************************************************************
 * SQL Server 2022 Basic Concepts Tutorial
 * Description: This script demonstrates basic Transact-SQL concepts:
 *              - Table creation and data insertion.
 *              - Date/time conversion using AT TIME ZONE.
 *              - Query hints with the OPTION clause.
 *              - OUTPUT clause for capturing DML results.
 *              - Text data manipulation with READTEXT, UPDATETEXT, and WRITETEXT.
 *              - Search conditions in WHERE clauses.
 *              - Table value constructors.
 *              - TOP clause.
 *              - Common Table Expressions (CTEs) and nested CTEs.
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
-- Region: 1. Creating and Populating Sample Table
-------------------------------------------------
/*
  Create a sample table for demonstration.
*/
IF OBJECT_ID(N'dbo.SampleData', N'U') IS NOT NULL
    DROP TABLE dbo.SampleData;
GO

CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT,
    Salary DECIMAL(10, 2),
    Department NVARCHAR(100),
    Notes TEXT
);
GO

/*
  Insert sample data.
*/
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
VALUES
    (1, 'Alice', 30, 60000.00, 'HR', 'Initial note for Alice'),
    (2, 'Bob', 25, NULL, 'IT', 'Initial note for Bob'),
    (3, 'Charlie', 35, 80000.00, 'Finance', 'Initial note for Charlie'),
    (4, 'David', 40, 90000.00, 'IT', 'Initial note for David'),
    (5, 'Eve', 28, NULL, 'HR', 'Initial note for Eve');
GO

-------------------------------------------------
-- Region: 2. AT TIME ZONE
-------------------------------------------------
/*
  Convert the current date/time to different time zones.
*/
SELECT 
    Name,
    GETDATE() AS CurrentTime,
    GETDATE() AT TIME ZONE 'UTC' AS UTCTime,
    GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS PSTTime
FROM dbo.SampleData;
GO

-------------------------------------------------
-- Region: 3. OPTION Clause
-------------------------------------------------
/*
  Use the OPTION clause to specify a query hint.
*/
SELECT 
    Name,
    Salary
FROM dbo.SampleData
WHERE Department = 'IT'
OPTION (MAXDOP 1);
GO

-------------------------------------------------
-- Region: 4. OUTPUT Clause
-------------------------------------------------
/*
  Capture the output of an INSERT statement using the OUTPUT clause.
*/
DECLARE @InsertedData TABLE (ID INT, Name NVARCHAR(100));

INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
OUTPUT INSERTED.ID, INSERTED.Name INTO @InsertedData
VALUES (6, 'Frank', 32, 70000.00, 'Marketing', 'Initial note for Frank');

SELECT * FROM @InsertedData;
GO

-------------------------------------------------
-- Region: 5. READTEXT
-------------------------------------------------
/*
  Read a portion of the text in the Notes column for the record with ID = 1.
*/
DECLARE @TextPointer VARBINARY(16);
SELECT @TextPointer = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 1;

READTEXT dbo.SampleData.Notes @TextPointer 0 10;
GO

-------------------------------------------------
-- Region: 6. Search Condition
-------------------------------------------------
/*
  Use a search condition in the WHERE clause.
*/
SELECT 
    Name,
    Salary
FROM dbo.SampleData
WHERE Salary IS NOT NULL AND Department = 'IT';
GO

-------------------------------------------------
-- Region: 7. Table Value Constructor
-------------------------------------------------
/*
  Insert multiple rows using a table value constructor.
*/
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
VALUES
    (7, 'Grace', 29, 75000.00, 'Sales', 'Initial note for Grace'),
    (8, 'Hank', 33, 85000.00, 'Sales', 'Initial note for Hank');
GO

-------------------------------------------------
-- Region: 8. TOP Clause
-------------------------------------------------
/*
  Select the top 3 rows based on Salary in descending order.
*/
SELECT TOP 3 
    Name,
    Salary
FROM dbo.SampleData
ORDER BY Salary DESC;
GO

-------------------------------------------------
-- Region: 9. UPDATETEXT
-------------------------------------------------
/*
  Update a portion of the text in the Notes column for record with ID = 1.
  Replace the first 10 characters with 'Updated note for Alice'.
*/
DECLARE @TextPointer2 VARBINARY(16);
SELECT @TextPointer2 = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 1;

UPDATETEXT dbo.SampleData.Notes @TextPointer2 0 10 'Updated note for Alice';
GO

-------------------------------------------------
-- Region: 10. WITH Common Table Expression (CTE)
-------------------------------------------------
/*
  Use a CTE to filter and return IT department employees.
*/
WITH EmployeeCTE AS
(
    SELECT 
        Name,
        Salary
    FROM dbo.SampleData
    WHERE Department = 'IT'
)
SELECT * FROM EmployeeCTE;
GO

-------------------------------------------------
-- Region: 11. Nested Common Table Expressions
-------------------------------------------------
/*
  Use nested CTEs to further filter IT department employees with Salary > 80000.
*/
WITH CTE1 AS
(
    SELECT 
        Name,
        Salary
    FROM dbo.SampleData
    WHERE Department = 'IT'
),
CTE2 AS
(
    SELECT 
        Name,
        Salary
    FROM CTE1
    WHERE Salary > 80000.00
)
SELECT * FROM CTE2;
GO

-------------------------------------------------
-- Region: 12. WRITETEXT
-------------------------------------------------
/*
  Write a new value to the text column for record with ID = 2.
*/
DECLARE @TextPointer3 VARBINARY(16);
SELECT @TextPointer3 = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 2;

WRITETEXT dbo.SampleData.Notes @TextPointer3 'Completely new note for Bob';
GO

-------------------------------------------------
-- Region: 13. Cleanup
-------------------------------------------------
/*
  Clean up the sample table.
*/
DROP TABLE dbo.SampleData;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
