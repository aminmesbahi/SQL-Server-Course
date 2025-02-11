-- Create a database for the temporal table example
CREATE DATABASE TemporalDB;
GO

USE TemporalDB;
GO

-- Create a temporal table
CREATE TABLE Employee
(
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Position NVARCHAR(100),
    Salary DECIMAL(10, 2),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) 
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
GO

-- Insert data into the temporal table
INSERT INTO Employee (EmployeeID, Name, Position, Salary)
VALUES (1, 'Alice', 'Manager', 60000.00),
       (2, 'Bob', 'Developer', 50000.00),
       (3, 'Charlie', 'Analyst', 55000.00);
GO


-- Update data in the temporal table
UPDATE Employee
SET Salary = 65000.00
WHERE EmployeeID = 1;
GO

-- Another update
UPDATE Employee
SET Position = 'Senior Developer', Salary = 55000.00
WHERE EmployeeID = 2;
GO


-- Query the current data
SELECT * FROM Employee;
GO

-- Query the historical data
SELECT * FROM EmployeeHistory;
GO

-- Query data as of a specific point in time
SELECT * FROM Employee
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00.0000000';
GO

-- Query data for a specific period
SELECT * FROM Employee
FOR SYSTEM_TIME FROM '2023-01-01T00:00:00.0000000' TO '2023-12-31T23:59:59.9999999';
GO

-- Query all changes within a specific period
SELECT * FROM Employee
FOR SYSTEM_TIME BETWEEN '2023-01-01T00:00:00.0000000' AND '2023-12-31T23:59:59.9999999';
GO


-- Delete data from the temporal table
DELETE FROM Employee
WHERE EmployeeID = 3;
GO

-- Query the current data
SELECT * FROM Employee;
GO

-- Query the historical data
SELECT * FROM EmployeeHistory;
GO


-- Disable system versioning
ALTER TABLE Employee
SET (SYSTEM_VERSIONING = OFF);
GO

-- Enable system versioning
ALTER TABLE Employee
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));
GO


-- Drop the temporal table and its history table
DROP TABLE Employee;
DROP TABLE EmployeeHistory;
GO

-- Drop the database
DROP DATABASE TemporalDB;
GO