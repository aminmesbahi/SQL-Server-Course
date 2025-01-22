-------------------------------------
-- APPROX_PERCENTILE_CONT and APPROX_PERCENTILE_DISC
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
    (5, '2023-01-05', 2, 300.00),
    (6, '2023-01-06', 1, 350.00),
    (7, '2023-01-07', 3, 400.00),
    (8, '2023-01-08', 2, 450.00),
    (9, '2023-01-09', 1, 500.00),
    (10, '2023-01-10', 3, 550.00);
GO

-- APPROX_PERCENTILE_CONT function
-- Calculate the approximate continuous percentile for the Amount column
SELECT 
    APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmount,
    APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartile,
    APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartile
FROM dbo.Sales;
GO

-- APPROX_PERCENTILE_DISC function
-- Calculate the approximate discrete percentile for the Amount column
SELECT 
    APPROX_PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmount,
    APPROX_PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartile,
    APPROX_PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartile
FROM dbo.Sales;
GO

-- APPROX_PERCENTILE_CONT function with PARTITION BY
-- Calculate the approximate continuous percentile for the Amount column partitioned by CustomerID
SELECT 
    CustomerID,
    APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmount,
    APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartile,
    APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartile
FROM dbo.Sales
GROUP BY CustomerID;
GO

-- APPROX_PERCENTILE_DISC function with PARTITION BY
-- Calculate the approximate discrete percentile for the Amount column partitioned by CustomerID
SELECT 
    CustomerID,
    APPROX_PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmount,
    APPROX_PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartile,
    APPROX_PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartile
FROM dbo.Sales
GROUP BY CustomerID;
GO

-- Combining APPROX_PERCENTILE_CONT and APPROX_PERCENTILE_DISC in a single query
SELECT 
    CustomerID,
    APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmountCont,
    APPROX_PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Amount) AS MedianAmountDisc,
    APPROX_PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartileCont,
    APPROX_PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Amount) AS FirstQuartileDisc,
    APPROX_PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartileCont,
    APPROX_PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Amount) AS ThirdQuartileDisc
FROM dbo.Sales
GROUP BY CustomerID;
GO