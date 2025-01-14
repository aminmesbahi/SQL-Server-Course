-------------------------------------
-- 5: Stored Procedures
-------------------------------------

USE TestDB;
GO

-- Simple stored procedure
CREATE PROCEDURE GetAnimalByName
    @Name NVARCHAR(60)
AS
BEGIN
    SELECT [Name]
    FROM dbo.Animals
    WHERE [Name] = @Name;
END;
GO

-- Complex stored procedure with multiple parameters and error handling
CREATE PROCEDURE AddAnimal
    @Name NVARCHAR(60),
    @Type NVARCHAR(60),
    @Age INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.Animals ([Name], [Type], [Age])
        VALUES (@Name, @Type, @Age);
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

-- Stored procedure with Table-Valued Parameter (TVP)
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
    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    SELECT [Name], [Type], [Age]
    FROM @Animals;
END;
GO

-- Native stored procedure
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

-- Stored procedure with output parameter
CREATE PROCEDURE GetAnimalCountByType
    @Type NVARCHAR(60),
    @Count INT OUTPUT
AS
BEGIN
    SELECT @Count = COUNT(*)
    FROM dbo.Animals
    WHERE [Type] = @Type;
END;
GO

-- Stored procedure with XML parameter
CREATE PROCEDURE AddAnimalFromXML
    @AnimalData XML
AS
BEGIN
    DECLARE @Name NVARCHAR(60), @Type NVARCHAR(60), @Age INT;
    
    SET @Name = @AnimalData.value('(/Animal/Name)[1]', 'NVARCHAR(60)');
    SET @Type = @AnimalData.value('(/Animal/Type)[1]', 'NVARCHAR(60)');
    SET @Age = @AnimalData.value('(/Animal/Age)[1]', 'INT');
    
    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    VALUES (@Name, @Type, @Age);
END;
GO

-- Stored procedure with JSON parameter
CREATE PROCEDURE AddAnimalFromJSON
    @AnimalData NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Name NVARCHAR(60), @Type NVARCHAR(60), @Age INT;
    
    SET @Name = JSON_VALUE(@AnimalData, '$.Name');
    SET @Type = JSON_VALUE(@AnimalData, '$.Type');
    SET @Age = JSON_VALUE(@AnimalData, '$.Age');
    
    INSERT INTO dbo.Animals ([Name], [Type], [Age])
    VALUES (@Name, @Type, @Age);
END;
GO

-- Stored procedure with transaction
CREATE PROCEDURE TransferAnimal
    @AnimalId INT,
    @NewType NVARCHAR(60)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE dbo.Animals
        SET [Type] = @NewType
        WHERE Id = @AnimalId;
        
        -- Simulate some other operations
        -- ...
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO