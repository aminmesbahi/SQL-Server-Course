-------------------------------------
-- 8: Views
-------------------------------------

USE TestDB;
GO

-- Simple view
CREATE VIEW dbo.vwAnimalNames
AS
SELECT [Name]
FROM dbo.Animals;
GO

-- View with JOIN
CREATE VIEW dbo.vwAnimalDetails
AS
SELECT a.[Name], a.[Type], a.[Age], d.[Detail]
FROM dbo.Animals a
LEFT JOIN dbo.AnimalDetails d ON a.[Name] = d.[Name];
GO

-- View with aggregate function
CREATE VIEW dbo.vwAnimalCountByType
AS
SELECT [Type], COUNT(*) AS AnimalCount
FROM dbo.Animals
GROUP BY [Type];
GO

-- Indexed view (materialized view)
CREATE VIEW dbo.vwAnimalAges
WITH SCHEMABINDING
AS
SELECT [Name], [Age]
FROM dbo.Animals;
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalAges ON dbo.vwAnimalAges([Name]);
GO

-- View with parameters using inline table-valued function
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

CREATE VIEW dbo.vwAnimalsByType
AS
SELECT [Name], [Age]
FROM dbo.fnGetAnimalsByType(N'Mammal');
GO

-- Advanced view using JSON
CREATE VIEW dbo.vwAnimalJSON
AS
SELECT [Name], [Type], [Age], 
       JSON_QUERY((SELECT [Name], [Type], [Age] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS AnimalJSON
FROM dbo.Animals;
GO

-- Advanced view using SQL Server 2022 features
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

-- Materialized view with refresh option
CREATE VIEW dbo.vwAnimalSummary
WITH SCHEMABINDING
AS
SELECT [Type], COUNT(*) AS AnimalCount, AVG([Age]) AS AverageAge
FROM dbo.Animals
GROUP BY [Type];
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalSummary ON dbo.vwAnimalSummary([Type]);
GO

-- Refresh materialized view
ALTER INDEX IX_vwAnimalSummary ON dbo.vwAnimalSummary REBUILD;
GO

-- Advanced materialized view using SQL Server 2022 features
CREATE VIEW dbo.vwAnimalStats
WITH SCHEMABINDING
AS
SELECT [Type], COUNT(*) AS AnimalCount, AVG([Age]) AS AverageAge, 
       JSON_OBJECT('Type' VALUE [Type], 'AnimalCount' VALUE COUNT(*), 'AverageAge' VALUE AVG([Age])) AS AnimalStatsJSON
FROM dbo.Animals
GROUP BY [Type];
GO

CREATE UNIQUE CLUSTERED INDEX IX_vwAnimalStats ON dbo.vwAnimalStats([Type]);
GO

-- Refresh advanced materialized view
ALTER INDEX IX_vwAnimalStats ON dbo.vwAnimalStats REBUILD;
GO