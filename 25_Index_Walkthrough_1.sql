-- Enable advanced options to view details like page usage.
-- This enables the usage of DBCC IND and DBCC PAGE commands for deeper insights.
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- STEP 1: Create a database and set the context
CREATE DATABASE IndexDemoDB;
GO
USE IndexDemoDB;
GO

-- STEP 2: Create an empty table with a fixed-sized column (e.g., CHAR(2000))
-- No indexes are created at this stage.
CREATE TABLE HeapTable (
    ID INT NOT NULL PRIMARY KEY NONCLUSTERED, -- We'll focus on the heap (data without a clustered index)
    FixedColumn CHAR(2000) NOT NULL
);
GO

-- STEP 3: Check the storage structure of the empty table
-- Heap (no clustered index), no data pages yet.
DBCC IND('IndexDemoDB', 'HeapTable', -1); -- View allocation units and their types
DBCC SHOWCONTIG('HeapTable'); -- View details on page usage and fragmentation
GO

-- STEP 4: Insert enough rows to fill the first page
-- Assuming an 8 KB page and each row takes 2004 bytes (2000 bytes + some overhead),
-- each page can fit 4 rows.
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES (1, REPLICATE('A', 2000)),
       (2, REPLICATE('B', 2000)),
       (3, REPLICATE('C', 2000)),
       (4, REPLICATE('D', 2000));
GO

-- STEP 5: Analyze page usage after inserting 4 rows (first page filled)
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- STEP 6: Add another row to create a new page
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES (5, REPLICATE('E', 2000));
GO

-- Check page usage again. This time, there should be two pages.
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- STEP 7: Add a clustered index and repeat steps to observe behavior
-- Clustered indexes rearrange the data pages physically in sorted order based on the key.
CREATE CLUSTERED INDEX CIX_HeapTable ON HeapTable(ID);
GO

-- Analyze the table after adding a clustered index
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- Insert more rows and check page behavior with clustered index
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES (6, REPLICATE('F', 2000)),
       (7, REPLICATE('G', 2000)),
       (8, REPLICATE('H', 2000)),
       (9, REPLICATE('I', 2000));
GO

-- Check pages after more inserts
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- STEP 8: Create a non-clustered index and observe its behavior
-- Non-clustered indexes are separate from the data and include pointers to the rows.
CREATE NONCLUSTERED INDEX NCIX_HeapTable ON HeapTable(FixedColumn);
GO

-- Check the structure after adding the non-clustered index
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- Insert more rows and observe changes in both clustered and non-clustered indexes
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES (10, REPLICATE('J', 2000)),
       (11, REPLICATE('K', 2000));
GO

-- Final analysis of page behavior
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-- OPTIONAL: Use DBCC PAGE to examine individual pages in depth
-- Find a specific page ID from DBCC IND output and pass it to DBCC PAGE for details
-- For example, if PagePID = 1 (replace with your own result):
DBCC TRACEON(3604); -- Enable output to query results
DBCC PAGE('IndexDemoDB', 1, 1, 3); -- Database ID, File ID, Page ID, Output Level
GO
DBCC TRACEOFF(3604); -- Disable output

-- Clean up
-- DROP DATABASE IndexDemoDB;
