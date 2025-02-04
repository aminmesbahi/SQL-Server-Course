-------------------------------------
-- Basic Concepts Tutorial
-------------------------------------

USE TestDB;
GO

-- Create a sample table for demonstration
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

-- Insert sample data
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
VALUES
    (1, 'Alice', 30, 60000.00, 'HR', 'Initial note for Alice'),
    (2, 'Bob', 25, NULL, 'IT', 'Initial note for Bob'),
    (3, 'Charlie', 35, 80000.00, 'Finance', 'Initial note for Charlie'),
    (4, 'David', 40, 90000.00, 'IT', 'Initial note for David'),
    (5, 'Eve', 28, NULL, 'HR', 'Initial note for Eve');
GO

-- AT TIME ZONE
-- Convert datetime to a different time zone
SELECT 
    Name,
    GETDATE() AS CurrentTime,
    GETDATE() AT TIME ZONE 'UTC' AS UTCTime,
    GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS PSTTime
FROM dbo.SampleData;
GO

-- OPTION clause
-- Use OPTION clause to specify query hints
SELECT 
    Name,
    Salary
FROM dbo.SampleData
WHERE Department = 'IT'
OPTION (MAXDOP 1);
GO

-- OUTPUT clause
-- Capture the output of an INSERT statement
DECLARE @InsertedData TABLE (ID INT, Name NVARCHAR(100));

INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
OUTPUT INSERTED.ID, INSERTED.Name INTO @InsertedData
VALUES (6, 'Frank', 32, 70000.00, 'Marketing', 'Initial note for Frank');

SELECT * FROM @InsertedData;
GO

-- READTEXT
-- Read a portion of a text column
DECLARE @TextPointer VARBINARY(16);
SELECT @TextPointer = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 1;

READTEXT dbo.SampleData.Notes @TextPointer 0 10;
GO

-- Search condition
-- Use a search condition in a WHERE clause
SELECT 
    Name,
    Salary
FROM dbo.SampleData
WHERE Salary IS NOT NULL AND Department = 'IT';
GO

-- Table value constructor
-- Insert multiple rows using a table value constructor
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department, Notes)
VALUES
    (7, 'Grace', 29, 75000.00, 'Sales', 'Initial note for Grace'),
    (8, 'Hank', 33, 85000.00, 'Sales', 'Initial note for Hank');
GO

-- TOP
-- Select the top N rows
SELECT TOP 3 
    Name,
    Salary
FROM dbo.SampleData
ORDER BY Salary DESC;
GO

-- UPDATETEXT
-- Update a portion of a text column
DECLARE @TextPointer VARBINARY(16);
SELECT @TextPointer = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 1;

UPDATETEXT dbo.SampleData.Notes @TextPointer 0 10 'Updated note for Alice';
GO

-- WITH common_table_expression
-- Use a common table expression (CTE)
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

-- Nested common table expressions in Fabric Warehouse
-- Use nested CTEs
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

-- WRITETEXT
-- Write a new value to a text column
DECLARE @TextPointer VARBINARY(16);
SELECT @TextPointer = TEXTPTR(Notes) FROM dbo.SampleData WHERE ID = 2;

WRITETEXT dbo.SampleData.Notes @TextPointer 'Completely new note for Bob';
GO

-- Cleanup the sample table
DROP TABLE dbo.SampleData;
GO