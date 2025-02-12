CREATE DATABASE PartitionDB;
GO

USE PartitionDB;
GO

-- Create a partition function
CREATE PARTITION FUNCTION MyPartitionFunction (INT)
AS RANGE LEFT FOR VALUES (1000, 2000, 3000, 4000);
GO

-- Create a partition scheme
CREATE PARTITION SCHEME MyPartitionScheme
AS PARTITION MyPartitionFunction
TO (PRIMARY, PRIMARY, PRIMARY, PRIMARY, PRIMARY);
GO

-- Create a partitioned table
CREATE TABLE Sales
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
) ON MyPartitionScheme(SaleID);
GO


-- Insert data into the partitioned table
INSERT INTO Sales (SaleID, SaleDate, Amount)
VALUES (500, '2022-01-01', 100.00),
       (1500, '2022-02-01', 200.00),
       (2500, '2022-03-01', 300.00),
       (3500, '2022-04-01', 400.00),
       (4500, '2022-05-01', 500.00);
GO

-- Query data from the partitioned table
SELECT * FROM Sales
WHERE SaleID BETWEEN 1000 AND 2000;
GO

-- Create a staging table with the same structure as the partitioned table
CREATE TABLE Sales_Staging
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    Amount DECIMAL(10, 2)
);
GO

-- Insert data into the staging table
INSERT INTO Sales_Staging (SaleID, SaleDate, Amount)
VALUES (5000, '2022-06-01', 600.00);
GO

-- Switch the staging table data into a partition
ALTER TABLE Sales
SWITCH PARTITION 5 TO Sales_Staging;
GO

-- Verify the switch
SELECT * FROM Sales;
SELECT * FROM Sales_Staging;
GO

-- Switch the data back to the partitioned table
ALTER TABLE Sales_Staging
SWITCH TO Sales PARTITION 5;
GO

-- Verify the switch
SELECT * FROM Sales;
SELECT * FROM Sales_Staging;
GO