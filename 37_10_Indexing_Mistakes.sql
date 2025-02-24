/**************************************************************
 * SQL Server 2022: Indexing Bad Practices and Optimal Approaches
 * Description: This script demonstrates 10 common indexing bad 
 *              practices and provides the correct (optimal) approach 
 *              for each scenario. Adjust table/index names and designs 
 *              as needed based on your workload and query patterns.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Over-indexing vs. Optimal Composite Indexes
-------------------------------------------------
/*
  BAD PRACTICE:
    - Creating separate indexes on individual columns, causing high maintenance overhead.
  
  CORRECT APPROACH:
    - Analyze query patterns and create a composite (covering) index that supports common filtering 
      and sorting requirements.
*/

-- Setup sample table dbo.Orders
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    Status VARCHAR(50),
    Amount DECIMAL(10,2)
);
GO

-- BAD PRACTICE: Separate indexes on individual columns
CREATE NONCLUSTERED INDEX idx_Orders_CustomerID ON dbo.Orders(CustomerID);
CREATE NONCLUSTERED INDEX idx_Orders_OrderDate ON dbo.Orders(OrderDate);
CREATE NONCLUSTERED INDEX idx_Orders_Status     ON dbo.Orders(Status);
CREATE NONCLUSTERED INDEX idx_Orders_Amount     ON dbo.Orders(Amount);
GO

-- CORRECT APPROACH: Remove individual indexes and create one composite covering index
DROP INDEX idx_Orders_CustomerID ON dbo.Orders;
DROP INDEX idx_Orders_OrderDate  ON dbo.Orders;
DROP INDEX idx_Orders_Status     ON dbo.Orders;
DROP INDEX idx_Orders_Amount     ON dbo.Orders;
GO

CREATE NONCLUSTERED INDEX idx_Orders_Composite 
    ON dbo.Orders(CustomerID, OrderDate)
    INCLUDE (Status, Amount);
GO

-------------------------------------------------
-- Region: 2. Indexing Frequently Updated Columns
-------------------------------------------------
/*
  BAD PRACTICE:
    - Indexing columns that are updated frequently, increasing maintenance cost.
  
  CORRECT APPROACH:
    - Avoid indexing volatile columns unless they are critical for query performance.
*/

-- Setup sample table dbo.Employees
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
    DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees (
    EmployeeID INT IDENTITY PRIMARY KEY,
    Name         VARCHAR(100),
    LastLoginDate DATETIME
);
GO

-- BAD PRACTICE: Creating an index on a frequently updated column
CREATE NONCLUSTERED INDEX idx_Employees_LastLoginDate_Bad ON dbo.Employees(LastLoginDate);
GO

-- CORRECT APPROACH: Drop the index unless testing shows a performance benefit
DROP INDEX idx_Employees_LastLoginDate_Bad ON dbo.Employees;
GO

-- (Optionally, create the index only if needed)
-- CREATE NONCLUSTERED INDEX idx_Employees_LastLoginDate_Good ON dbo.Employees(LastLoginDate);
GO

-------------------------------------------------
-- Region: 3. Creating Covering Indexes with INCLUDE Clause
-------------------------------------------------
/*
  BAD PRACTICE:
    - Creating an index that doesn't cover the query, causing extra lookups.
  
  CORRECT APPROACH:
    - Use the INCLUDE clause to create a covering index that satisfies the query entirely.
*/

-- Setup sample table dbo.Products
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Products (
    ProductID   INT IDENTITY PRIMARY KEY,
    ProductName VARCHAR(200),
    CategoryID  INT,
    Price       DECIMAL(10,2),
    Stock       INT
);
GO

-- BAD PRACTICE: Index without covering additional columns
CREATE NONCLUSTERED INDEX idx_Products_CategoryID_Bad ON dbo.Products(CategoryID);
GO

-- CORRECT APPROACH: Drop the index and create one that includes needed columns
DROP INDEX idx_Products_CategoryID_Bad ON dbo.Products;
GO

CREATE NONCLUSTERED INDEX idx_Products_CategoryID_Good 
    ON dbo.Products(CategoryID)
    INCLUDE (ProductName, Price);
GO

-------------------------------------------------
-- Region: 4. Ordering Columns in Composite Indexes
-------------------------------------------------
/*
  BAD PRACTICE:
    - Incorrect ordering of columns in a composite index.
  
  CORRECT APPROACH:
    - Place columns with equality predicates before those with range predicates.
*/

-- Setup sample table dbo.Sales
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL
    DROP TABLE dbo.Sales;
GO

CREATE TABLE dbo.Sales (
    SaleID   INT IDENTITY PRIMARY KEY,
    RegionID INT,
    SaleDate DATETIME,
    Total    DECIMAL(10,2)
);
GO

-- BAD PRACTICE: Incorrect order – range column (SaleDate) first, then equality column (RegionID)
CREATE NONCLUSTERED INDEX idx_Sales_Bad ON dbo.Sales(SaleDate, RegionID);
GO

-- CORRECT APPROACH: Equality column first, then range column
DROP INDEX idx_Sales_Bad ON dbo.Sales;
GO

CREATE NONCLUSTERED INDEX idx_Sales_Good ON dbo.Sales(RegionID, SaleDate);
GO

-------------------------------------------------
-- Region: 5. Using Filtered Indexes Appropriately
-------------------------------------------------
/*
  BAD PRACTICE:
    - Creating an index on the entire table when only a subset is frequently queried.
  
  CORRECT APPROACH:
    - Use a filtered index to index only the subset of rows, reducing index size and improving performance.
*/

-- Setup sample table dbo.Logs
IF OBJECT_ID('dbo.Logs', 'U') IS NOT NULL
    DROP TABLE dbo.Logs;
GO

CREATE TABLE dbo.Logs (
    LogID     INT IDENTITY PRIMARY KEY,
    EventDate DATETIME,
    EventType VARCHAR(50),
    Message   NVARCHAR(MAX)
);
GO

-- BAD PRACTICE: Full-table index on EventType
CREATE NONCLUSTERED INDEX idx_Logs_EventType_Bad ON dbo.Logs(EventType);
GO

-- CORRECT APPROACH: Use a filtered index for a subset (e.g., 'Error' events)
DROP INDEX idx_Logs_EventType_Bad ON dbo.Logs;
GO

CREATE NONCLUSTERED INDEX idx_Logs_ErrorEventType 
    ON dbo.Logs(EventType)
    WHERE EventType = 'Error';
GO

-------------------------------------------------
-- Region: 6. Indexing Computed Columns Properly
-------------------------------------------------
/*
  BAD PRACTICE:
    - Indexing a non-persisted computed column, leading to performance overhead.
  
  CORRECT APPROACH:
    - Persist the computed column so that it is physically stored, then create the index.
*/

-- Setup sample table dbo.Invoices
IF OBJECT_ID('dbo.Invoices', 'U') IS NOT NULL
    DROP TABLE dbo.Invoices;
GO

CREATE TABLE dbo.Invoices (
    InvoiceID INT IDENTITY PRIMARY KEY,
    Subtotal  DECIMAL(10,2),
    Tax       DECIMAL(10,2)
);
GO

-- BAD PRACTICE: Add non-persisted computed column and index it directly
ALTER TABLE dbo.Invoices ADD Total AS (Subtotal + Tax);
GO

CREATE NONCLUSTERED INDEX idx_Invoices_Total_Bad ON dbo.Invoices((Subtotal + Tax));
GO

-- CORRECT APPROACH: Drop computed column, re-add as PERSISTED, then index it
ALTER TABLE dbo.Invoices DROP COLUMN Total;
GO

ALTER TABLE dbo.Invoices ADD Total AS (Subtotal + Tax) PERSISTED;
GO

CREATE NONCLUSTERED INDEX idx_Invoices_Total_Good ON dbo.Invoices(Total);
GO

-------------------------------------------------
-- Region: 7. Keeping Statistics Up-to-Date
-------------------------------------------------
/*
  BAD PRACTICE:
    - Not updating statistics after significant data changes.
  
  CORRECT APPROACH:
    - Update statistics manually or ensure AUTO_UPDATE_STATISTICS is enabled.
*/

-- Update statistics manually on dbo.Orders table
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
GO

-- Ensure AUTO_UPDATE_STATISTICS is enabled
ALTER DATABASE CURRENT SET AUTO_UPDATE_STATISTICS ON;
GO

-------------------------------------------------
-- Region: 8. Enforcing Uniqueness with Unique Indexes/Constraints
-------------------------------------------------
/*
  BAD PRACTICE:
    - Creating a non-unique index on a column expected to contain unique values.
  
  CORRECT APPROACH:
    - Use a UNIQUE constraint or index to enforce data integrity.
*/

-- Setup sample table dbo.Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    UserID   INT IDENTITY PRIMARY KEY,
    Username VARCHAR(100) NOT NULL
);
GO

-- BAD PRACTICE: Non-unique index on Username
CREATE NONCLUSTERED INDEX idx_Users_Username_Bad ON dbo.Users(Username);
GO

-- CORRECT APPROACH: Drop the index and enforce uniqueness via a constraint
DROP INDEX idx_Users_Username_Bad ON dbo.Users;
GO

ALTER TABLE dbo.Users
ADD CONSTRAINT UQ_Users_Username UNIQUE (Username);
GO

-------------------------------------------------
-- Region: 9. Regular Maintenance for Index Fragmentation
-------------------------------------------------
/*
  BAD PRACTICE:
    - Ignoring index fragmentation, which degrades query performance.
  
  CORRECT APPROACH:
    - Regularly monitor and maintain indexes using REBUILD or REORGANIZE commands.
*/

-- Rebuild all indexes on the dbo.Orders table to reduce fragmentation
ALTER INDEX ALL ON dbo.Orders REBUILD;
GO

-- Alternatively, reorganize indexes on the dbo.Products table for moderate fragmentation
ALTER INDEX ALL ON dbo.Products REORGANIZE;
GO

-------------------------------------------------
-- Region: 10. Avoiding Indexes on Low-Selectivity Columns
-------------------------------------------------
/*
  BAD PRACTICE:
    - Creating an index on a column with low cardinality (e.g., Status flag) that provides little filtering benefit.
  
  CORRECT APPROACH:
    - Avoid single-column indexes on low-selectivity columns.
    - Instead, create composite indexes that include additional columns.
*/

-- Setup sample table dbo.Tickets
IF OBJECT_ID('dbo.Tickets', 'U') IS NOT NULL
    DROP TABLE dbo.Tickets;
GO

CREATE TABLE dbo.Tickets (
    TicketID   INT IDENTITY PRIMARY KEY,
    Status     VARCHAR(20),  -- e.g., 'Open', 'Closed'
    CreatedDate DATETIME
);
GO

-- BAD PRACTICE: Single-column index on a low-selectivity column
CREATE NONCLUSTERED INDEX idx_Tickets_Status_Bad ON dbo.Tickets(Status);
GO

-- CORRECT APPROACH: Drop the index and create a composite index
DROP INDEX idx_Tickets_Status_Bad ON dbo.Tickets;
GO

CREATE NONCLUSTERED INDEX idx_Tickets_Status_CreatedDate_Good 
    ON dbo.Tickets(Status, CreatedDate);
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
