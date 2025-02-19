/**************************************************************
 * SQL Server 2022 Audit, Change Tracking, and CDC Tutorial
 * Description: This script demonstrates how to implement and test:
 *              - DDL auditing for schema changes.
 *              - DML auditing for data modifications.
 *              - Change Tracking for table-level data changes.
 *              - Change Data Capture (CDC) for detailed change logging.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Use the TestDB database.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating a Sample Table for Auditing
-------------------------------------------------
/*
  Create a simple table (AuditTest) to log test data.
*/
IF OBJECT_ID(N'dbo.AuditTest', N'U') IS NOT NULL
    DROP TABLE dbo.AuditTest;
GO

CREATE TABLE dbo.AuditTest
(
    AuditID INT IDENTITY PRIMARY KEY,
    Data NVARCHAR(100)
);
GO

-------------------------------------------------
-- Region: 2. DDL Audit
-------------------------------------------------
/*
  2.1 Create a server audit to capture DDL events, writing logs to a file.
*/
CREATE SERVER AUDIT DDL_Audit
TO FILE (FILEPATH = 'C:\AuditLogs\');
GO

/*
  2.2 Create a database audit specification for DDL changes (schema object changes).
*/
CREATE DATABASE AUDIT SPECIFICATION DDL_AuditSpec
FOR SERVER AUDIT DDL_Audit
ADD (SCHEMA_OBJECT_CHANGE_GROUP);
GO

/*
  2.3 Enable the audit and the audit specification.
*/
ALTER SERVER AUDIT DDL_Audit WITH (STATE = ON);
GO

ALTER DATABASE AUDIT SPECIFICATION DDL_AuditSpec WITH (STATE = ON);
GO

/*
  2.4 Test DDL Audit:
       - Create a table (dbo.TestTable) to trigger DDL events.
       - Then drop it.
*/
CREATE TABLE dbo.TestTable
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100)
);
GO

DROP TABLE dbo.TestTable;
GO

/*
  2.5 Disable and drop DDL auditing objects.
*/
ALTER DATABASE AUDIT SPECIFICATION DDL_AuditSpec WITH (STATE = OFF);
GO

ALTER SERVER AUDIT DDL_Audit WITH (STATE = OFF);
GO

DROP DATABASE AUDIT SPECIFICATION DDL_AuditSpec;
GO

DROP SERVER AUDIT DDL_Audit;
GO

-------------------------------------------------
-- Region: 3. DML Audit
-------------------------------------------------
/*
  3.1 Create a server audit to capture DML events.
*/
CREATE SERVER AUDIT DML_Audit
TO FILE (FILEPATH = 'C:\AuditLogs\');
GO

/*
  3.2 Create a database audit specification for DML (access) changes.
*/
CREATE DATABASE AUDIT SPECIFICATION DML_AuditSpec
FOR SERVER AUDIT DML_Audit
ADD (SCHEMA_OBJECT_ACCESS_GROUP);
GO

/*
  3.3 Enable the DML audit and its specification.
*/
ALTER SERVER AUDIT DML_Audit WITH (STATE = ON);
GO

ALTER DATABASE AUDIT SPECIFICATION DML_AuditSpec WITH (STATE = ON);
GO

/*
  3.4 Test DML Audit by performing DML operations on dbo.AuditTest.
*/
-- Insert a row
INSERT INTO dbo.AuditTest (Data)
VALUES ('Test Data 1');
GO

-- Update the inserted row
UPDATE dbo.AuditTest
SET Data = 'Updated Data 1'
WHERE AuditID = 1;
GO

-- Delete the updated row
DELETE FROM dbo.AuditTest
WHERE AuditID = 1;
GO

/*
  3.5 Disable and drop DML auditing objects.
*/
ALTER DATABASE AUDIT SPECIFICATION DML_AuditSpec WITH (STATE = OFF);
GO

ALTER SERVER AUDIT DML_Audit WITH (STATE = OFF);
GO

DROP DATABASE AUDIT SPECIFICATION DML_AuditSpec;
GO

DROP SERVER AUDIT DML_Audit;
GO

-------------------------------------------------
-- Region: 4. Change Tracking
-------------------------------------------------
/*
  4.1 Enable change tracking at the database level.
       Set retention to 2 DAYS with auto cleanup.
*/
ALTER DATABASE TestDB
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);
GO

/*
  4.2 Enable change tracking for the dbo.AuditTest table.
       TRACK_COLUMNS_UPDATED = ON for detailed column changes.
*/
ALTER TABLE dbo.AuditTest
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);
GO

/*
  4.3 Test Change Tracking:
       - Insert, update, and delete data in dbo.AuditTest.
*/
-- Insert a row
INSERT INTO dbo.AuditTest (Data)
VALUES ('Change Tracking Data 1');
GO

-- Update the row
UPDATE dbo.AuditTest
SET Data = 'Updated Change Tracking Data 1'
WHERE AuditID = 2;
GO

-- Delete the row
DELETE FROM dbo.AuditTest
WHERE AuditID = 2;
GO

/*
  4.4 Query change tracking information.
*/
SELECT * FROM CHANGETABLE(CHANGES dbo.AuditTest, 0) AS CT;
GO

/*
  4.5 Disable change tracking for the table and the database.
*/
ALTER TABLE dbo.AuditTest
DISABLE CHANGE_TRACKING;
GO

ALTER DATABASE TestDB
SET CHANGE_TRACKING = OFF;
GO

-------------------------------------------------
-- Region: 5. Change Data Capture (CDC)
-------------------------------------------------
/*
  5.1 Enable CDC for the database.
*/
EXEC sys.sp_cdc_enable_db;
GO

/*
  5.2 Enable CDC for the dbo.AuditTest table.
       No specific role is required (set role_name = NULL).
*/
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'AuditTest',
    @role_name = NULL;
GO

/*
  5.3 Test CDC:
       - Insert, update, and delete data in dbo.AuditTest.
*/
-- Insert a row
INSERT INTO dbo.AuditTest (Data)
VALUES ('CDC Data 1');
GO

-- Update the row
UPDATE dbo.AuditTest
SET Data = 'Updated CDC Data 1'
WHERE AuditID = 3;
GO

-- Delete the row
DELETE FROM dbo.AuditTest
WHERE AuditID = 3;
GO

/*
  5.4 Query CDC information from the change table.
*/
SELECT * FROM cdc.dbo_AuditTest_CT;
GO

/*
  5.5 Disable CDC for the table and the database.
*/
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'AuditTest',
    @capture_instance = N'dbo_AuditTest';
GO

EXEC sys.sp_cdc_disable_db;
GO

-------------------------------------------------
-- Region: 6. Cleanup
-------------------------------------------------
/*
  Clean up the sample table.
*/
DROP TABLE dbo.AuditTest;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
