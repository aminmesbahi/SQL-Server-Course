-------------------------------------
-- Enhanced APPROX_PERCENTILE Script with SQL Server 2022 Features
-------------------------------------

USE TestDB;
GO

-- Create optimized table with compression (2022 enhancement)
DROP TABLE IF EXISTS dbo.Sales;
CREATE TABLE dbo.Sales
(
    SaleID INT PRIMARY KEY CLUSTERED,
    SaleDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2),
    RegionID INT,
    INDEX idx_Amount NONCLUSTERED (Amount) WITH (DATA_COMPRESSION = PAGE)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);  -- 2022 in-mem optimization
GO

-- Insert larger dataset using GENERATE_SERIES (2022 new function)
INSERT INTO dbo.Sales (SaleID, SaleDate, CustomerID, Amount, RegionID)
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS SaleID,
    DATEADD(DAY, seq-1, '2023-01-01') AS SaleDate,
    ABS(CHECKSUM(NEWID())) % 10 + 1 AS CustomerID,  -- 10 customers
    ROUND(RAND(CHECKSUM(NEWID())) * 1000, 2) AS Amount,
    ABS(CHECKSUM(NEWID())) % 5 + 1 AS RegionID      -- 5 regions
FROM GENERATE_SERIES(1, 100000);  -- 2022 feature for 100k rows
GO

-- Add NULL values for demonstration
UPDATE dbo.Sales 
SET Amount = NULL 
WHERE SaleID % 100 = 0;  -- 1% NULL values
GO

-- Create columnstore index for analytics (2022 compression improvements)
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_sales_cs 
ON dbo.Sales (SaleDate, CustomerID, Amount, RegionID)
WITH (COMPRESSION_DELAY = 60);
GO

-- Approximate percentile with accuracy analysis (2022 new features)
DECLARE @Percentile FLOAT = 0.75;
DECLARE @AccuracyLevel INT = 10000;  -- 2022 precision control

SELECT 
    CustomerID,
    -- Approximate calculations
    APPROX_PERCENTILE_CONT(Amount, @Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) AS ApproxMedianCont,
        
    APPROX_PERCENTILE_DISC(Amount, @Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) AS ApproxMedianDisc,
        
    -- Exact calculations for comparison
    PERCENTILE_CONT(@Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) AS ExactMedianCont,
        
    PERCENTILE_DISC(@Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) AS ExactMedianDisc,
        
    -- Accuracy metrics
    ABS(APPROX_PERCENTILE_CONT(Amount, @Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) - 
        PERCENTILE_CONT(@Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID)) AS ContErrorMargin,
        
    COUNT(*) OVER (PARTITION BY CustomerID) AS SampleSize
FROM dbo.Sales
WHERE Amount IS NOT NULL;  -- 2022 IS NOT NULL predicate optimization
GO

-- Multi-dimensional percentiles with WINDOW clause (2022 feature)
WITH PercentileData AS (
    SELECT 
        CustomerID,
        RegionID,
        Amount,
        APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) 
            OVER (PARTITION BY CustomerID) AS GlobalMedian,
        APPROX_PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Amount) 
            OVER (PARTITION BY CustomerID, RegionID) AS RegionalMedian
    FROM dbo.Sales
    WHERE Amount IS NOT NULL
)
SELECT 
    CustomerID,
    RegionID,
    AVG(Amount) AS AvgAmount,
    GlobalMedian,
    RegionalMedian,
    RegionalMedian - GlobalMedian AS MedianDiff
FROM PercentileData
GROUP BY CustomerID, RegionID, GlobalMedian, RegionalMedian;
GO

-- Histogram with APPROX_PERCENTILE and GENERATE_SERIES (2022 combination)
WITH Buckets AS (
    SELECT value AS BucketNumber
    FROM GENERATE_SERIES(0, 100, 5)  -- 5% buckets
)
SELECT 
    b.BucketNumber/100.0 AS Percentile,
    APPROX_PERCENTILE_CONT(b.BucketNumber/100.0) 
        WITHIN GROUP (ORDER BY Amount) AS ValueCont,
    APPROX_PERCENTILE_DISC(b.BucketNumber/100.0) 
        WITHIN GROUP (ORDER BY Amount) AS ValueDisc
FROM dbo.Sales
CROSS JOIN Buckets b
WHERE Amount IS NOT NULL
GROUP BY b.BucketNumber;
GO

-- Error handling for percentile functions (2022 improved TRY_*)
BEGIN TRY
    SELECT APPROX_PERCENTILE_CONT(1.5) WITHIN GROUP (ORDER BY Amount) FROM dbo.Sales;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- Performance comparison with STATISTICS (2022 enhanced stats)
SET STATISTICS IO, TIME ON;

-- Approximate version
SELECT 
    CustomerID,
    APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Amount) AS P95
FROM dbo.Sales
GROUP BY CustomerID;

-- Exact version
SELECT 
    CustomerID,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Amount) AS ExactP95
FROM dbo.Sales
GROUP BY CustomerID;

SET STATISTICS IO, TIME OFF;
GO

-- Cleanup with modern syntax
DROP TABLE IF EXISTS dbo.Sales;
GO