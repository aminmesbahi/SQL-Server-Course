--------------------------------------------------------------------------------
-- Temporal Tables Tutorial for SQL Server 2022
--------------------------------------------------------------------------------

USE TestDB;
GO

-- 1. Drop tables if they already exist (for re-run purposes)
IF OBJECT_ID('dbo.EmployeeHistory', 'U') IS NOT NULL  
    DROP TABLE dbo.EmployeeHistory;
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL  
    DROP TABLE dbo.Employee;
GO

-- 2. Create a system-versioned temporal table with a history table.
CREATE TABLE dbo.Employee
(
    EmployeeID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Position NVARCHAR(100) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo   DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH
(
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory)
);
GO

-- 3. Insert initial data into the temporal table.
INSERT INTO dbo.Employee (EmployeeID, Name, Position, Salary)
VALUES
    (1, 'Alice', 'Manager', 90000.00),
    (2, 'Bob', 'Developer', 75000.00),
    (3, 'Charlie', 'Analyst', 68000.00);
GO

-- Wait for a short period
WAITFOR DELAY '00:00:02';
GO

-- 4. Update data: Increase salary for Bob and change his Position.
UPDATE dbo.Employee
SET Salary = 80000.00, Position = 'Senior Developer'
WHERE EmployeeID = 2;
GO

WAITFOR DELAY '00:00:02';
GO

-- 5. Another update: Modify Alice's salary.
UPDATE dbo.Employee
SET Salary = 95000.00
WHERE EmployeeID = 1;
GO

-- 6. Delete an employee (Charlie)
DELETE FROM dbo.Employee
WHERE EmployeeID = 3;
GO

--------------------------------------------------------------------------------
-- Querying Temporal Data
--------------------------------------------------------------------------------

-- Query the current data
SELECT *
FROM dbo.Employee;
GO

-- Query the full history (current + historical rows)
SELECT * 
FROM dbo.Employee
FOR SYSTEM_TIME ALL;
GO

-- Query as of a specific point in time 
-- (Replace the datetime value with an appropriate value from your history)
DECLARE @AsOfTime DATETIME2 = DATEADD(SECOND, -3, SYSUTCDATETIME());
SELECT *
FROM dbo.Employee
FOR SYSTEM_TIME AS OF @AsOfTime;
GO

-- Query changes between two time points
DECLARE @StartTime DATETIME2 = DATEADD(SECOND, -10, SYSUTCDATETIME());
DECLARE @EndTime   DATETIME2 = SYSUTCDATETIME();

SELECT *
FROM dbo.Employee
FOR SYSTEM_TIME BETWEEN @StartTime AND @EndTime;
GO

--------------------------------------------------------------------------------
-- Disabling System-Versioning (if needed)
--------------------------------------------------------------------------------
-- To disable system-versioning temporarily, run:
-- ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = OFF);
-- (After modifications, you can re-enable it using:)
-- ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
GO

--------------------------------------------------------------------------------
-- Cleanup (Optional)
--------------------------------------------------------------------------------
-- Uncomment the following lines to drop the created tables after testing
-- DROP TABLE dbo.Employee;
-- DROP TABLE dbo.EmployeeHistory;
GO