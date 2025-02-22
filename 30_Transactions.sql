/**************************************************************
 * SQL Server 2022 Transactions Tutorial
 * Description: This script demonstrates various transaction 
 *              management techniques in SQL Server, including:
 *              - Basic transactions (BEGIN, COMMIT, ROLLBACK).
 *              - Savepoints within transactions.
 *              - Using different isolation levels.
 *              - Distributed transactions (requires MSDTC and linked servers).
 *              - Nested transactions.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization and Sample Table Setup
-------------------------------------------------
/*
  Use the target database.
*/
USE TestDB;
GO

/*
  Create a sample Accounts table for demonstration.
*/
IF OBJECT_ID(N'dbo.Accounts', N'U') IS NOT NULL
    DROP TABLE dbo.Accounts;
GO

CREATE TABLE dbo.Accounts
(
    AccountID INT PRIMARY KEY,
    AccountHolder NVARCHAR(100),
    Balance DECIMAL(10, 2)
);
GO

/*
  Insert sample data into the Accounts table.
*/
INSERT INTO dbo.Accounts (AccountID, AccountHolder, Balance)
VALUES
    (1, 'Alice', 1000.00),
    (2, 'Bob', 1500.00),
    (3, 'Charlie', 2000.00);
GO

-------------------------------------------------
-- Region: 1. Basic Transaction with COMMIT/ROLLBACK
-------------------------------------------------
/*
  Begin a transaction to simulate a money transfer from Alice to Bob.
  After the updates, check if Alice's balance is non-negative;
  if so, commit the transaction; otherwise, rollback.
*/
BEGIN TRANSACTION;
GO

UPDATE dbo.Accounts
SET Balance = Balance - 200.00
WHERE AccountID = 1;

UPDATE dbo.Accounts
SET Balance = Balance + 200.00
WHERE AccountID = 2;

IF (SELECT Balance FROM dbo.Accounts WHERE AccountID = 1) >= 0
BEGIN
    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    PRINT 'Transaction rolled back due to insufficient funds.';
END
GO

-------------------------------------------------
-- Region: 2. Transaction with SAVEPOINT
-------------------------------------------------
/*
  Begin a new transaction and set a savepoint.
  Attempt a money transfer from Bob to Charlie.
  If Bob's balance remains non-negative, commit; otherwise, rollback to the savepoint.
*/
BEGIN TRANSACTION;
GO

SAVE TRANSACTION SavePoint1;
GO

UPDATE dbo.Accounts
SET Balance = Balance - 500.00
WHERE AccountID = 2;

UPDATE dbo.Accounts
SET Balance = Balance + 500.00
WHERE AccountID = 3;

IF (SELECT Balance FROM dbo.Accounts WHERE AccountID = 2) >= 0
BEGIN
    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully.';
END
ELSE
BEGIN
    ROLLBACK TRANSACTION SavePoint1;
    PRINT 'Transaction rolled back to savepoint due to insufficient funds.';
END
GO

-------------------------------------------------
-- Region: 3. Transaction Isolation Levels
-------------------------------------------------
/*
  Set the isolation level to SERIALIZABLE, which ensures full isolation.
  Begin a transaction, read data with HOLDLOCK, update, and commit.
*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO

BEGIN TRANSACTION;
GO

SELECT * FROM dbo.Accounts WITH (HOLDLOCK);
GO

UPDATE dbo.Accounts
SET Balance = Balance + 100.00
WHERE AccountID = 1;
GO

COMMIT TRANSACTION;
GO

-------------------------------------------------
-- Region: 4. Distributed Transactions (Example)
-------------------------------------------------
/*
  The following is an example of a distributed transaction.
  NOTE: This example requires a linked server setup and MSDTC to be running.
  Uncomment and adjust the code according to your environment.
*/
/*
BEGIN DISTRIBUTED TRANSACTION;

-- Example operation on the local database.
UPDATE dbo.Accounts
SET Balance = Balance - 300.00
WHERE AccountID = 1;

-- Example operation on a linked server (replace 'LinkedServer' with your actual server name).
UPDATE LinkedServer.TestDB.dbo.Accounts
SET Balance = Balance + 300.00
WHERE AccountID = 4;

COMMIT TRANSACTION;
GO
*/

-------------------------------------------------
-- Region: 5. Distributed Transaction with Multiple Databases
-------------------------------------------------
/*
  Example of a distributed transaction across two databases.
  NOTE: This requires both databases (Database1 and Database2) to exist,
  and MSDTC to be enabled.
*/
BEGIN DISTRIBUTED TRANSACTION;
GO

-- Insert sample data into Table1 of Database1.
USE Database1;
INSERT INTO Table1 (Column1) VALUES ('Value1');
GO

-- Insert sample data into Table2 of Database2.
USE Database2;
INSERT INTO Table2 (Column2) VALUES ('Value2');
GO

COMMIT TRANSACTION;
GO

-------------------------------------------------
-- Region: 6. Nested Transactions
-------------------------------------------------
/*
  Begin an outer transaction, perform an operation, then start a nested transaction.
  After nested operations, commit the nested transaction and then the outer transaction.
  Note: SQL Server treats nested transactions as a single transaction,
        but savepoints can be used to simulate nested behavior.
*/
BEGIN TRANSACTION;
GO

-- Outer transaction operation.
INSERT INTO dbo.Accounts (AccountID, AccountHolder, Balance)
VALUES (4, 'David', 90000.00);
GO

SAVE TRANSACTION NestedSave;
GO

-- Nested transaction operation.
INSERT INTO dbo.Accounts (AccountID, AccountHolder, Balance)
VALUES (5, 'Eve', 80000.00);
GO

-- Optionally, rollback to the nested savepoint if needed.
-- ROLLBACK TRANSACTION NestedSave;

COMMIT TRANSACTION;
GO

-------------------------------------------------
-- Region: 7. Cleanup
-------------------------------------------------
/*
  Clean up the sample Accounts table.
*/
DROP TABLE dbo.Accounts;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------