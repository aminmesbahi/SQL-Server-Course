/**************************************************************
 * SQL Server 2022 Enhanced APPROX_PERCENTILE Tutorial
 * Description: This script demonstrates advanced percentile and 
 *              histogram analytics using new SQL Server 2022 features.
 *              Features include:
 *              - Creating a memory-optimized, compressed table.
 *              - Generating a large dataset with GENERATE_SERIES.
 *              - Using APPROX_PERCENTILE_CONT/DISC with accuracy metrics.
 *              - Multi-dimensional percentiles using the WINDOW clause.
 *              - Histogram generation with GENERATE_SERIES.
 *              - Enhanced error handling and performance statistics.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure the target database is used.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating the Optimized Sales Table
-------------------------------------------------
/*
  1.1 Drop the table if it exists.
*/
DROP TABLE IF EXISTS dbo.Sales;
GO

/*
  1.2 Create a memory-optimized table with data compression and an index.
       This table leverages SQL Server 2022 enhancements.
*/
CREATE TABLE dbo.Sales
(
    SaleID INT PRIMARY KEY CLUSTERED,
    SaleDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2),
    RegionID INT,
    INDEX idx_Amount NONCLUSTERED (Amount) WITH (DATA_COMPRESSION = PAGE)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

-------------------------------------------------
-- Region: 2. Inserting Sample Data using GENERATE_SERIES
-------------------------------------------------
/*
  2.1 Insert 100,000 rows using the new GENERATE_SERIES function.
       This simulates a large time series dataset.
*/
INSERT INTO dbo.Sales (SaleID, SaleDate, CustomerID, Amount, RegionID)
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS SaleID,
    DATEADD(DAY, seq-1, '2023-01-01') AS SaleDate,
    ABS(CHECKSUM(NEWID())) % 10 + 1 AS CustomerID,  -- 10 customers
    ROUND(RAND(CHECKSUM(NEWID())) * 1000, 2) AS Amount,
    ABS(CHECKSUM(NEWID())) % 5 + 1 AS RegionID       -- 5 regions
FROM GENERATE_SERIES(1, 100000);
GO

-------------------------------------------------
-- Region: 3. Introducing NULL Values
-------------------------------------------------
/*
  3.1 Update the table to include NULL values in the Amount column.
       This sets approximately 1% of rows to NULL.
*/
UPDATE dbo.Sales 
SET Amount = NULL 
WHERE SaleID % 100 = 0;
GO

-------------------------------------------------
-- Region: 4. Creating a Columnstore Index for Analytics
-------------------------------------------------
/*
  4.1 Create a nonclustered columnstore index to improve analytical query performance.
       COMPRESSION_DELAY option (in seconds) is used to optimize compression timing.
*/
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_sales_cs 
ON dbo.Sales (SaleDate, CustomerID, Amount, RegionID)
WITH (COMPRESSION_DELAY = 60);
GO

-------------------------------------------------
-- Region: 5. Approximate Percentile Analytics with Accuracy Metrics
-------------------------------------------------
/*
  5.1 Set percentile and accuracy parameters.
*/
DECLARE @Percentile FLOAT = 0.75;
DECLARE @AccuracyLevel INT = 10000;  -- Precision control (conceptual)

/*
  5.2 Calculate approximate and exact percentiles, and compute error margins.
       Partitioning by CustomerID for per-customer analysis.
*/
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
        
    -- Accuracy metrics (absolute error margin)
    ABS(APPROX_PERCENTILE_CONT(Amount, @Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID) 
      - PERCENTILE_CONT(@Percentile) 
        WITHIN GROUP (ORDER BY Amount) 
        OVER (PARTITION BY CustomerID)) AS ContErrorMargin,
        
    COUNT(*) OVER (PARTITION BY CustomerID) AS SampleSize
FROM dbo.Sales
WHERE Amount IS NOT NULL;  -- Optimized predicate in 2022
GO

-------------------------------------------------
-- Region: 6. Multi-Dimensional Percentiles with WINDOW Clause
-------------------------------------------------
/*
  6.1 Calculate global and regional medians using APPROX_PERCENTILE_CONT.
       Global median is per CustomerID; regional median is per CustomerID and RegionID.
*/
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

-------------------------------------------------
-- Region: 7. Histogram Generation using APPROX_PERCENTILE and GENERATE_SERIES
-------------------------------------------------
/*
  7.1 Create buckets using GENERATE_SERIES for 5% intervals.
       Then, generate approximate percentile histograms for each bucket.
*/
WITH Buckets AS (
    SELECT value AS BucketNumber
    FROM GENERATE_SERIES(0, 100, 5)  -- Buckets every 5%
)
SELECT 
    b.BucketNumber / 100.0 AS Percentile,
    APPROX_PERCENTILE_CONT(b.BucketNumber / 100.0) 
        WITHIN GROUP (ORDER BY Amount) AS ValueCont,
    APPROX_PERCENTILE_DISC(b.BucketNumber / 100.0) 
        WITHIN GROUP (ORDER BY Amount) AS ValueDisc
FROM dbo.Sales
CROSS JOIN Buckets b
WHERE Amount IS NOT NULL
GROUP BY b.BucketNumber;
GO

-------------------------------------------------
-- Region: 8. Error Handling for Percentile Functions
-------------------------------------------------
/*
  8.1 Demonstrate error handling using TRY/CATCH for an invalid percentile.
*/
BEGIN TRY
    SELECT APPROX_PERCENTILE_CONT(1.5) WITHIN GROUP (ORDER BY Amount) FROM dbo.Sales;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-------------------------------------------------
-- Region: 9. Performance Comparison with STATISTICS IO, TIME
-------------------------------------------------
/*
  9.1 Enable performance statistics.
*/
SET STATISTICS IO, TIME ON;

/*
  9.2 Query using the approximate percentile function.
*/
SELECT 
    CustomerID,
    APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Amount) AS P95
FROM dbo.Sales
GROUP BY CustomerID;

/*
  9.3 Query using the exact percentile function.
*/
SELECT 
    CustomerID,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Amount) AS ExactP95
FROM dbo.Sales
GROUP BY CustomerID;

/*
  9.4 Disable performance statistics.
*/
SET STATISTICS IO, TIME OFF;
GO

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
/*
  Clean up by dropping the Sales table.
*/
DROP TABLE IF EXISTS dbo.Sales;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
