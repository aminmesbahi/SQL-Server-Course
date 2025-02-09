-------------------------------------
-- Transactions Tutorial
-------------------------------------

USE TestDB;
GO

-- Create a sample table for demonstration
CREATE TABLE dbo.Accounts
(
    AccountID INT PRIMARY KEY,
    AccountHolder NVARCHAR(100),
    Balance DECIMAL(10, 2)
);
GO

-- Insert sample data
INSERT INTO dbo.Accounts (AccountID, AccountHolder, Balance)
VALUES
    (1, 'Alice', 1000.00),
    (2, 'Bob', 1500.00),
    (3, 'Charlie', 2000.00);
GO

-- Example: BEGIN TRANSACTION, COMMIT TRANSACTION, and ROLLBACK TRANSACTION
BEGIN TRANSACTION;
GO

-- Attempt to transfer money from Alice to Bob
UPDATE dbo.Accounts
SET Balance = Balance - 200.00
WHERE AccountID = 1;

UPDATE dbo.Accounts
SET Balance = Balance + 200.00
WHERE AccountID = 2;

-- Check if the balances are correct
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

-- Example: SAVE TRANSACTION
BEGIN TRANSACTION;
GO

-- Savepoint before making changes
SAVE TRANSACTION SavePoint1;

-- Attempt to transfer money from Bob to Charlie
UPDATE dbo.Accounts
SET Balance = Balance - 500.00
WHERE AccountID = 2;

UPDATE dbo.Accounts
SET Balance = Balance + 500.00
WHERE AccountID = 3;

-- Check if the balances are correct
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

-- Example: Transaction Isolation Levels
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO

BEGIN TRANSACTION;
GO

-- Attempt to read and update data
SELECT * FROM dbo.Accounts WITH (HOLDLOCK);

UPDATE dbo.Accounts
SET Balance = Balance + 100.00
WHERE AccountID = 1;

COMMIT TRANSACTION;
GO

-- Example: BEGIN DISTRIBUTED TRANSACTION
-- Note: This requires a linked server setup and MSDTC (Microsoft Distributed Transaction Coordinator) running.
-- BEGIN DISTRIBUTED TRANSACTION;
-- GO

-- -- Distributed transaction example
-- UPDATE dbo.Accounts
-- SET Balance = Balance - 300.00
-- WHERE AccountID = 1;

-- -- Assume a linked server named 'LinkedServer'
-- UPDATE LinkedServer.TestDB.dbo.Accounts
-- SET Balance = Balance + 300.00
-- WHERE AccountID = 4;

-- COMMIT TRANSACTION;
-- GO

-- Cleanup the sample table
DROP TABLE dbo.Accounts;
GO