/**************************************************************
 * SQL Server 2022 Time Series Tutorial
 * Description: This script demonstrates various techniques for 
 *              working with time series data in SQL Server 2022.
 *              Topics include:
 *              - Creating a time series table.
 *              - Inserting sample time series data.
 *              - Basic queries filtering by date/time.
 *              - Window functions for running totals, moving averages,
 *                and differences.
 *              - Using system-versioned temporal tables for historical
 *                data analysis.
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
-- Region: 1. Creating the Time Series Table
-------------------------------------------------
/*
  1.1 Create a basic time series table to store sensor readings.
  Columns include:
    - ReadingID: Unique identifier.
    - ReadingTime: The timestamp of the reading.
    - SensorID: ID of the sensor.
    - Value: Numeric measurement.
*/
IF OBJECT_ID(N'dbo.TimeSeriesData', N'U') IS NOT NULL
    DROP TABLE dbo.TimeSeriesData;
GO

CREATE TABLE dbo.TimeSeriesData
(
    ReadingID INT IDENTITY(1,1) PRIMARY KEY,
    ReadingTime DATETIME2(0) NOT NULL,
    SensorID INT NOT NULL,
    Value DECIMAL(10,2) NOT NULL
);
GO

-------------------------------------------------
-- Region: 2. Inserting Sample Time Series Data
-------------------------------------------------
/*
  2.1 Insert sample time series data.
  For demonstration, we use readings from a single sensor over a period.
*/
INSERT INTO dbo.TimeSeriesData (ReadingTime, SensorID, Value)
VALUES
    ('2023-01-01 08:00:00', 1, 10.50),
    ('2023-01-01 08:05:00', 1, 11.00),
    ('2023-01-01 08:10:00', 1, 10.75),
    ('2023-01-01 08:15:00', 1, 11.25),
    ('2023-01-01 08:20:00', 1, 10.90),
    ('2023-01-01 08:25:00', 1, 11.10),
    ('2023-01-01 08:30:00', 1, 11.00),
    ('2023-01-01 08:35:00', 1, 10.80),
    ('2023-01-01 08:40:00', 1, 11.20),
    ('2023-01-01 08:45:00', 1, 11.30);
GO

-------------------------------------------------
-- Region: 3. Basic Time Series Queries
-------------------------------------------------
/*
  3.1 Retrieve all readings for SensorID = 1 during the morning session.
*/
SELECT *
FROM dbo.TimeSeriesData
WHERE SensorID = 1
  AND ReadingTime BETWEEN '2023-01-01 08:00:00' AND '2023-01-01 09:00:00'
ORDER BY ReadingTime;
GO

-------------------------------------------------
-- Region: 4. Time Series Analysis Using Window Functions
-------------------------------------------------
/*
  4.1 Running Total: Calculate a running total of the sensor values.
*/
SELECT ReadingID, ReadingTime, SensorID, Value,
       SUM(Value) OVER (ORDER BY ReadingTime ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM dbo.TimeSeriesData
ORDER BY ReadingTime;
GO

/*
  4.2 Moving Average: Calculate a 3-reading moving average.
         (Adjust the window frame as needed.)
*/
SELECT ReadingID, ReadingTime, SensorID, Value,
       AVG(Value) OVER (ORDER BY ReadingTime ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS MovingAvg
FROM dbo.TimeSeriesData
ORDER BY ReadingTime;
GO

/*
  4.3 Lag and Lead: Compare each reading with the previous and next readings.
*/
SELECT ReadingID, ReadingTime, SensorID, Value,
       LAG(Value, 1) OVER (ORDER BY ReadingTime) AS PrevValue,
       LEAD(Value, 1) OVER (ORDER BY ReadingTime) AS NextValue
FROM dbo.TimeSeriesData
ORDER BY ReadingTime;
GO

/*
  4.4 Difference Calculation: Calculate the difference between consecutive readings.
*/
SELECT ReadingID, ReadingTime, SensorID, Value,
       Value - LAG(Value, 1) OVER (ORDER BY ReadingTime) AS ValueDiff
FROM dbo.TimeSeriesData
ORDER BY ReadingTime;
GO

-------------------------------------------------
-- Region: 5. Grouping Time Series Data by Intervals
-------------------------------------------------
/*
  5.1 Group by 15-minute intervals and calculate aggregate metrics.
  Use DATEADD and DATEDIFF to bucket timestamps.
*/
SELECT DATEADD(minute, (DATEDIFF(minute, 0, ReadingTime) / 15) * 15, 0) AS TimeInterval,
       COUNT(*) AS ReadingCount,
       AVG(Value) AS AvgValue,
       MIN(Value) AS MinValue,
       MAX(Value) AS MaxValue
FROM dbo.TimeSeriesData
GROUP BY DATEADD(minute, (DATEDIFF(minute, 0, ReadingTime) / 15) * 15, 0)
ORDER BY TimeInterval;
GO

-------------------------------------------------
-- Region: 6. Using System-Versioned Temporal Tables for Time Series History
-------------------------------------------------
/*
  6.1 Create a system-versioned temporal table for time series data.
  This example uses a new table to track historical changes.
*/
IF OBJECT_ID(N'dbo.TemporalTimeSeries', N'U') IS NOT NULL
    DROP TABLE dbo.TemporalTimeSeries;
GO

CREATE TABLE dbo.TemporalTimeSeries
(
    ReadingID INT IDENTITY(1,1) PRIMARY KEY,
    ReadingTime DATETIME2(0) NOT NULL,
    SensorID INT NOT NULL,
    Value DECIMAL(10,2) NOT NULL,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo   DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.TemporalTimeSeriesHistory));
GO

/*
  6.2 Insert sample data into the temporal table.
*/
INSERT INTO dbo.TemporalTimeSeries (ReadingTime, SensorID, Value)
VALUES
    ('2023-01-01 09:00:00', 1, 11.50),
    ('2023-01-01 09:05:00', 1, 11.60);
GO

/*
  6.3 Update data to generate history records.
*/
UPDATE dbo.TemporalTimeSeries
SET Value = 11.70
WHERE ReadingID = 1;
GO

/*
  6.4 Query the current data.
*/
SELECT *
FROM dbo.TemporalTimeSeries
FOR SYSTEM_TIME AS OF '2023-01-01 09:10:00';
GO

/*
  6.5 Query the historical data.
*/
SELECT *
FROM dbo.TemporalTimeSeriesHistory
ORDER BY ValidFrom;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
