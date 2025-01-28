-- ===============================
-- 5: Stored Procedures
-- ===============================

USE TestDB;
GO

-- 5.1 Simple Stored Procedure
CREATE PROCEDURE GetAnimalByName
    @Name NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON; -- Improves performance by suppressing the DONE_IN_PROC messages.
    SELECT [Name]
    FROM dbo.Animals
    WHERE [Name] = @Name;
END;
GO

-- 5.2 Complex Stored Procedure with Error Handling
CREATE PROCEDURE AddAnimal
    @Name NVARCHAR(60),
    @Type NVARCHAR(60),
    @Age INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO dbo.Animals ([Name], [Type], [Age])
        VALUES (@Name, @Type, @Age);
    END TRY
    BEGIN CATCH
        -- Return detailed error information
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

-- 5.3 Stored Procedure with Table-Valued Parameter (TVP)
CREATE TYPE AnimalTableType AS TABLE
(
    [Name] NVARCHAR(60),
    [Type] NVARCHAR(60),
    [Age] INT
);
GO

CREATE PROCEDURE AddAnimals
    @Animals AnimalTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    SELECT [Name], [Type], [Age]
    FROM @Animals;
END;
GO

-- 5.4 Native Stored Procedure
CREATE PROCEDURE GetAnimalsByType
    @Type NVARCHAR(60)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english'
)
    SELECT [Name], [Age]
    FROM dbo.Animals
    WHERE [Type] = @Type;
END;
GO

-- 5.5 Stored Procedure with Output Parameter
CREATE PROCEDURE GetAnimalCountByType
    @Type NVARCHAR(60),
    @Count INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @Count = COUNT(*)
    FROM dbo.Animals
    WHERE [Type] = @Type;
END;
GO

-- 5.6 Stored Procedure with XML Parameter
CREATE PROCEDURE AddAnimalFromXML
    @AnimalData XML
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Name NVARCHAR(60), @Type NVARCHAR(60), @Age INT;

    SET @Name = @AnimalData.value('(/Animal/Name)[1]', 'NVARCHAR(60)');
    SET @Type = @AnimalData.value('(/Animal/Type)[1]', 'NVARCHAR(60)');
    SET @Age = @AnimalData.value('(/Animal/Age)[1]', 'INT');

    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    VALUES (@Name, @Type, @Age);
END;
GO

-- 5.7 Stored Procedure with JSON Parameter
CREATE PROCEDURE AddAnimalFromJSON
    @AnimalData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Name NVARCHAR(60), @Type NVARCHAR(60), @Age INT;

    SET @Name = JSON_VALUE(@AnimalData, '$.Name');
    SET @Type = JSON_VALUE(@AnimalData, '$.Type');
    SET @Age = JSON_VALUE(@AnimalData, '$.Age');

    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    VALUES (@Name, @Type, @Age);
END;
GO

-- 5.8 Stored Procedure with Transactions and Error Handling
CREATE PROCEDURE TransferAnimal
    @AnimalId INT,
    @NewType NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
