-------------------------------------
-- Rank Functions (Transact-SQL)
-------------------------------------

USE TestDB;
GO

-- Create a sample table
CREATE TABLE dbo.Employees
(
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    Department NVARCHAR(100),
    Salary DECIMAL(10, 2)
);
GO

-- Insert sample data
INSERT INTO dbo.Employees (EmployeeID, EmployeeName, Department, Salary)
VALUES
    (1, 'Alice', 'HR', 60000.00),
    (2, 'Bob', 'IT', 80000.00),
    (3, 'Charlie', 'HR', 70000.00),
    (4, 'David', 'IT', 90000.00),
    (5, 'Eve', 'Finance', 75000.00);
GO

-- RANK() function
-- Assigns a rank to each row within the partition of a result set
SELECT EmployeeID, EmployeeName, Department, Salary,
       RANK() OVER (ORDER BY Salary DESC) AS Rank
FROM dbo.Employees;
GO

-- DENSE_RANK() function
-- Assigns a rank to each row within the partition of a result set, without gaps in rank values
SELECT EmployeeID, EmployeeName, Department, Salary,
       DENSE_RANK() OVER (ORDER BY Salary DESC) AS DenseRank
FROM dbo.Employees;
GO

-- NTILE() function
-- Distributes the rows in an ordered partition into a specified number of groups
SELECT EmployeeID, EmployeeName, Department, Salary,
       NTILE(3) OVER (ORDER BY Salary DESC) AS NTile
FROM dbo.Employees;
GO

-- ROW_NUMBER() function
-- Assigns a unique number to each row within the partition of a result set
SELECT EmployeeID, EmployeeName, Department, Salary,
       ROW_NUMBER() OVER (ORDER BY Salary DESC) AS RowNum
FROM dbo.Employees;
GO

-- RANK() function with PARTITION BY
-- Assigns a rank to each row within the partition of a result set, partitioned by Department
SELECT EmployeeID, EmployeeName, Department, Salary,
       RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS Rank
FROM dbo.Employees;
GO

-- DENSE_RANK() function with PARTITION BY
-- Assigns a rank to each row within the partition of a result set, partitioned by Department, without gaps in rank values
SELECT EmployeeID, EmployeeName, Department, Salary,
       DENSE_RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS DenseRank
FROM dbo.Employees;
GO

-- NTILE() function with PARTITION BY
-- Distributes the rows in an ordered partition into a specified number of groups, partitioned by Department
SELECT EmployeeID, EmployeeName, Department, Salary,
       NTILE(2) OVER (PARTITION BY Department ORDER BY Salary DESC) AS NTile
FROM dbo.Employees;
GO

-- ROW_NUMBER() function with PARTITION BY
-- Assigns a unique number to each row within the partition of a result set, partitioned by Department
SELECT EmployeeID, EmployeeName, Department, Salary,
       ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS RowNum
FROM dbo.Employees;
GO

-- Advanced query using RANK() function with PARTITION BY and filtering
-- Get the top 2 highest salaries in each department
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

-- Advanced query using DENSE_RANK() function with PARTITION BY and filtering
-- Get the top 2 highest salaries in each department without gaps in rank values
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

-- Advanced query using NTILE() function with PARTITION BY and filtering
-- Divide employees into 2 groups within each department based on salary
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

-- Advanced query using ROW_NUMBER() function with PARTITION BY and filtering
-- Get the top 2 highest salaries in each department with unique row numbers
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