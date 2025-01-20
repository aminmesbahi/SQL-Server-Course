-------------------------------------
-- 15: Windowing Functions
-------------------------------------

USE TestDB;
GO

-- Create a sample table
CREATE TABLE dbo.Sales
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2)
);
GO

-- Insert sample data
INSERT INTO dbo.Sales (SaleID, SaleDate, CustomerID, Amount)
VALUES
    (1, '2023-01-01', 1, 100.00),
    (2, '2023-01-02', 2, 150.00),
    (3, '2023-01-03', 1, 200.00),
    (4, '2023-01-04', 3, 250.00),
    (5, '2023-01-05', 2, 300.00);
GO

-- ROW_NUMBER() function
-- Assigns a unique number to each row within the partition of a result set
SELECT SaleID, SaleDate, CustomerID, Amount,
       ROW_NUMBER() OVER (ORDER BY SaleDate) AS RowNum
FROM dbo.Sales;
GO

-- RANK() function
-- Assigns a rank to each row within the partition of a result set
SELECT SaleID, SaleDate, CustomerID, Amount,
       RANK() OVER (ORDER BY Amount DESC) AS Rank
FROM dbo.Sales;
GO

-- DENSE_RANK() function
-- Assigns a rank to each row within the partition of a result set, without gaps in rank values
SELECT SaleID, SaleDate, CustomerID, Amount,
       DENSE_RANK() OVER (ORDER BY Amount DESC) AS DenseRank
FROM dbo.Sales;
GO

-- NTILE() function
-- Distributes the rows in an ordered partition into a specified number of groups
SELECT SaleID, SaleDate, CustomerID, Amount,
       NTILE(3) OVER (ORDER BY Amount DESC) AS NTile
FROM dbo.Sales;
GO

-- LAG() function
-- Accesses data from a previous row in the same result set without the use of a self-join
SELECT SaleID, SaleDate, CustomerID, Amount,
       LAG(Amount, 1, 0) OVER (ORDER BY SaleDate) AS PrevAmount
FROM dbo.Sales;
GO

-- LEAD() function
-- Accesses data from a subsequent row in the same result set without the use of a self-join
SELECT SaleID, SaleDate, CustomerID, Amount,
       LEAD(Amount, 1, 0) OVER (ORDER BY SaleDate) AS NextAmount
FROM dbo.Sales;
GO

-- FIRST_VALUE() function
-- Returns the first value in an ordered set of values
SELECT SaleID, SaleDate, CustomerID, Amount,
       FIRST_VALUE(Amount) OVER (ORDER BY SaleDate) AS FirstAmount
FROM dbo.Sales;
GO

-- LAST_VALUE() function
-- Returns the last value in an ordered set of values
SELECT SaleID, SaleDate, CustomerID, Amount,
       LAST_VALUE(Amount) OVER (ORDER BY SaleDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastAmount
FROM dbo.Sales;
GO

-- CUME_DIST() function
-- Calculates the cumulative distribution of a value in a set of values
SELECT SaleID, SaleDate, CustomerID, Amount,
       CUME_DIST() OVER (ORDER BY Amount DESC) AS CumeDist
FROM dbo.Sales;
GO

-- PERCENT_RANK() function
-- Calculates the relative rank of a row within a group of rows
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENT_RANK() OVER (ORDER BY Amount DESC) AS PercentRank
FROM dbo.Sales;
GO

-- PERCENTILE_CONT() function
-- Calculates a percentile based on a continuous distribution of the column value
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) OVER () AS MedianAmount
FROM dbo.Sales;
GO

-- PERCENTILE_DISC() function
-- Calculates a percentile based on a discrete distribution of the column value
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Amount) OVER () AS MedianAmount
FROM dbo.Sales;
GO

-- SUM() function with PARTITION BY
-- Calculates the sum of a set of values within a partition
SELECT SaleID, SaleDate, CustomerID, Amount,
       SUM(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningTotal
FROM dbo.Sales;
GO

-- AVG() function with PARTITION BY
-- Calculates the average of a set of values within a partition
SELECT SaleID, SaleDate, CustomerID, Amount,
       AVG(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningAvg
FROM dbo.Sales;
GO

-- COUNT() function with PARTITION BY
-- Calculates the count of a set of values within a partition
SELECT SaleID, SaleDate, CustomerID, Amount,
       COUNT(*) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningCount
FROM dbo.Sales;
GO

-- MAX() function with PARTITION BY
-- Calculates the maximum of a set of values within a partition
SELECT SaleID, SaleDate, CustomerID, Amount,
       MAX(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningMax
FROM dbo.Sales;
GO

-- MIN() function with PARTITION BY
-- Calculates the minimum of a set of values within a partition
SELECT SaleID, SaleDate, CustomerID, Amount,
       MIN(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningMin
FROM dbo.Sales;
GO