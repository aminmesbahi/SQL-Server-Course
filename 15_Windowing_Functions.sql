/**************************************************************
 * SQL Server 2022 Windowing Functions Tutorial
 * Description: This script demonstrates various windowing 
 *              (analytic) functions in SQL Server, including:
 *              - ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE()
 *              - LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE()
 *              - CUME_DIST(), PERCENT_RANK()
 *              - PERCENTILE_CONT() and PERCENTILE_DISC()
 *              - Aggregate window functions (SUM, AVG, COUNT, MAX, MIN)
 *              along with the use of PARTITION BY and ORDER BY.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating the Sales Table and Inserting Data
-------------------------------------------------
/*
  1.1 Create a sample table to demonstrate window functions.
*/
IF OBJECT_ID(N'dbo.Sales', N'U') IS NOT NULL
    DROP TABLE dbo.Sales;
GO

CREATE TABLE dbo.Sales
(
    SaleID INT PRIMARY KEY,
    SaleDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2)
);
GO

/*
  1.2 Insert sample sales data.
*/
INSERT INTO dbo.Sales (SaleID, SaleDate, CustomerID, Amount)
VALUES
    (1, '2023-01-01', 1, 100.00),
    (2, '2023-01-02', 2, 150.00),
    (3, '2023-01-03', 1, 200.00),
    (4, '2023-01-04', 3, 250.00),
    (5, '2023-01-05', 2, 300.00);
GO

-------------------------------------------------
-- Region: 2. Ranking Functions
-------------------------------------------------
/*
  2.1 ROW_NUMBER() - Assigns a unique number to each row ordered by SaleDate.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       ROW_NUMBER() OVER (ORDER BY SaleDate) AS RowNum
FROM dbo.Sales;
GO

/*
  2.2 RANK() - Assigns a rank to each row, with gaps for ties.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       RANK() OVER (ORDER BY Amount DESC) AS Rank
FROM dbo.Sales;
GO

/*
  2.3 DENSE_RANK() - Similar to RANK() but without gaps.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       DENSE_RANK() OVER (ORDER BY Amount DESC) AS DenseRank
FROM dbo.Sales;
GO

/*
  2.4 NTILE() - Distributes rows into a specified number of groups.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       NTILE(3) OVER (ORDER BY Amount DESC) AS NTile
FROM dbo.Sales;
GO

-------------------------------------------------
-- Region: 3. Navigation Functions
-------------------------------------------------
/*
  3.1 LAG() - Accesses data from the previous row.
       If no previous row exists, default to 0.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       LAG(Amount, 1, 0) OVER (ORDER BY SaleDate) AS PrevAmount
FROM dbo.Sales;
GO

/*
  3.2 LEAD() - Accesses data from the next row.
       If no subsequent row exists, default to 0.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       LEAD(Amount, 1, 0) OVER (ORDER BY SaleDate) AS NextAmount
FROM dbo.Sales;
GO

/*
  3.3 FIRST_VALUE() - Returns the first value in the window.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       FIRST_VALUE(Amount) OVER (ORDER BY SaleDate) AS FirstAmount
FROM dbo.Sales;
GO

/*
  3.4 LAST_VALUE() - Returns the last value in the window.
       The window frame must cover all rows.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       LAST_VALUE(Amount) OVER (ORDER BY SaleDate 
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastAmount
FROM dbo.Sales;
GO

-------------------------------------------------
-- Region: 4. Distribution Functions
-------------------------------------------------
/*
  4.1 CUME_DIST() - Cumulative distribution of a value in a set.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       CUME_DIST() OVER (ORDER BY Amount DESC) AS CumeDist
FROM dbo.Sales;
GO

/*
  4.2 PERCENT_RANK() - Relative rank of a row within a group.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENT_RANK() OVER (ORDER BY Amount DESC) AS PercentRank
FROM dbo.Sales;
GO

-------------------------------------------------
-- Region: 5. Percentile Functions
-------------------------------------------------
/*
  5.1 PERCENTILE_CONT() - Calculates a continuous percentile (e.g., median).
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) OVER () AS MedianAmount
FROM dbo.Sales;
GO

/*
  5.2 PERCENTILE_DISC() - Calculates a discrete percentile.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Amount) OVER () AS MedianAmount
FROM dbo.Sales;
GO

-------------------------------------------------
-- Region: 6. Aggregate Window Functions with PARTITION BY
-------------------------------------------------
/*
  6.1 SUM() - Running total of Amount for each Customer.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       SUM(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningTotal
FROM dbo.Sales;
GO

/*
  6.2 AVG() - Running average of Amount for each Customer.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       AVG(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningAvg
FROM dbo.Sales;
GO

/*
  6.3 COUNT() - Running count of sales for each Customer.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       COUNT(*) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningCount
FROM dbo.Sales;
GO

/*
  6.4 MAX() - Running maximum sale amount for each Customer.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       MAX(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningMax
FROM dbo.Sales;
GO

/*
  6.5 MIN() - Running minimum sale amount for each Customer.
*/
SELECT SaleID, SaleDate, CustomerID, Amount,
       MIN(Amount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS RunningMin
FROM dbo.Sales;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
