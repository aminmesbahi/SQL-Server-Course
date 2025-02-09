-- Single CTE example
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


-- Nested CTEs
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


-- Recursive CTE example
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




