/**************************************************************
 * SQL Server 2022 CTE Examples Tutorial
 * Description: This script demonstrates various CTE techniques:
 *              - A single CTE for simple filtering.
 *              - Nested CTEs for layered filtering.
 *              - A recursive CTE for hierarchical data traversal.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Single CTE Example
-------------------------------------------------
/*
  This example creates a simple CTE (EmployeeCTE) that retrieves
  employee names and salaries from the dbo.SampleData table where the 
  Department is 'IT', then selects all rows from the CTE.
*/
WITH EmployeeCTE AS
(
    SELECT 
        Name,
        Salary
    FROM dbo.SampleData
    WHERE Department = 'IT'
)
SELECT * 
FROM EmployeeCTE;
GO

-------------------------------------------------
-- Region: 2. Nested CTEs Example
-------------------------------------------------
/*
  This example demonstrates nested CTEs:
  - CTE1 filters employees in the IT department.
  - CTE2 further filters those employees to only include those with 
    a Salary greater than 80000.
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
SELECT * 
FROM CTE2;
GO

-------------------------------------------------
-- Region: 3. Recursive CTE Example
-------------------------------------------------
/*
  This recursive CTE (OrgCTE) is used to traverse a simple organizational hierarchy.
  - The anchor member selects top-level employees (those with no ManagerID).
  - The recursive member joins back to the CTE to retrieve subordinate employees,
    incrementing the hierarchy level.
  Replace dbo.Employees with your actual table name and ensure it has columns:
    EmployeeID, ManagerID, and EmployeeName.
*/
WITH OrgCTE (EmployeeID, ManagerID, EmployeeName, Level)
AS
(
    -- Anchor member: top-level employees (no manager)
    SELECT 
        e.EmployeeID,
        e.ManagerID,
        e.EmployeeName,
        1 AS Level
    FROM dbo.Employees e
    WHERE e.ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive member: employees with a manager
    SELECT 
        e.EmployeeID,
        e.ManagerID,
        e.EmployeeName,
        OrgCTE.Level + 1
    FROM dbo.Employees e
    JOIN OrgCTE ON e.ManagerID = OrgCTE.EmployeeID
)
SELECT 
    EmployeeID, 
    ManagerID, 
    EmployeeName, 
    Level
FROM OrgCTE
ORDER BY Level, EmployeeName;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
