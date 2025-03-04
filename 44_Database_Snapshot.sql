/**************************************************************
 * SQL Server 2022 Database Snapshot Tutorial
 * Description: This script demonstrates how to work with database
 *              snapshots in SQL Server 2022. It covers:
 *              - Creating a database snapshot
 *              - Querying data from a snapshot
 *              - Comparing data between a snapshot and source database
 *              - Reverting to a snapshot (database restore)
 *              - Managing and dropping snapshots
 **************************************************************/

-------------------------------------------------
-- Region: 1. Setup and Initial Database Creation
-------------------------------------------------
USE master;
GO

/*
  Create a test database with sample data.
  We'll create snapshots of this database.
*/
IF DB_ID('TestDB') IS NOT NULL
    DROP DATABASE TestDB;
GO

CREATE DATABASE TestDB;
GO

USE TestDB;
GO

/*
  Create a sample table and insert test data.
*/
CREATE TABLE dbo.Employees
(
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Salary DECIMAL(10, 2)
);
GO

INSERT INTO dbo.Employees (EmployeeID, FirstName, LastName, Salary)
VALUES 
    (1, 'John', 'Doe', 50000.00),
    (2, 'Jane', 'Smith', 60000.00),
    (3, 'Bob', 'Johnson', 55000.00);
GO

-------------------------------------------------
-- Region: 2. Creating Database Snapshots
-------------------------------------------------
USE master;
GO

/*
  Create a database snapshot of TestDB.
  The snapshot is a read-only, point-in-time view of the database.
  Note: You must specify the file path for each database file.
*/
CREATE DATABASE TestDB_Snapshot_1 
ON
(
    NAME = TestDB,
    FILENAME = 'E:\SQL_Data\TestDB_Snapshot_1.ss'
)
AS SNAPSHOT OF TestDB;
GO

/*
  Verify that the snapshot was created successfully.
*/
SELECT name, database_id, source_database_id, create_date, state_desc 
FROM sys.databases
WHERE source_database_id IS NOT NULL;
GO

-------------------------------------------------
-- Region: 3. Querying Data from a Snapshot
-------------------------------------------------
/*
  Query data from the database snapshot.
  Snapshots are read-only, so you can only perform SELECT operations.
*/
USE TestDB_Snapshot_1;
GO

SELECT * FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 4. Modifying Data in the Source Database
-------------------------------------------------
/*
  Make changes to the data in the source database.
  This will create divergence between the source and snapshot.
*/
USE TestDB;
GO

-- Update an existing employee
UPDATE dbo.Employees
SET Salary = 52000.00
WHERE EmployeeID = 1;
GO

-- Add a new employee
INSERT INTO dbo.Employees (EmployeeID, FirstName, LastName, Salary)
VALUES (4, 'Sarah', 'Williams', 65000.00);
GO

-- Delete an employee
DELETE FROM dbo.Employees
WHERE EmployeeID = 3;
GO

-- Verify changes in the source database
SELECT * FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 5. Comparing Source Database and Snapshot
-------------------------------------------------
/*
  Compare data between the source database and the snapshot.
  The snapshot will still show the original data before changes.
*/
-- Query from source database
SELECT 'Source Database' AS Source, * FROM TestDB.dbo.Employees;
GO

-- Query from snapshot
SELECT 'Database Snapshot' AS Source, * FROM TestDB_Snapshot_1.dbo.Employees;
GO

-------------------------------------------------
-- Region: 6. Taking a New Snapshot
-------------------------------------------------
USE master;
GO

/*
  Create a new snapshot to capture the current state of the database.
*/
CREATE DATABASE TestDB_Snapshot_2
ON
(
    NAME = TestDB,
    FILENAME = 'E:\SQL_Data\TestDB_Snapshot_2.ss'
)
AS SNAPSHOT OF TestDB;
GO

/*
  List all available snapshots for TestDB.
*/
SELECT name, database_id, source_database_id, create_date, state_desc 
FROM sys.databases
WHERE source_database_id = DB_ID('TestDB');
GO

-------------------------------------------------
-- Region: 7. Reverting to a Snapshot (Database Restore)
-------------------------------------------------
USE master;
GO

/*
  Restore the database from a snapshot.
  
  Note: 
  1. You must close all connections to both the source database and the snapshot.
  2. The source database must be in SINGLE_USER mode.
  3. After restoration, the snapshot will be automatically dropped.
*/

-- First, set the database to SINGLE_USER mode to close connections
ALTER DATABASE TestDB
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- Restore the database from the snapshot
RESTORE DATABASE TestDB
FROM DATABASE_SNAPSHOT = 'TestDB_Snapshot_1';
GO

-- Set the database back to MULTI_USER mode
ALTER DATABASE TestDB
SET MULTI_USER;
GO

/*
  Verify that the database was restored from the snapshot.
  The data should be back to its original state.
*/
USE TestDB;
GO

SELECT * FROM dbo.Employees;
GO

-------------------------------------------------
-- Region: 8. Managing and Dropping Snapshots
-------------------------------------------------
USE master;
GO

/*
  Drop database snapshots when they are no longer needed.
*/
DROP DATABASE TestDB_Snapshot_2;
GO

/*
  Verify that the snapshot was dropped.
*/
SELECT name, database_id, source_database_id, create_date 
FROM sys.databases
WHERE source_database_id = DB_ID('TestDB');
GO

-------------------------------------------------
-- Region: 9. Multiple Snapshots for Point-in-Time Views
-------------------------------------------------
USE TestDB;
GO

/*
  Let's make additional changes to demonstrate multiple snapshots.
*/
UPDATE dbo.Employees
SET Salary = Salary * 1.1;  -- 10% salary increase
GO

-- Create another snapshot
USE master;
GO

CREATE DATABASE TestDB_Snapshot_3
ON
(
    NAME = TestDB,
    FILENAME = 'E:\SQL_Data\TestDB_Snapshot_3.ss'
)
AS SNAPSHOT OF TestDB;
GO

/*
  View available snapshots with their creation dates.
*/
SELECT name, create_date 
FROM sys.databases
WHERE source_database_id = DB_ID('TestDB')
ORDER BY create_date;
GO

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
USE master;
GO

/*
  Clean up all resources by dropping snapshots and the test database.
*/
-- Uncomment the following lines to clean up resources:
/*
DROP DATABASE TestDB_Snapshot_1;
GO

DROP DATABASE TestDB_Snapshot_3;
GO

DROP DATABASE TestDB;
GO
*/