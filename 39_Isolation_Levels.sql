/**************************************************************
 * SQL Server 2022 Isolation Levels Tutorial
 * Description: This script demonstrates how to enable and use 
 *              different transaction isolation levels in SQL Server,
 *              including Snapshot Isolation and other standard levels.
 *              It covers:
 *              - Enabling Snapshot Isolation and Read Committed Snapshot Isolation.
 *              - Example transactions using Snapshot Isolation.
 *              - Examples for Read Uncommitted, Read Committed, Repeatable Read,
 *                Serializable, and Snapshot isolation levels.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Enabling Snapshot Isolation
-------------------------------------------------
/*
  Enable Snapshot Isolation and Read Committed Snapshot Isolation for the database.
  Replace 'YourDatabaseName' with your actual database name.
*/
ALTER DATABASE YourDatabaseName
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

ALTER DATABASE YourDatabaseName
SET READ_COMMITTED_SNAPSHOT ON;
GO

-------------------------------------------------
-- Region: 2. Example Using Snapshot Isolation
-------------------------------------------------
/*
  Snapshot Isolation provides a transaction with a consistent view of the data 
  as it existed at the start of the transaction, reducing blocking and deadlocks.
*/
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Perform operations under snapshot isolation.
SELECT * FROM YourTable
WHERE SomeColumn = 'SomeValue';

COMMIT TRANSACTION;
GO

-------------------------------------------------
-- Region: 3. Isolation Levels Examples
-------------------------------------------------
/*
  SQL Server supports several isolation levels to control the visibility of changes made by other transactions.
*/

/*-------------------------------------------------------------
   3.1 Read Uncommitted:
        Allows dirty reads (reads uncommitted changes).
-------------------------------------------------------------*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;

-- Perform operations (may return uncommitted data)
SELECT * FROM YourTable;

COMMIT TRANSACTION;
GO

/*-------------------------------------------------------------
   3.2 Read Committed:
        Default isolation level. Prevents dirty reads by only reading committed data.
-------------------------------------------------------------*/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

-- Perform operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;
GO

/*-------------------------------------------------------------
   3.3 Repeatable Read:
        Prevents dirty and non-repeatable reads by holding shared locks until the transaction completes.
-------------------------------------------------------------*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

-- Perform operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;
GO

/*-------------------------------------------------------------
   3.4 Serializable:
        The strictest isolation level. Prevents dirty, non-repeatable, and phantom reads by holding range locks.
-------------------------------------------------------------*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

-- Perform operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;
GO

/*-------------------------------------------------------------
   3.5 Snapshot (revisited):
        Provides a consistent view of data as it existed at the start of the transaction.
-------------------------------------------------------------*/
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Perform operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
