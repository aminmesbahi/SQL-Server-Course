/*
  Script: IndexingBadPracticesAndOptimalApproaches.sql
  Description: This script demonstrates 10 common indexing bad practices in SQL Server 2022
               and provides the correct (optimal) approach for each scenario.
  Note: These examples are for demonstration purposes. In a production environment,
        adjust table/index names and designs based on your workload and query patterns.
*/

/*=============================================================================
  1. Over-indexing vs. Optimal Indexing Based on Query Patterns
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating many separate indexes on a table’s individual columns.
    - This can cause unnecessary overhead on INSERT/UPDATE/DELETE operations.
    
  CORRECT APPROACH:
    - Analyze the queries and create a composite (covering) index that supports
      the most common filtering and sorting requirements.
=============================================================================*/

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

-- BAD PRACTICE: Creating too many separate indexes
CREATE NONCLUSTERED INDEX idx_Orders_CustomerID ON dbo.Orders(CustomerID);
CREATE NONCLUSTERED INDEX idx_Orders_OrderDate ON dbo.Orders(OrderDate);
CREATE NONCLUSTERED INDEX idx_Orders_Status     ON dbo.Orders(Status);
CREATE NONCLUSTERED INDEX idx_Orders_Amount     ON dbo.Orders(Amount);
GO

-- CORRECT APPROACH: Remove the unnecessary indexes and create one composite index
DROP INDEX idx_Orders_CustomerID ON dbo.Orders;
DROP INDEX idx_Orders_OrderDate  ON dbo.Orders;
DROP INDEX idx_Orders_Status     ON dbo.Orders;
DROP INDEX idx_Orders_Amount     ON dbo.Orders;
GO

CREATE NONCLUSTERED INDEX idx_Orders_Composite 
    ON dbo.Orders(CustomerID, OrderDate)
    INCLUDE (Status, Amount);
GO

/*=============================================================================
  2. Indexing Frequently Updated Columns
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Indexing columns that are updated very often.
    - This increases the maintenance cost during DML operations.
    
  CORRECT APPROACH:
    - Only create indexes on volatile columns if they are essential for query performance.
    - Otherwise, avoid indexing to reduce update overhead.
=============================================================================*/

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

-- BAD PRACTICE: Index on a frequently updated column
CREATE NONCLUSTERED INDEX idx_Employees_LastLoginDate_Bad ON dbo.Employees(LastLoginDate);
GO

-- CORRECT APPROACH: Drop the index unless performance testing shows a benefit.
DROP INDEX idx_Employees_LastLoginDate_Bad ON dbo.Employees;
GO

-- (Optionally, create the index only if queries filtering by LastLoginDate are critical)
-- CREATE NONCLUSTERED INDEX idx_Employees_LastLoginDate_Good ON dbo.Employees(LastLoginDate);
GO

/*=============================================================================
  3. Creating Covering Indexes Using the INCLUDE Clause
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating an index that only includes the key column(s) and forces lookups
      to retrieve additional columns.
      
  CORRECT APPROACH:
    - Use the INCLUDE clause to create a covering index that satisfies the query.
=============================================================================*/

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

-- BAD PRACTICE: Index without including columns used in SELECT
CREATE NONCLUSTERED INDEX idx_Products_CategoryID_Bad ON dbo.Products(CategoryID);
GO

-- CORRECT APPROACH: Cover the query by including needed columns
DROP INDEX idx_Products_CategoryID_Bad ON dbo.Products;
GO

CREATE NONCLUSTERED INDEX idx_Products_CategoryID_Good 
    ON dbo.Products(CategoryID)
    INCLUDE (ProductName, Price);
GO

/*=============================================================================
  4. Ordering of Columns in Composite Indexes
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Not ordering columns correctly.
    - For queries that filter with equality on one column and a range on another,
      the column used with the equality predicate should come first.
      
  CORRECT APPROACH:
    - Order the columns such that equality predicates come before range predicates.
=============================================================================*/

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

-- BAD PRACTICE: Wrong order – SaleDate (range) comes before RegionID (equality)
CREATE NONCLUSTERED INDEX idx_Sales_Bad ON dbo.Sales(SaleDate, RegionID);
GO

-- CORRECT APPROACH: Equality column first, then range column
DROP INDEX idx_Sales_Bad ON dbo.Sales;
GO

CREATE NONCLUSTERED INDEX idx_Sales_Good ON dbo.Sales(RegionID, SaleDate);
GO

/*=============================================================================
  5. Using Filtered Indexes Appropriately
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating a full-table index even though only a subset of rows is often queried.
    
  CORRECT APPROACH:
    - Use a filtered index to index only the subset of rows that are queried,
      reducing index size and improving performance.
=============================================================================*/

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

-- CORRECT APPROACH: Use a filtered index (e.g., for 'Error' events)
DROP INDEX idx_Logs_EventType_Bad ON dbo.Logs;
GO

CREATE NONCLUSTERED INDEX idx_Logs_ErrorEventType 
    ON dbo.Logs(EventType)
    WHERE EventType = 'Error';
GO

/*=============================================================================
  6. Indexing Computed Columns Properly
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating an index on a computed column that isn’t persisted,
      which can lead to performance issues.
      
  CORRECT APPROACH:
    - Persist the computed column so that it is physically stored,
      then create the index.
=============================================================================*/

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

-- BAD PRACTICE: Add non-persisted computed column and index its expression directly
ALTER TABLE dbo.Invoices ADD Total AS (Subtotal + Tax);
GO

CREATE NONCLUSTERED INDEX idx_Invoices_Total_Bad ON dbo.Invoices((Subtotal + Tax));
GO

-- CORRECT APPROACH: Drop the computed column, re-add it as PERSISTED, then index it
ALTER TABLE dbo.Invoices DROP COLUMN Total;
GO

ALTER TABLE dbo.Invoices ADD Total AS (Subtotal + Tax) PERSISTED;
GO

CREATE NONCLUSTERED INDEX idx_Invoices_Total_Good ON dbo.Invoices(Total);
GO

/*=============================================================================
  7. Keeping Statistics Up-to-Date
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Failing to update statistics after significant data/index changes,
      which may lead the query optimizer to choose suboptimal plans.
    
  CORRECT APPROACH:
    - Ensure that statistics are updated regularly—either via auto-update or
      manual maintenance.
=============================================================================*/

-- BAD PRACTICE: (No statistics update; just for demonstration, nothing is done here)

-- CORRECT APPROACH: Update statistics manually if needed
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
GO

-- Also, ensure that the database has AUTO_UPDATE_STATISTICS enabled:
ALTER DATABASE CURRENT SET AUTO_UPDATE_STATISTICS ON;
GO

/*=============================================================================
  8. Enforcing Uniqueness Using Unique Indexes/Constraints
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating a non-unique index on a column that is expected to contain unique values.
    
  CORRECT APPROACH:
    - Use a UNIQUE index or constraint to enforce data integrity and potentially improve
      query performance.
=============================================================================*/

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

-- CORRECT APPROACH: Drop the index and add a UNIQUE constraint
DROP INDEX idx_Users_Username_Bad ON dbo.Users;
GO

ALTER TABLE dbo.Users
ADD CONSTRAINT UQ_Users_Username UNIQUE (Username);
GO

/*=============================================================================
  9. Regular Maintenance to Manage Index Fragmentation
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Neglecting index fragmentation, which can slow down query performance.
    
  CORRECT APPROACH:
    - Regularly monitor and maintain indexes using REBUILD or REORGANIZE commands.
=============================================================================*/

-- Example: Rebuild all indexes on Orders table to eliminate fragmentation
ALTER INDEX ALL ON dbo.Orders REBUILD;
GO

-- Alternatively, reorganize indexes on the Products table (for moderate fragmentation)
ALTER INDEX ALL ON dbo.Products REORGANIZE;
GO

/*=============================================================================
  10. Avoiding Indexes on Low-Selectivity Columns
  -----------------------------------------------------------------------------
  BAD PRACTICE:
    - Creating indexes on columns with low cardinality (e.g., a Status flag) where
      the index does little to narrow down the result set.
      
  CORRECT APPROACH:
    - Avoid single-column indexes on low-selectivity columns.
    - Instead, create composite indexes that include additional columns to improve selectivity.
=============================================================================*/

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

-- CORRECT APPROACH: Create a composite index that includes an additional column for better filtering
DROP INDEX idx_Tickets_Status_Bad ON dbo.Tickets;
GO

CREATE NONCLUSTERED INDEX idx_Tickets_Status_CreatedDate_Good 
    ON dbo.Tickets(Status, CreatedDate);
GO

