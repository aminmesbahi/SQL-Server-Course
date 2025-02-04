-------------------------------------
-- Expressions Tutorial
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
    Department NVARCHAR(100)
);
GO

-- Insert sample data
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department)
VALUES
    (1, 'Alice', 30, 60000.00, 'HR'),
    (2, 'Bob', 25, NULL, 'IT'),
    (3, 'Charlie', 35, 80000.00, 'Finance'),
    (4, 'David', 40, 90000.00, 'IT'),
    (5, 'Eve', 28, NULL, 'HR');
GO

-- CASE Expression
-- Example 1: Simple CASE expression to categorize age groups
SELECT 
    Name,
    Age,
    CASE 
        WHEN Age < 30 THEN 'Young'
        WHEN Age BETWEEN 30 AND 39 THEN 'Adult'
        ELSE 'Senior'
    END AS AgeGroup
FROM dbo.SampleData;
GO

-- Example 2: Searched CASE expression to handle NULL values in Salary
SELECT 
    Name,
    Salary,
    CASE 
        WHEN Salary IS NULL THEN 'Salary not provided'
        ELSE 'Salary provided'
    END AS SalaryStatus
FROM dbo.SampleData;
GO

-- COALESCE Expression
-- Example 1: Using COALESCE to provide a default value for NULL Salary
SELECT 
    Name,
    COALESCE(Salary, 50000.00) AS Salary
FROM dbo.SampleData;
GO

-- Example 2: Using COALESCE to concatenate Name and Department with a fallback
SELECT 
    COALESCE(Name, 'Unknown') + ' - ' + COALESCE(Department, 'Unknown') AS EmployeeInfo
FROM dbo.SampleData;
GO

-- NULLIF Expression
-- Example 1: Using NULLIF to avoid division by zero
SELECT 
    Name,
    Salary,
    Age,
    Salary / NULLIF(Age, 0) AS SalaryPerYear
FROM dbo.SampleData;
GO

-- Example 2: Using NULLIF to compare columns and return NULL if they are equal
SELECT 
    Name,
    Department,
    NULLIF(Department, 'IT') AS NonITDepartment
FROM dbo.SampleData;
GO

-- Cleanup the sample table
DROP TABLE dbo.SampleData;
GO