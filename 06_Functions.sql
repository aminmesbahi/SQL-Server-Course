-- ===============================
-- 6: Functions
-- ===============================

USE TestDB;
GO

-- 6.1 Simple Scalar Function
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

-- 6.2 Inline Table-Valued Function
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

-- 6.3 Multi-Statement Table-Valued Function
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

-- 6.4 Function with APPLY Operator
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

-- 6.5 Advanced Scalar Function with Error Handling
CREATE FUNCTION dbo.SafeDivide(@Numerator FLOAT, @Denominator FLOAT)
RETURNS FLOAT
AS
BEGIN
    IF @Denominator = 0
        RETURN NULL; -- Avoid division by zero
    RETURN @Numerator / @Denominator;
END;
GO

-- 6.6 Advanced Table-Valued Function Using JSON
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

-- 6.7 Advanced Function Using CASE Expression
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

-- 6.8 Advanced Function Using STRING_SPLIT (SQL Server 2016+)
CREATE FUNCTION dbo.GetAnimalListFromString(@AnimalList NVARCHAR(MAX))
RETURNS @Animals TABLE
(
    [Name] NVARCHAR(60)
)
AS
BEGIN
    INSERT INTO @Animals ([Name])
    SELECT value
    FROM STRING_SPLIT(@AnimalList, ',');
    RETURN;
END;
GO

-- 6.9 Function Using APPLY Operator
-- Example query using CROSS APPLY with a function
SELECT a.[Name], a.[Type], a.[Age], d.[Detail]
FROM dbo.Animals a
CROSS APPLY dbo.GetAnimalDetails(a.[Name]) d;
GO

-- 6.10 Function Using STRING_AGG (SQL Server 2017+)
CREATE FUNCTION dbo.GetAnimalNamesByType(@Type NVARCHAR(60))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT STRING_AGG([Name], ', ')
        FROM dbo.Animals
        WHERE [Type] = @Type
    );
END;
GO

-- 6.11 Function with Dynamic Data Masking (SQL Server 2022+)
CREATE FUNCTION dbo.MaskAnimalName(@Name NVARCHAR(60))
RETURNS NVARCHAR(60)
AS
BEGIN
    RETURN 
        CASE 
            WHEN @Name IS NOT NULL THEN CONCAT(LEFT(@Name, 1), REPLICATE('*', LEN(@Name) - 1))
            ELSE NULL
        END;
END;
GO

-- 6.12 Example Query with APPLY
SELECT 
    a.[Name], 
    a.[Type], 
    a.[Age], 
    d.AnimalNames
FROM dbo.Animals a
CROSS APPLY (SELECT dbo.GetAnimalNamesByType(a.[Type])) d(AnimalNames);
GO
