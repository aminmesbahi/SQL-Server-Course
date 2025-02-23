/**************************************************************
 * SQL Server 2022 Temporal Tables Tutorial
 * Description: This script demonstrates how to create and use 
 *              system-versioned temporal tables in SQL Server 2022.
 *              It covers:
 *              - Creating a temporal table with a history table.
 *              - Inserting, updating, and deleting data to generate history.
 *              - Querying current data, full history, and data as of specific times.
 *              - Disabling and re-enabling system versioning.
 *              - Cleanup instructions.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Cleanup Existing Tables (for re-run purposes)
-------------------------------------------------
IF OBJECT_ID('dbo.EmployeeHistory', 'U') IS NOT NULL  
    DROP TABLE dbo.EmployeeHistory;
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL  
    DROP TABLE dbo.Employee;
GO

-------------------------------------------------
-- Region: 2. Creating the Temporal Table
-------------------------------------------------
/*
  Create the temporal table with system versioning.
  The ValidFrom and ValidTo columns are generated automatically.
*/
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

-------------------------------------------------
-- Region: 3. Inserting and Modifying Data
-------------------------------------------------
/*
  Insert initial data into the temporal table.
*/
INSERT INTO dbo.Employee (EmployeeID, Name, Position, Salary)
VALUES
    (1, 'Alice', 'Manager', 90000.00),
    (2, 'Bob', 'Developer', 75000.00),
    (3, 'Charlie', 'Analyst', 68000.00);
GO

-- Wait for a short period to ensure different timestamps
WAITFOR DELAY '00:00:02';
GO

/*
  Update data: Increase Bob's salary and change his Position.
*/
UPDATE dbo.Employee
SET Salary = 80000.00, Position = 'Senior Developer'
WHERE EmployeeID = 2;
GO

WAITFOR DELAY '00:00:02';
GO

/*
  Another update: Modify Alice's salary.
*/
UPDATE dbo.Employee
SET Salary = 95000.00
WHERE EmployeeID = 1;
GO

/*
  Delete an employee (Charlie) to generate a delete history record.
*/
DELETE FROM dbo.Employee
WHERE EmployeeID = 3;
GO

-------------------------------------------------
-- Region: 4. Querying Temporal Data
-------------------------------------------------
/*
  4.1 Query the current data.
*/
SELECT *
FROM dbo.Employee;
GO

/*
  4.2 Query the full history (current and historical rows).
*/
SELECT * 
FROM dbo.Employee
FOR SYSTEM_TIME ALL;
GO

/*
  4.3 Query as of a specific point in time.
      (Replace @AsOfTime with an appropriate value from your history.)
*/
DECLARE @AsOfTime DATETIME2 = DATEADD(SECOND, -3, SYSUTCDATETIME());
SELECT *
FROM dbo.Employee
FOR SYSTEM_TIME AS OF @AsOfTime;
GO

/*
  4.4 Query changes between two time points.
*/
DECLARE @StartTime DATETIME2 = DATEADD(SECOND, -10, SYSUTCDATETIME());
DECLARE @EndTime   DATETIME2 = SYSUTCDATETIME();

SELECT *
FROM dbo.Employee
FOR SYSTEM_TIME BETWEEN @StartTime AND @EndTime;
GO

-------------------------------------------------
-- Region: 5. Disabling System-Versioning (Optional)
-------------------------------------------------
/*
  To temporarily disable system-versioning:
  ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = OFF);
  
  After modifications, re-enable using:
  ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
*/
GO

-------------------------------------------------
-- Region: 6. Cleanup (Optional)
-------------------------------------------------
/*
  Uncomment the following lines to drop the tables after testing.
*/
-- DROP TABLE dbo.Employee;
-- DROP TABLE dbo.EmployeeHistory;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
