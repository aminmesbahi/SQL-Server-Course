/**************************************************************
 * SQL Server 2022 Partitioning Tutorial
 * Description: This script demonstrates how to implement table 
 *              partitioning in SQL Server 2022. It covers:
 *              - Creating a partition function and scheme.
 *              - Creating and populating a partitioned table.
 *              - Switching data between staging and production partitions.
 *              - Splitting and merging partitions.
 *              - Creating and rebuilding partitioned indexes.
 *              - Archiving data using SWITCH.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database and Partitioning Objects Setup
-------------------------------------------------
/*
  Create a database for the partitioning example.
*/
CREATE DATABASE PartitionDB;
GO

USE PartitionDB;
GO

/*
  Create a partition function that defines ranges based on SaleID.
  RANGE LEFT means that the boundary value belongs to the left partition.
*/
CREATE PARTITION FUNCTION MyPartitionFunction (INT)
AS RANGE LEFT FOR VALUES (1000, 2000, 3000, 4000);
GO

/*
  Create a partition scheme that maps the partition function to filegroups.
  In this example, all partitions are mapped to the PRIMARY filegroup.
*/
CREATE PARTITION SCHEME MyPartitionScheme
AS PARTITION MyPartitionFunction
TO (PRIMARY, PRIMARY, PRIMARY, PRIMARY, PRIMARY);
GO

-------------------------------------------------
-- Region: 2. Creating and Populating the Partitioned Table
-------------------------------------------------
/*
  Create a partitioned table Sales on the partition scheme based on SaleID.
*/
CREATE TABLE Sales
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
) ON MyPartitionScheme(SaleID);
GO

/*
  Insert sample data into the partitioned table.
  The inserted SaleIDs will fall into different partitions based on the partition function.
*/
INSERT INTO Sales (SaleID, SaleDate, Amount)
VALUES (500, '2022-01-01', 100.00),
       (1500, '2022-02-01', 200.00),
       (2500, '2022-03-01', 300.00),
       (3500, '2022-04-01', 400.00),
       (4500, '2022-05-01', 500.00);
GO

-------------------------------------------------
-- Region: 3. Querying and Switching Data Between Partitions
-------------------------------------------------
/*
  Query data from the partitioned table for a specific range of SaleIDs.
*/
SELECT * FROM Sales
WHERE SaleID BETWEEN 1000 AND 2000;
GO

/*
  Create a staging table with the same structure as the Sales table.
*/
CREATE TABLE Sales_Staging
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
);
GO

/*
  Insert sample data into the staging table.
*/
INSERT INTO Sales_Staging (SaleID, SaleDate, Amount)
VALUES (5000, '2022-06-01', 600.00);
GO

/*
  Switch the staging table data into partition 5 of the Sales table.
*/
ALTER TABLE Sales
SWITCH PARTITION 5 TO Sales_Staging;
GO

/*
  Verify the switch: Sales_Staging should be empty and Sales should include the new row.
*/
SELECT * FROM Sales;
SELECT * FROM Sales_Staging;
GO

/*
  Switch the data back from the staging table to partition 5.
*/
ALTER TABLE Sales_Staging
SWITCH TO Sales PARTITION 5;
GO

/*
  Verify the switch: Sales_Staging should again be empty.
*/
SELECT * FROM Sales;
SELECT * FROM Sales_Staging;
GO

-------------------------------------------------
-- Region: 4. Splitting and Merging Partitions
-------------------------------------------------
/*
  Split a partition: This will split an existing partition at the specified value.
*/
ALTER PARTITION FUNCTION MyPartitionFunction()
SPLIT RANGE (3500);
GO

/*
  Merge partitions: This will merge partitions that have the specified boundary value.
*/
ALTER PARTITION FUNCTION MyPartitionFunction()
MERGE RANGE (3000);
GO

-------------------------------------------------
-- Region: 5. Partitioned Index Maintenance
-------------------------------------------------
/*
  Create a partitioned nonclustered index on the SaleDate column.
*/
CREATE INDEX IX_Sales_SaleDate
ON Sales(SaleDate)
ON MyPartitionScheme(SaleID);
GO

/*
  Rebuild the partitioned index across all partitions.
*/
ALTER INDEX IX_Sales_SaleDate
ON Sales
REBUILD PARTITION = ALL;
GO

-------------------------------------------------
-- Region: 6. Archiving Data Using SWITCH
-------------------------------------------------
/*
  Create an archive table with the same structure as the Sales table.
*/
CREATE TABLE Sales_Archive
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
) ON [PRIMARY];
GO

/*
  Switch old data (from partition 1) to the archive table.
*/
ALTER TABLE Sales
SWITCH PARTITION 1 TO Sales_Archive;
GO

/*
  Verify the switch: Check data in both Sales and Sales_Archive tables.
*/
SELECT * FROM Sales;
SELECT * FROM Sales_Archive;
GO

-------------------------------------------------
-- Region: 7. Cleanup
-------------------------------------------------
/*
  Drop the partitioned table.
*/
DROP TABLE Sales;
GO

/*
  Drop the partition scheme.
*/
DROP PARTITION SCHEME MyPartitionScheme;
GO

/*
  Drop the partition function.
*/
DROP PARTITION FUNCTION MyPartitionFunction;
GO

/*
  Drop the archive table.
*/
DROP TABLE Sales_Archive;
GO

/*
  Drop the database.
*/
DROP DATABASE PartitionDB;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
