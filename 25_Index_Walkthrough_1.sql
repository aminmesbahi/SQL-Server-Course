/**************************************************************
 * SQL Server 2022: Page Usage and Index Analysis Tutorial
 * Description: This script demonstrates how to enable advanced 
 *              options to view detailed page usage and index 
 *              structure using DBCC IND, DBCC SHOWCONTIG, and 
 *              DBCC PAGE commands. It covers:
 *              - Creating a database and table (Heap and then with
 *                clustered and non-clustered indexes).
 *              - Inserting rows to observe page splitting behavior.
 *              - Analyzing page usage and fragmentation.
 *              - Examining specific pages using DBCC PAGE.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Enabling Advanced Options
-------------------------------------------------
/*
  Enable advanced options to view details like page usage.
  This allows the usage of DBCC IND and DBCC PAGE commands.
*/
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-------------------------------------------------
-- Region: 1. Database and Table Setup
-------------------------------------------------
/*
  1.1 Create a new database and switch to its context.
*/
CREATE DATABASE IndexDemoDB;
GO
USE IndexDemoDB;
GO

/*
  1.2 Create an empty table with a fixed-sized column.
       The table is initially a heap (no clustered index).
*/
CREATE TABLE HeapTable (
    ID INT NOT NULL PRIMARY KEY NONCLUSTERED, -- Primary key is nonclustered to emphasize the heap structure
    FixedColumn CHAR(2000) NOT NULL
);
GO

-------------------------------------------------
-- Region: 2. Initial Page Usage Analysis (Empty Table)
-------------------------------------------------
/*
  2.1 Analyze the storage structure of the empty table.
      - DBCC IND shows allocation units and their types.
      - DBCC SHOWCONTIG displays page usage and fragmentation.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-------------------------------------------------
-- Region: 3. Inserting Data and Analyzing Page Splits
-------------------------------------------------
/*
  3.1 Insert enough rows to fill the first page.
      Assuming each row is ~2004 bytes (2000 for FixedColumn + overhead),
      approximately 4 rows will fill an 8 KB page.
*/
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES 
    (1, REPLICATE('A', 2000)),
    (2, REPLICATE('B', 2000)),
    (3, REPLICATE('C', 2000)),
    (4, REPLICATE('D', 2000));
GO

/*
  3.2 Analyze page usage after inserting 4 rows (first page filled).
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

/*
  3.3 Insert another row to create a new page.
*/
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES (5, REPLICATE('E', 2000));
GO

/*
  3.4 Analyze page usage; now there should be two pages.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-------------------------------------------------
-- Region: 4. Adding a Clustered Index and Analyzing Behavior
-------------------------------------------------
/*
  4.1 Create a clustered index on the table.
       This will physically reorder the data pages based on the key.
*/
CREATE CLUSTERED INDEX CIX_HeapTable ON HeapTable(ID);
GO

/*
  4.2 Analyze the table after adding a clustered index.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

/*
  4.3 Insert additional rows to observe page behavior with a clustered index.
*/
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES 
    (6, REPLICATE('F', 2000)),
    (7, REPLICATE('G', 2000)),
    (8, REPLICATE('H', 2000)),
    (9, REPLICATE('I', 2000));
GO

/*
  4.4 Check page usage after the additional inserts.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-------------------------------------------------
-- Region: 5. Adding a Non-Clustered Index and Further Analysis
-------------------------------------------------
/*
  5.1 Create a non-clustered index on the FixedColumn.
       Non-clustered indexes are stored separately from the data.
*/
CREATE NONCLUSTERED INDEX NCIX_HeapTable ON HeapTable(FixedColumn);
GO

/*
  5.2 Analyze the structure after adding the non-clustered index.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

/*
  5.3 Insert additional rows and observe changes.
*/
INSERT INTO HeapTable (ID, FixedColumn) 
VALUES 
    (10, REPLICATE('J', 2000)),
    (11, REPLICATE('K', 2000));
GO

/*
  5.4 Final analysis of page usage and index structure.
*/
DBCC IND('IndexDemoDB', 'HeapTable', -1);
DBCC SHOWCONTIG('HeapTable');
GO

-------------------------------------------------
-- Region: 6. Deep Dive: Using DBCC PAGE for Page Details
-------------------------------------------------
/*
  6.1 OPTIONAL: Use DBCC PAGE to examine details of a specific page.
       First, enable trace flag 3604 to direct output to the query results.
       Replace <PageID> with an actual PageID from DBCC IND output.
*/
DBCC TRACEON(3604); -- Enable output to query results

-- Example: Examine page details (adjust File ID and Page ID as appropriate)
DBCC PAGE('IndexDemoDB', 1, 1, 3); -- (DatabaseID, FileID, PageID, Output Level)
GO

DBCC TRACEOFF(3604); -- Disable trace flag
GO

-------------------------------------------------
-- Region: 7. Cleanup
-------------------------------------------------
/*
  Clean up: Optionally, drop the database if no longer needed.
  Uncomment the following line to drop the database.
*/
-- DROP DATABASE IndexDemoDB;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
