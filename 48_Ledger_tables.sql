/**************************************************************
 * SQL Server 2022 Ledger Tables Tutorial
 * Description: This script demonstrates how to work with Ledger Tables
 *              in SQL Server 2022. It covers:
 *              - Creating updatable and append-only ledger tables
 *              - Querying ledger history and changes
 *              - Verifying ledger data integrity
 *              - Using ledger views to track history
 *              - Implementing blockchain-like immutability
 *              - Practical use cases and scenarios
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database Setup for Ledger Tables
-------------------------------------------------
USE master;
GO

/*
  Drop the database if it exists for clean testing.
*/
IF DB_ID('LedgerDemo') IS NOT NULL
BEGIN
    ALTER DATABASE LedgerDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LedgerDemo;
END
GO

/*
  Create a new database with ledger support.
  SQL Server 2022 supports ledger tables without special configuration.
*/
CREATE DATABASE LedgerDemo;
GO

USE LedgerDemo;
GO

-------------------------------------------------
-- Region: 2. Creating Updatable Ledger Tables
-------------------------------------------------
/*
  Create a simple updatable ledger table.
  Updatable ledger tables allow data modifications but maintain a history
  of all changes for tamper-evidence.
*/
CREATE TABLE dbo.Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL,
    DepartmentID INT NOT NULL,
    HireDate DATE NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
)
WITH (LEDGER = ON);
GO

/*
  Create another updatable ledger table with a simple schema and foreign key.
*/
CREATE TABLE dbo.Departments
(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL,
    ManagerID INT NULL,
    Budget DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
)
WITH (LEDGER = ON);
GO

/*
  Add a foreign key constraint between the tables.
  Ledger tables support standard constraints.
*/
ALTER TABLE dbo.Employees
ADD CONSTRAINT FK_Employees_Departments
FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments(DepartmentID);
GO

-------------------------------------------------
-- Region: 3. Creating Append-Only Ledger Tables
-------------------------------------------------
/*
  Create an append-only ledger table.
  Append-only ledger tables only allow inserts, providing
  even stronger tamper-evidence guarantees.
*/
CREATE TABLE dbo.EmployeeSalaryHistory
(
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    OldSalary DECIMAL(10, 2) NOT NULL,
    NewSalary DECIMAL(10, 2) NOT NULL,
    ChangeReason NVARCHAR(100) NOT NULL,
    ChangeDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ChangedBy NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER
)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

/*
  Add a foreign key to the append-only ledger table.
*/
ALTER TABLE dbo.EmployeeSalaryHistory
ADD CONSTRAINT FK_SalaryHistory_Employees
FOREIGN KEY (EmployeeID) REFERENCES dbo.Employees(EmployeeID);
GO

-------------------------------------------------
-- Region: 4. Inserting and Modifying Data
-------------------------------------------------
/*
  Insert data into the Departments ledger table.
*/
INSERT INTO dbo.Departments (DepartmentName, Budget)
VALUES 
    ('Executive', 500000.00),
    ('Finance', 300000.00),
    ('IT', 450000.00),
    ('Marketing', 350000.00),
    ('Human Resources', 200000.00);
GO

/*
  Insert data into the Employees ledger table.
*/
INSERT INTO dbo.Employees (FirstName, LastName, Salary, DepartmentID, HireDate)
VALUES 
    ('John', 'Smith', 95000.00, 1, '2018-01-15'),
    ('Sarah', 'Johnson', 78000.00, 2, '2019-03-22'),
    ('Michael', 'Williams', 85000.00, 3, '2017-11-10'),
    ('Jessica', 'Brown', 72000.00, 4, '2020-02-05'),
    ('David', 'Miller', 65000.00, 5, '2021-06-18');
GO

/*
  Update data in the updatable ledger table.
  Ledger will automatically track these changes.
*/
UPDATE dbo.Employees
SET Salary = 98000.00,
    ModifiedDate = SYSUTCDATETIME()
WHERE EmployeeID = 1;
GO

/*
  Record the salary change in the append-only ledger table.
*/
INSERT INTO dbo.EmployeeSalaryHistory (EmployeeID, OldSalary, NewSalary, ChangeReason)
VALUES (1, 95000.00, 98000.00, 'Annual performance review');
GO

/*
  Make additional changes to demonstrate ledger history.
*/
UPDATE dbo.Departments
SET Budget = 525000.00,
    ModifiedDate = SYSUTCDATETIME()
WHERE DepartmentID = 1;
GO

UPDATE dbo.Employees
SET DepartmentID = 3,
    ModifiedDate = SYSUTCDATETIME()
WHERE EmployeeID = 5;
GO

/*
  Delete a record from the updatable ledger table.
  Even deletions are tracked in the ledger.
*/
DELETE FROM dbo.Employees
WHERE EmployeeID = 4;
GO

-------------------------------------------------
-- Region: 5. Querying Ledger History
-------------------------------------------------
/*
  Query the system-generated ledger history table to view all changes.
  Every ledger table has a corresponding history table.
*/
SELECT * FROM dbo.Employees_Ledger;
GO

SELECT * FROM dbo.Departments_Ledger;
GO

SELECT * FROM dbo.EmployeeSalaryHistory_Ledger;
GO

/*
  Query specific changes to a record over time.
  This is useful for auditing and compliance purposes.
*/
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.Salary,
    e.DepartmentID,
    e.transaction_id,
    e.operation_type,
    e.operation_type_desc,
    e.commit_time
FROM dbo.Employees FOR SYSTEM_TIME ALL AS e
WHERE e.EmployeeID = 1
ORDER BY e.commit_time;
GO

/*
  Use temporal-like syntax to query ledger tables for point-in-time analysis.
*/
-- Get all employees as they existed at a specific point in time
SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2023-03-15T12:00:00';
GO

-------------------------------------------------
-- Region: 6. Verifying Ledger Data Integrity
-------------------------------------------------
/*
  Generate a digest of the ledger database to verify integrity.
  This returns cryptographic proof that the ledger hasn't been tampered with.
*/
SELECT * FROM sys.generate_database_ledger_digest(
    DB_NAME()
);
GO

/*
  Query the ledger database digest state for current verification status.
*/
SELECT * FROM sys.database_ledger_digest_states;
GO

/*
  Query block changes in the ledger.
  Each block represents a group of transactions.
*/
SELECT * FROM sys.database_ledger_blocks;
GO

/*
  Query individual transactions in the ledger.
*/
SELECT * FROM sys.database_ledger_transactions;
GO

-------------------------------------------------
-- Region: 7. Working with Ledger Views
-------------------------------------------------
/*
  Create a view to simplify querying the employees ledger history.
  Views can help provide cleaner interfaces to ledger data.
*/
CREATE VIEW dbo.EmployeeChangesView
AS
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.Salary,
    e.DepartmentID,
    d.DepartmentName,
    e.ledger_start_transaction_id,
    e.ledger_end_transaction_id,
    e.ledger_start_sequence_number,
    e.ledger_operation_type_desc,
    e.ledger_transaction_id,
    CASE 
        WHEN e.ledger_operation_type = 1 THEN 'INSERT'
        WHEN e.ledger_operation_type = 2 THEN 'DELETE'
        WHEN e.ledger_operation_type = 3 THEN 'UPDATE (Before)'
        WHEN e.ledger_operation_type = 4 THEN 'UPDATE (After)'
        ELSE 'Unknown'
    END AS OperationType,
    e.ledger_commit_time
FROM dbo.Employees_Ledger e
LEFT JOIN dbo.Departments d ON e.DepartmentID = d.DepartmentID
ORDER BY e.ledger_commit_time;
GO

/*
  Query the view to see employee changes in a more user-friendly format.
*/
SELECT * FROM dbo.EmployeeChangesView;
GO

-------------------------------------------------
-- Region: 8. Practical Examples with Ledger Tables
-------------------------------------------------
/*
  Example 1: Implementing an audit trail with append-only ledger table.
  Shows how to create a comprehensive audit system.
*/
CREATE TABLE dbo.AuditLog
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(128) NOT NULL,
    RecordID INT NOT NULL,
    Action NVARCHAR(20) NOT NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    ChangedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

/*
  Create triggers to automatically populate the audit log.
  This shows how ledger tables can be integrated with regular SQL features.
*/
CREATE TRIGGER trg_Employees_AuditChanges
ON dbo.Employees
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(20);
    
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
        
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO dbo.AuditLog (TableName, RecordID, Action, NewValues)
        SELECT 
            'Employees',
            i.EmployeeID,
            'INSERT',
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM inserted i;
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        INSERT INTO dbo.AuditLog (TableName, RecordID, Action, OldValues, NewValues)
        SELECT 
            'Employees',
            i.EmployeeID,
            'UPDATE',
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM inserted i
        JOIN deleted d ON i.EmployeeID = d.EmployeeID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.AuditLog (TableName, RecordID, Action, OldValues)
        SELECT 
            'Employees',
            d.EmployeeID,
            'DELETE',
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
        FROM deleted d;
    END
END;
GO

/*
  Example 2: Using ledger tables for regulatory compliance.
  This simulates a financial transaction logging system.
*/
CREATE TABLE dbo.FinancialTransactions
(
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ProcessedBy NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    Notes NVARCHAR(500) NULL
)
WITH (LEDGER = ON);
GO

/*
  Insert sample financial transactions.
*/
INSERT INTO dbo.FinancialTransactions (AccountID, TransactionType, Amount, Notes)
VALUES 
    (1001, 'DEPOSIT', 5000.00, 'Initial deposit'),
    (1002, 'DEPOSIT', 3500.00, 'Initial deposit'),
    (1001, 'WITHDRAWAL', 1500.00, 'ATM withdrawal'),
    (1003, 'DEPOSIT', 10000.00, 'Account opening');
GO

/*
  Example 3: Data lineage tracking for sensitive operations.
  Shows how append-only ledger tables can track critical actions.
*/
CREATE TABLE dbo.GDPR_DataAccessLog
(
    AccessID INT IDENTITY(1,1) PRIMARY KEY,
    DataSubjectID INT NOT NULL,
    AccessedBy NVARCHAR(128) NOT NULL,
    AccessReason NVARCHAR(500) NOT NULL,
    AccessDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    DataAccessed NVARCHAR(MAX) NOT NULL,
    ClientIP NVARCHAR(50) NOT NULL DEFAULT '0.0.0.0',
    AccessApprovedBy NVARCHAR(128) NULL
)
WITH (LEDGER = ON (APPEND_ONLY = ON));
GO

/*
  Insert sample data access events.
*/
INSERT INTO dbo.GDPR_DataAccessLog 
(DataSubjectID, AccessedBy, AccessReason, DataAccessed, ClientIP, AccessApprovedBy)
VALUES 
    (12345, 'analyst1', 'Customer service inquiry', 'Contact information', '192.168.1.100', 'supervisor1'),
    (12345, 'analyst2', 'Fraud investigation', 'Transaction history', '192.168.1.102', 'supervisor2'),
    (67890, 'analyst1', 'Data correction request', 'Full profile', '192.168.1.100', 'supervisor1');
GO

-------------------------------------------------
-- Region: 9. Performance and Best Practices
-------------------------------------------------
/*
  Query to view ledger space usage to understand storage impact.
*/
SELECT 
    t.name AS TableName,
    p.rows AS RowCount,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name LIKE '%\_Ledger' ESCAPE '\'
   OR t.name IN ('Employees', 'Departments', 'EmployeeSalaryHistory', 'AuditLog', 
                 'FinancialTransactions', 'GDPR_DataAccessLog')
GROUP BY t.name, p.rows
ORDER BY t.name;
GO

/*
  Best practice: Create indexes on ledger history tables for performance.
*/
CREATE INDEX IX_Employees_Ledger_EmployeeID_CommitTime 
ON dbo.Employees_Ledger(EmployeeID, ledger_commit_time);
GO

CREATE INDEX IX_FinancialTransactions_Ledger_AccountID_CommitTime 
ON dbo.FinancialTransactions_Ledger(AccountID, ledger_commit_time);
GO

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
USE master;
GO

/*
  Clean up resources by dropping the test database.
*/
-- Uncomment the following line to clean up resources:
-- DROP DATABASE LedgerDemo;
-- GO

/*
  Note: When working with production ledger tables, consider retention policies
  and backup strategies that preserve the full ledger history for
  regulatory compliance.
*/