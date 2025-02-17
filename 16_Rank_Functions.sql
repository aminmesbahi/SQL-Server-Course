/**************************************************************
 * SQL Server 2022 Rank Functions Tutorial
 * Description: This script demonstrates the use of ranking 
 *              functions (RANK, DENSE_RANK, NTILE, ROW_NUMBER) 
 *              in Transact-SQL. It covers:
 *              - Basic ranking functions.
 *              - Ranking functions with PARTITION BY.
 *              - Advanced queries using Common Table Expressions (CTEs)
 *                for filtering top-N results within partitions.
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
-- Region: 1. Creating the Employees Table and Inserting Sample Data
-------------------------------------------------
/*
  1.1 Drop the Employees table if it already exists.
*/
IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
    DROP TABLE dbo.Employees;
GO

/*
  1.2 Create the Employees table with sample columns.
*/
CREATE TABLE dbo.Employees
(
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    Department NVARCHAR(100),
    Salary DECIMAL(10, 2)
);
GO

/*
  1.3 Insert sample employee data.
*/
INSERT INTO dbo.Employees (EmployeeID, EmployeeName, Department, Salary)
VALUES
    (1, 'Alice', 'HR', 60000.00),
    (2, 'Bob', 'IT', 80000.00),
    (3, 'Charlie', 'HR', 70000.00),
    (4, 'David', 'IT', 90000.00),
    (5, 'Eve', 'Finance', 75000.00);
GO

-------------------------------------------------
-- Region: 2. Basic Ranking Functions (Without PARTITION BY)
-------------------------------------------------
/*
  2.1 RANK() - Assigns a rank to each row ordered by Salary in descending order.
       Ties receive the same rank, with gaps in ranking.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       RANK() OVER (ORDER BY Salary DESC) AS Rank
FROM dbo.Employees;
GO

/*
  2.2 DENSE_RANK() - Similar to RANK() but without gaps in ranking.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       DENSE_RANK() OVER (ORDER BY Salary DESC) AS DenseRank
FROM dbo.Employees;
GO

/*
  2.3 NTILE() - Distributes rows into a specified number of groups.
       In this example, employees are divided into 3 groups based on salary.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       NTILE(3) OVER (ORDER BY Salary DESC) AS NTile
FROM dbo.Employees;
GO

/*
  2.4 ROW_NUMBER() - Assigns a unique sequential number to each row.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       ROW_NUMBER() OVER (ORDER BY Salary DESC) AS RowNum
FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 3. Ranking Functions with PARTITION BY
-------------------------------------------------
/*
  3.1 RANK() with PARTITION BY Department - Ranks employees within each department.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS Rank
FROM dbo.Employees;
GO

/*
  3.2 DENSE_RANK() with PARTITION BY Department - Dense ranking within each department.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       DENSE_RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS DenseRank
FROM dbo.Employees;
GO

/*
  3.3 NTILE() with PARTITION BY Department - Divides employees in each department into 2 groups based on salary.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       NTILE(2) OVER (PARTITION BY Department ORDER BY Salary DESC) AS NTile
FROM dbo.Employees;
GO

/*
  3.4 ROW_NUMBER() with PARTITION BY Department - Assigns a unique sequential number within each department.
*/
SELECT EmployeeID, EmployeeName, Department, Salary,
       ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS RowNum
FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 4. Advanced Ranking Queries with Filtering (CTEs)
-------------------------------------------------
/*
  4.1 Advanced query using RANK() with PARTITION BY
       Retrieve the top 2 highest salaries in each department.
*/
WITH RankedEmployees AS
(
    SELECT EmployeeID, EmployeeName, Department, Salary,
           RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS Rank
    FROM dbo.Employees
)
SELECT EmployeeID, EmployeeName, Department, Salary, Rank
FROM RankedEmployees
WHERE Rank <= 2;
GO

/*
  4.2 Advanced query using DENSE_RANK() with PARTITION BY
       Retrieve the top 2 highest salaries in each department without gaps.
*/
WITH DenseRankedEmployees AS
(
    SELECT EmployeeID, EmployeeName, Department, Salary,
           DENSE_RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS DenseRank
    FROM dbo.Employees
)
SELECT EmployeeID, EmployeeName, Department, Salary, DenseRank
FROM DenseRankedEmployees
WHERE DenseRank <= 2;
GO

/*
  4.3 Advanced query using NTILE() with PARTITION BY
       Divide employees within each department into 2 groups and select one group.
*/
WITH NTileEmployees AS
(
    SELECT EmployeeID, EmployeeName, Department, Salary,
           NTILE(2) OVER (PARTITION BY Department ORDER BY Salary DESC) AS NTile
    FROM dbo.Employees
)
SELECT EmployeeID, EmployeeName, Department, Salary, NTile
FROM NTileEmployees
WHERE NTile = 1;
GO

/*
  4.4 Advanced query using ROW_NUMBER() with PARTITION BY
       Retrieve the top 2 highest salaries in each department with unique row numbers.
*/
WITH RowNumberedEmployees AS
(
    SELECT EmployeeID, EmployeeName, Department, Salary,
           ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS RowNum
    FROM dbo.Employees
)
SELECT EmployeeID, EmployeeName, Department, Salary, RowNum
FROM RowNumberedEmployees
WHERE RowNum <= 2;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
