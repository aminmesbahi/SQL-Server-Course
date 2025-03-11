/**************************************************************
 * SQL Server 2022 Availability Groups Tutorial
 * Description: This script demonstrates how to work with Availability Groups
 *              in SQL Server 2022. It covers:
 *              - Prerequisites and environment setup
 *              - Creating an availability group
 *              - Adding databases to the availability group
 *              - Configuring synchronous and asynchronous replicas
 *              - Setting up read-only routing
 *              - Performing manual and automatic failovers
 *              - Monitoring availability group health and performance
 *              - Troubleshooting common issues
 **************************************************************/

-------------------------------------------------
-- Region: 1. Environment Prerequisites and Setup
-------------------------------------------------
/*
  Before setting up Availability Groups, ensure the following prerequisites:
  - SQL Server installed as Enterprise or Standard edition (Standard has limitations)
  - Windows Server Failover Clustering (WSFC) configured
  - SQL Server service accounts with proper permissions
  - Network connectivity between all nodes
  - Appropriate disk space for databases and transaction log files
  
  Note: These commands should be run on all nodes that will participate
  in the Availability Group.
*/

-- Enable AlwaysOn Availability Groups feature at the instance level
-- (Requires restart of SQL Server service)
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'hadr enabled', 1;
GO
RECONFIGURE;
GO

-- View current AlwaysOn configuration
SELECT SERVERPROPERTY('IsHadrEnabled') AS [AlwaysOn_Enabled];
GO

-- For demo purposes, create a sample database to be used in AG
USE master;
GO

IF DB_ID('AGDemoDB') IS NOT NULL
BEGIN
    ALTER DATABASE AGDemoDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AGDemoDB;
END
GO

CREATE DATABASE AGDemoDB;
GO

-- Switch to the new database and create a sample table with data
USE AGDemoDB;
GO

CREATE TABLE dbo.Customer
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    CustomerEmail NVARCHAR(200) NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

-- Insert some sample data
INSERT INTO dbo.Customer (CustomerName, CustomerEmail)
VALUES 
    ('John Smith', 'john.smith@example.com'),
    ('Sarah Johnson', 'sarah.johnson@example.com'),
    ('Michael Williams', 'michael.williams@example.com'),
    ('Emily Brown', 'emily.brown@example.com');
GO

-- Switch back to master
USE master;
GO

-- Ensure database is in FULL recovery model (required for AG)
ALTER DATABASE AGDemoDB SET RECOVERY FULL;
GO

-- Take a full backup of the database (required before adding to AG)
BACKUP DATABASE AGDemoDB 
TO DISK = 'C:\Backups\AGDemoDB_Full.bak'
WITH FORMAT, INIT, COMPRESSION;
GO

-- Take a transaction log backup
BACKUP LOG