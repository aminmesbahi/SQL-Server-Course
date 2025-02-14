/**************************************************************
 * SQL Server 2022 Functions Tutorial
 * Description: This script demonstrates various function types
 *              in SQL Server including scalar functions, inline
 *              and multi-statement table-valued functions, usage 
 *              of APPLY operator, error handling, JSON parsing, 
 *              and advanced functions using CASE, STRING_SPLIT, 
 *              STRING_AGG, and dynamic data masking.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database for function operations.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Simple Scalar Function
-------------------------------------------------
/*
  1.1 dbo.GetAnimalType: Returns the type of an animal based on its name.
  Note: The dbo.Animals table must contain a column named [Type].
*/
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

-------------------------------------------------
-- Region: 2. Inline Table-Valued Function
-------------------------------------------------
/*
  2.1 dbo.GetAnimalsByType: Returns a table with animals filtered by type.
*/
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

-------------------------------------------------
-- Region: 3. Multi-Statement Table-Valued Function
-------------------------------------------------
/*
  3.1 dbo.GetAnimalsOlderThan: Returns animals older than the specified age.
  Note: The dbo.Animals table must contain columns [Name], [Type], and [Age].
*/
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

-------------------------------------------------
-- Region: 4. Function with APPLY Operator
-------------------------------------------------
/*
  4.1 dbo.GetAnimalDetails: Returns animal details along with a computed detail string.
*/
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

-------------------------------------------------
-- Region: 5. Advanced Scalar Function with Error Handling
-------------------------------------------------
/*
  5.1 dbo.SafeDivide: Divides two numbers and returns NULL if division by zero is attempted.
*/
CREATE FUNCTION dbo.SafeDivide(@Numerator FLOAT, @Denominator FLOAT)
RETURNS FLOAT
AS
BEGIN
    IF @Denominator = 0
        RETURN NULL; -- Avoid division by zero
    RETURN @Numerator / @Denominator;
END;
GO

-------------------------------------------------
-- Region: 6. Advanced Table-Valued Function Using JSON
-------------------------------------------------
/*
  6.1 dbo.GetAnimalsFromJSON: Parses JSON input and returns a table of animal records.
  Expected JSON format: An array of objects with properties "Name", "Type", and "Age".
*/
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

-------------------------------------------------
-- Region: 7. Advanced Function Using CASE Expression
-------------------------------------------------
/*
  7.1 dbo.GetAnimalAgeCategory: Returns an age category based on the input age.
*/
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

-------------------------------------------------
-- Region: 8. Advanced Function Using STRING_SPLIT
-------------------------------------------------
/*
  8.1 dbo.GetAnimalListFromString: Splits a comma-separated list of animal names into a table.
  Requires SQL Server 2016 or later.
*/
CREATE FUNCTION dbo.GetAnimalListFromString(@AnimalList NVARCHAR(MAX))
RETURNS @Animals TABLE
(
    [Name] NVARCHAR(60)
)
AS
BEGIN
    INSERT INTO @Animals ([Name])
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@AnimalList, ',');
    RETURN;
END;
GO

-------------------------------------------------
-- Region: 9. Function Using STRING_AGG
-------------------------------------------------
/*
  9.1 dbo.GetAnimalNamesByType: Aggregates animal names of a specific type into a single string.
  Requires SQL Server 2017 or later.
*/
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

-------------------------------------------------
-- Region: 10. Function with Dynamic Data Masking
-------------------------------------------------
/*
  10.1 dbo.MaskAnimalName: Masks an animal name by revealing only the first character.
  Requires SQL Server 2022 or later.
*/
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

-------------------------------------------------
-- Region: 11. Example Query Using APPLY with a Function
-------------------------------------------------
/*
  11.1 Example query: Uses CROSS APPLY with dbo.GetAnimalNamesByType to retrieve aggregated names.
*/
SELECT 
    a.[Name], 
    a.[Type], 
    a.[Age], 
    d.AnimalNames
FROM dbo.Animals a
CROSS APPLY (SELECT dbo.GetAnimalNamesByType(a.[Type])) d(AnimalNames);
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
