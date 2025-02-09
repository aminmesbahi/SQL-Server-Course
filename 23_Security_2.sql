-------------------------------------
-- Audit (DDL, DML), Change Tracking, CDC
-------------------------------------

USE TestDB;
GO

-- Create a sample table for auditing
CREATE TABLE dbo.AuditTest
(
    AuditID INT IDENTITY PRIMARY KEY,
    Data NVARCHAR(100)
);
GO

-- DDL Audit
-- Create an audit and audit specification for DDL changes
CREATE SERVER AUDIT DDL_Audit
TO FILE (FILEPATH = 'C:\AuditLogs\');
GO

CREATE DATABASE AUDIT SPECIFICATION DDL_AuditSpec
FOR SERVER AUDIT DDL_Audit
ADD (SCHEMA_OBJECT_CHANGE_GROUP);
GO

-- Enable the audit and audit specification
ALTER SERVER AUDIT DDL_Audit WITH (STATE = ON);
GO

ALTER DATABASE AUDIT SPECIFICATION DDL_AuditSpec WITH (STATE = ON);
GO

-- Test DDL Audit
-- Create a table to trigger the audit
CREATE TABLE dbo.TestTable
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100)
);
GO

-- Drop the table to trigger the audit
DROP TABLE dbo.TestTable;
GO

-- Disable the audit and audit specification
ALTER DATABASE AUDIT SPECIFICATION DDL_AuditSpec WITH (STATE = OFF);
GO

ALTER SERVER AUDIT DDL_Audit WITH (STATE = OFF);
GO

-- Drop the audit and audit specification
DROP DATABASE AUDIT SPECIFICATION DDL_AuditSpec;
GO

DROP SERVER AUDIT DDL_Audit;
GO

-- DML Audit
-- Create an audit and audit specification for DML changes
CREATE SERVER AUDIT DML_Audit
TO FILE (FILEPATH = 'C:\AuditLogs\');
GO

CREATE DATABASE AUDIT SPECIFICATION DML_AuditSpec
FOR SERVER AUDIT DML_Audit
ADD (SCHEMA_OBJECT_ACCESS_GROUP);
GO

-- Enable the audit and audit specification
ALTER SERVER AUDIT DML_Audit WITH (STATE = ON);
GO

ALTER DATABASE AUDIT SPECIFICATION DML_AuditSpec WITH (STATE = ON);
GO

-- Test DML Audit
-- Insert data to trigger the audit
INSERT INTO dbo.AuditTest (Data)
VALUES ('Test Data 1');
GO

-- Update data to trigger the audit
UPDATE dbo.AuditTest
SET Data = 'Updated Data 1'
WHERE AuditID = 1;
GO

-- Delete data to trigger the audit
DELETE FROM dbo.AuditTest
WHERE AuditID = 1;
GO

-- Disable the audit and audit specification
ALTER DATABASE AUDIT SPECIFICATION DML_AuditSpec WITH (STATE = OFF);
GO

ALTER SERVER AUDIT DML_Audit WITH (STATE = OFF);
GO

-- Drop the audit and audit specification
DROP DATABASE AUDIT SPECIFICATION DML_AuditSpec;
GO

DROP SERVER AUDIT DML_Audit;
GO

-- Change Tracking
-- Enable change tracking for the database
ALTER DATABASE TestDB
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);
GO

-- Enable change tracking for the table
ALTER TABLE dbo.AuditTest
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);
GO

-- Test Change Tracking
-- Insert data
INSERT INTO dbo.AuditTest (Data)
VALUES ('Change Tracking Data 1');
GO

-- Update data
UPDATE dbo.AuditTest
SET Data = 'Updated Change Tracking Data 1'
WHERE AuditID = 2;
GO

-- Delete data
DELETE FROM dbo.AuditTest
WHERE AuditID = 2;
GO

-- Query change tracking information
SELECT * FROM CHANGETABLE(CHANGES dbo.AuditTest, 0) AS CT;
GO

-- Disable change tracking for the table
ALTER TABLE dbo.AuditTest
DISABLE CHANGE_TRACKING;
GO

-- Disable change tracking for the database
ALTER DATABASE TestDB
SET CHANGE_TRACKING = OFF;
GO

-- Change Data Capture (CDC)
-- Enable CDC for the database
EXEC sys.sp_cdc_enable_db;
GO

-- Enable CDC for the table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'AuditTest',
    @role_name = NULL;
GO

-- Test CDC
-- Insert data
INSERT INTO dbo.AuditTest (Data)
VALUES ('CDC Data 1');
GO

-- Update data
UPDATE dbo.AuditTest
SET Data = 'Updated CDC Data 1'
WHERE AuditID = 3;
GO

-- Delete data
DELETE FROM dbo.AuditTest
WHERE AuditID = 3;
GO

-- Query CDC information
SELECT * FROM cdc.dbo_AuditTest_CT;
GO

-- Disable CDC for the table
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'AuditTest',
    @capture_instance = N'dbo_AuditTest';
GO

-- Disable CDC for the database
EXEC sys.sp_cdc_disable_db;
GO

-- Clean up the sample table
DROP TABLE dbo.AuditTest;
GO