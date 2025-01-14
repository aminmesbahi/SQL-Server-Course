-------------------------------------
-- 6: Functions
-------------------------------------

USE TestDB;
GO

-- Simple scalar function
CREATE FUNCTION dbo.GetAnimalType(@Name NVARCHAR(60))
RETURNS NVARCHAR(60)
AS
BEGIN
    DECLARE @Type NVARCHAR(60);
    SELECT @Type = [Type]
    FROM dbo.Animals
    WHERE [Name] = @Name;
    RETURN @Type;
END;
GO

-- Inline table-valued function
CREATE FUNCTION dbo.GetAnimalsByType(@Type NVARCHAR(60))
RETURNS TABLE
AS
RETURN
(
    SELECT [Name], [Age]
    FROM dbo.Animals
    WHERE [Type] = @Type
);
GO

-- Multi-statement table-valued function
CREATE FUNCTION dbo.GetAnimalsOlderThan(@Age INT)
RETURNS @Animals TABLE
(
    [Name] NVARCHAR(60),
    [Type] NVARCHAR(60),
    [Age] INT
)
AS
BEGIN
    INSERT INTO @Animals
    SELECT [Name], [Type], [Age]
    FROM dbo.Animals
    WHERE [Age] > @Age;
    RETURN;
END;
GO

-- Function with APPLY operator
CREATE FUNCTION dbo.GetAnimalDetails(@Name NVARCHAR(60))
RETURNS TABLE
AS
RETURN
(
    SELECT a.[Name], a.[Type], a.[Age], d.[Detail]
    FROM dbo.Animals a
    CROSS APPLY (SELECT 'Detail about ' + a.[Name] AS [Detail]) d
    WHERE a.[Name] = @Name
);
GO

-- Advanced scalar function with error handling
CREATE FUNCTION dbo.SafeDivide(@Numerator FLOAT, @Denominator FLOAT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @Result FLOAT;
    IF @Denominator = 0
        RETURN NULL;
    SET @Result = @Numerator / @Denominator;
    RETURN @Result;
END;
GO

-- Advanced table-valued function using JSON
CREATE FUNCTION dbo.GetAnimalsFromJSON(@AnimalData NVARCHAR(MAX))
RETURNS @Animals TABLE
(
    [Name] NVARCHAR(60),
    [Type] NVARCHAR(60),
    [Age] INT
)
AS
BEGIN
    INSERT INTO @Animals
    SELECT 
        JSON_VALUE(value, '$.Name') AS [Name],
        JSON_VALUE(value, '$.Type') AS [Type],
        JSON_VALUE(value, '$.Age') AS [Age]
    FROM OPENJSON(@AnimalData);
    RETURN;
END;
GO

-- Advanced function using SQL Server 2022 features
CREATE FUNCTION dbo.GetAnimalAgeCategory(@Age INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    RETURN 
        CASE 
            WHEN @Age < 1 THEN 'Infant'
            WHEN @Age BETWEEN 1 AND 3 THEN 'Young'
            WHEN @Age BETWEEN 4 AND 7 THEN 'Adult'
            ELSE 'Senior'
        END;
END;
GO

-- Using APPLY operator with a function
SELECT a.[Name], a.[Type], a.[Age], d.[Detail]
FROM dbo.Animals a
CROSS APPLY dbo.GetAnimalDetails(a.[Name]) d;
GO