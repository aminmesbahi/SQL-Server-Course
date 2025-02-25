/**************************************************************
 * SQL Server 2022 Temporal Tables Tutorial
 * Description: This script demonstrates how to create and use 
 *              system-versioned temporal tables in SQL Server 2022.
 *              It covers:
 *              - Creating a temporal table with a history table.
 *              - Inserting and updating data to generate historical records.
 *              - Querying current and historical data, including point-in-time 
 *                and period queries.
 *              - Disabling and re-enabling system versioning.
 *              - Cleaning up by dropping tables and the database.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database Setup
-------------------------------------------------
/*
  Create a database for the temporal table example.
*/
CREATE DATABASE TemporalDB;
GO

USE TemporalDB;
GO

-------------------------------------------------
-- Region: 2. Creating the Temporal Table
-------------------------------------------------
/*
  Create a temporal table (Employee) with system versioning enabled.
  The ValidFrom and ValidTo columns are generated automatically,
  and the history table is set to dbo.EmployeeHistory.
*/
CREATE TABLE Employee
(
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Position NVARCHAR(100),
    Salary DECIMAL(10, 2),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo   DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
GO

-------------------------------------------------
-- Region: 3. Data Manipulation
-------------------------------------------------
/*
  Insert initial data into the temporal table.
*/
INSERT INTO Employee (EmployeeID, Name, Position, Salary)
VALUES 
    (1, 'Alice', 'Manager', 60000.00),
    (2, 'Bob', 'Developer', 50000.00),
    (3, 'Charlie', 'Analyst', 55000.00);
GO

/*
  Update data in the temporal table to generate history records.
*/
UPDATE Employee
SET Salary = 65000.00
WHERE EmployeeID = 1;
GO

UPDATE Employee
SET Position = 'Senior Developer', Salary = 55000.00
WHERE EmployeeID = 2;
GO

-------------------------------------------------
-- Region: 4. Querying Temporal Data
-------------------------------------------------
/*
  Query the current (active) data from the temporal table.
*/
SELECT * FROM Employee;
GO

/*
  Query the full history (current and historical rows) from the temporal table.
*/
SELECT * FROM EmployeeHistory;
GO

/*
  Query data as of a specific point in time.
  Replace the datetime value as appropriate based on your data history.
*/
SELECT * FROM Employee
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00.0000000';
GO

/*
  Query data for a specific period using FROM ... TO.
*/
SELECT * FROM Employee
FOR SYSTEM_TIME FROM '2023-01-01T00:00:00.0000000' TO '2023-12-31T23:59:59.9999999';
GO

/*
  Query all changes within a specific period using BETWEEN.
*/
SELECT * FROM Employee
FOR SYSTEM_TIME BETWEEN '2023-01-01T00:00:00.0000000' AND '2023-12-31T23:59:59.9999999';
GO

-------------------------------------------------
-- Region: 5. Deleting Data and Generating History
-------------------------------------------------
/*
  Delete an employee to generate a delete record in the history table.
*/
DELETE FROM Employee
WHERE EmployeeID = 3;
GO

/*
  Query current data after deletion.
*/
SELECT * FROM Employee;
GO

/*
  Query historical data to see the deleted record.
*/
SELECT * FROM EmployeeHistory;
GO

-------------------------------------------------
-- Region: 6. Managing System-Versioning
-------------------------------------------------
/*
  To temporarily disable system versioning (e.g., for maintenance):
*/
ALTER TABLE Employee
SET (SYSTEM_VERSIONING = OFF);
GO

/*
  Re-enable system versioning using the existing history table.
*/
ALTER TABLE Employee
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
GO

-------------------------------------------------
-- Region: 7. Cleanup
-------------------------------------------------
/*
  Drop the temporal table and its associated history table.
*/
DROP TABLE Employee;
DROP TABLE EmployeeHistory;
GO

/*
  Drop the database after testing.
*/
DROP DATABASE TemporalDB;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
