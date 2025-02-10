-- Enable Snapshot Isolation
ALTER DATABASE YourDatabaseName
SET ALLOW_SNAPSHOT_ISOLATION ON;

-- Enable Read Committed Snapshot Isolation
ALTER DATABASE YourDatabaseName
SET READ_COMMITTED_SNAPSHOT ON;

-- Example of using Snapshot Isolation
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable WHERE SomeColumn = 'SomeValue';

COMMIT TRANSACTION;




-- Snapshot Isolation and Its Use Cases
-- Snapshot Isolation allows transactions to work with a consistent snapshot of the data as it existed at the start of the transaction. This can help reduce blocking and deadlocks.


-- Enable Snapshot Isolation
ALTER DATABASE YourDatabaseName
SET ALLOW_SNAPSHOT_ISOLATION ON;

-- Enable Read Committed Snapshot Isolation
ALTER DATABASE YourDatabaseName
SET READ_COMMITTED_SNAPSHOT ON;

-- Example of using Snapshot Isolation
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable WHERE SomeColumn = 'SomeValue';

COMMIT TRANSACTION;


-- SQL Server supports several isolation levels that control the visibility of changes made by other transactions.

-- 1. Read Uncommitted: Allows dirty reads, meaning you can read uncommitted changes from other transactions.

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;


-- 2. Read Committed: Default isolation level. Prevents dirty reads by only reading committed changes.

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;


-- 3. Repeatable Read: Prevents dirty reads and non-repeatable reads by holding shared locks on read data until the transaction completes.

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;


-- 4. Serializable: The strictest isolation level. Prevents dirty reads, non-repeatable reads, and phantom reads by holding range locks until the transaction completes.

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;


-- 5. Snapshot: Provides a consistent view of the data as it existed at the start of the transaction, preventing dirty reads, non-repeatable reads, and phantom reads.


SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Perform some operations
SELECT * FROM YourTable;

COMMIT TRANSACTION;