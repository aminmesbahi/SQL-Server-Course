/**************************************************************
 * SQL Server 2022 Expressions Tutorial
 * Description: This script demonstrates various Transact-SQL expressions:
 *              - CASE expressions (both simple and searched) for data categorization.
 *              - COALESCE to provide default values and concatenate strings.
 *              - NULLIF to avoid division by zero and compare values.
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
  1.1 Create a sample table for demonstration.
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
    Department NVARCHAR(100)
);
GO

/*
  1.2 Insert sample data into the table.
*/
INSERT INTO dbo.SampleData (ID, Name, Age, Salary, Department)
VALUES
    (1, 'Alice', 30, 60000.00, 'HR'),
    (2, 'Bob', 25, NULL, 'IT'),
    (3, 'Charlie', 35, 80000.00, 'Finance'),
    (4, 'David', 40, 90000.00, 'IT'),
    (5, 'Eve', 28, NULL, 'HR');
GO

-------------------------------------------------
-- Region: 2. CASE Expressions
-------------------------------------------------
/*
  2.1 Simple CASE expression to categorize age groups.
*/
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

/*
  2.2 Searched CASE expression to handle NULL values in Salary.
*/
SELECT 
    Name,
    Salary,
    CASE 
        WHEN Salary IS NULL THEN 'Salary not provided'
        ELSE 'Salary provided'
    END AS SalaryStatus
FROM dbo.SampleData;
GO

-------------------------------------------------
-- Region: 3. COALESCE Expressions
-------------------------------------------------
/*
  3.1 Use COALESCE to provide a default value for NULL Salary.
*/
SELECT 
    Name,
    COALESCE(Salary, 50000.00) AS Salary
FROM dbo.SampleData;
GO

/*
  3.2 Use COALESCE to concatenate Name and Department with a fallback.
*/
SELECT 
    COALESCE(Name, 'Unknown') + ' - ' + COALESCE(Department, 'Unknown') AS EmployeeInfo
FROM dbo.SampleData;
GO

-------------------------------------------------
-- Region: 4. NULLIF Expressions
-------------------------------------------------
/*
  4.1 Use NULLIF to avoid division by zero when calculating Salary per Year.
*/
SELECT 
    Name,
    Salary,
    Age,
    Salary / NULLIF(Age, 0) AS SalaryPerYear
FROM dbo.SampleData;
GO

/*
  4.2 Use NULLIF to compare columns and return NULL if they are equal.
*/
SELECT 
    Name,
    Department,
    NULLIF(Department, 'IT') AS NonITDepartment
FROM dbo.SampleData;
GO

-------------------------------------------------
-- Region: 5. Cleanup
-------------------------------------------------
/*
  Clean up the sample table.
*/
DROP TABLE dbo.SampleData;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------