/**************************************************************
 * SQL Server 2022 Views Tutorial
 * Description: This script demonstrates various view types in
 *              SQL Server including simple views, views with JOINs,
 *              aggregate views, indexed (materialized) views, views
 *              using inline table-valued functions, and advanced views
 *              using JSON and SQL Server 2022 features.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database for view operations.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Simple Views
-------------------------------------------------
/*
  1.1 Simple view to display animal names.
*/
CREATE VIEW dbo.vwAnimalNames
AS
SELECT [Name]
FROM dbo.Animals;
GO

-------------------------------------------------
-- Region: 2. Views with JOINs
-------------------------------------------------
/*
  2.1 View joining dbo.Animals with dbo.AnimalDetails.
  Note: Ensure that dbo.AnimalDetails exists with a [Name] column.
*/
CREATE VIEW dbo.vwAnimalDetails
AS
SELECT a.[Name], a.[Type], a.[Age], d.[Detail]
FROM dbo.Animals a
LEFT JOIN dbo.AnimalDetails d 
    ON a.[Name] = d.[Name];
GO

-------------------------------------------------
-- Region: 3. Aggregate Views
-------------------------------------------------
/*
  3.1 View showing count of animals by type.
*/
CREATE VIEW dbo.vwAnimalCountByType
AS
SELECT [Type], COUNT(*) AS AnimalCount
FROM dbo.Animals
GROUP BY [Type];
GO

-------------------------------------------------
-- Region: 4. Indexed (Materialized) Views
-------------------------------------------------
/*
  4.1 Indexed view for animal ages.
  Note: Indexed views require schema binding.
*/
CREATE VIEW dbo.vwAnimalAges
WITH SCHEMABINDING
AS
SELECT [Name], [Age]
FROM dbo.Animals;
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalAges 
ON dbo.vwAnimalAges([Name]);
GO

-------------------------------------------------
-- Region: 5. Views with Parameters via Inline Table-Valued Functions
-------------------------------------------------
/*
  5.1 Inline table-valued function to filter animals by type.
*/
CREATE FUNCTION dbo.fnGetAnimalsByType(@Type NVARCHAR(60))
RETURNS TABLE
AS
RETURN
(
    SELECT [Name], [Age]
    FROM dbo.Animals
    WHERE [Type] = @Type
);
GO

/*
  5.2 View using the inline table-valued function.
  In this example, it returns animals of type 'Mammal'.
*/
CREATE VIEW dbo.vwAnimalsByType
AS
SELECT [Name], [Age]
FROM dbo.fnGetAnimalsByType(N'Mammal');
GO

-------------------------------------------------
-- Region: 6. Advanced Views Using JSON and SQL Server 2022 Features
-------------------------------------------------
/*
  6.1 Advanced view using JSON: Returns animal data along with a JSON snippet.
*/
CREATE VIEW dbo.vwAnimalJSON
AS
SELECT [Name], [Type], [Age], 
       JSON_QUERY(
           (SELECT [Name], [Type], [Age] 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
       ) AS AnimalJSON
FROM dbo.Animals;
GO

/*
  6.2 Advanced view using CASE to compute animal age categories.
*/
CREATE VIEW dbo.vwAnimalAgeCategory
AS
SELECT [Name], [Age],
       CASE 
           WHEN [Age] < 1 THEN 'Infant'
           WHEN [Age] BETWEEN 1 AND 3 THEN 'Young'
           WHEN [Age] BETWEEN 4 AND 7 THEN 'Adult'
           ELSE 'Senior'
       END AS AgeCategory
FROM dbo.Animals;
GO

-------------------------------------------------
-- Region: 7. Materialized Views with Refresh Options
-------------------------------------------------
/*
  7.1 Materialized view summarizing animal counts and average age by type.
  Requires schema binding.
*/
CREATE VIEW dbo.vwAnimalSummary
WITH SCHEMABINDING
AS
SELECT [Type], COUNT(*) AS AnimalCount, AVG([Age]) AS AverageAge
FROM dbo.Animals
GROUP BY [Type];
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalSummary 
ON dbo.vwAnimalSummary([Type]);
GO

/*
  Refresh materialized view by rebuilding its index.
*/
ALTER INDEX IX_vwAnimalSummary ON dbo.vwAnimalSummary REBUILD;
GO

/*
  7.2 Advanced materialized view using SQL Server 2022 features to include JSON.
*/
CREATE VIEW dbo.vwAnimalStats
WITH SCHEMABINDING
AS
SELECT [Type], COUNT(*) AS AnimalCount, AVG([Age]) AS AverageAge, 
       JSON_OBJECT('Type' VALUE [Type],
                   'AnimalCount' VALUE COUNT(*),
                   'AverageAge' VALUE AVG([Age])
                  ) AS AnimalStatsJSON
FROM dbo.Animals
GROUP BY [Type];
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalStats 
ON dbo.vwAnimalStats([Type]);
GO

/*
  Refresh advanced materialized view.
*/
ALTER INDEX IX_vwAnimalStats ON dbo.vwAnimalStats REBUILD;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------