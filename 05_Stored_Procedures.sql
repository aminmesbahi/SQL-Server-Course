/**************************************************************
 * SQL Server 2022 Stored Procedures Tutorial
 * Description: This script demonstrates creating stored 
 *              procedures for various scenarios including 
 *              simple queries, error handling, table-valued 
 *              parameters (TVP), native compilation, output 
 *              parameters, and handling XML/JSON inputs.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you're using the target database for stored procedure operations.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Simple Stored Procedure
-------------------------------------------------
/*
  1.1 GetAnimalByName: Returns animal information based on a provided name.
*/
CREATE PROCEDURE GetAnimalByName
    @Name NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;  -- Suppress unnecessary messages for performance.
    SELECT [Name]
    FROM dbo.Animals
    WHERE [Name] = @Name;
END;
GO

-------------------------------------------------
-- Region: 2. Complex Stored Procedure with Error Handling
-------------------------------------------------
/*
  2.1 AddAnimal: Inserts a new animal record and returns error details if insertion fails.
  Note: Ensure the dbo.Animals table has columns [Name], [Type], and [Age].
*/
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

-------------------------------------------------
-- Region: 3. Stored Procedure with Table-Valued Parameter (TVP)
-------------------------------------------------
/*
  3.1 Create a table type to be used as a TVP.
*/
IF TYPE_ID(N'AnimalTableType') IS NOT NULL
    DROP TYPE AnimalTableType;
GO

CREATE TYPE AnimalTableType AS TABLE
(
    [Name] NVARCHAR(60),
    [Type] NVARCHAR(60),
    [Age] INT
);
GO

/*
  3.2 AddAnimals: Inserts multiple animal records using a TVP.
*/
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

-------------------------------------------------
-- Region: 4. Native Stored Procedure
-------------------------------------------------
/*
  4.1 GetAnimalsByType: Retrieves animals by type using native compilation.
  Note: Native compiled stored procedures require specific database settings.
*/
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

-------------------------------------------------
-- Region: 5. Stored Procedure with Output Parameter
-------------------------------------------------
/*
  5.1 GetAnimalCountByType: Returns the count of animals for a given type.
*/
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

-------------------------------------------------
-- Region: 6. Stored Procedure with XML Parameter
-------------------------------------------------
/*
  6.1 AddAnimalFromXML: Parses XML input to insert an animal record.
  Expected XML format:
  <Animal>
      <Name>...</Name>
      <Type>...</Type>
      <Age>...</Age>
  </Animal>
*/
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

-------------------------------------------------
-- Region: 7. Stored Procedure with JSON Parameter
-------------------------------------------------
/*
  7.1 AddAnimalFromJSON: Parses JSON input to insert an animal record.
  Expected JSON format:
  {"Name": "...", "Type": "...", "Age": ...}
*/
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

-------------------------------------------------
-- Region: 8. Stored Procedure with Transactions and Error Handling
-------------------------------------------------
/*
  8.1 TransferAnimal: Updates the type of an animal using transactions.
  Rolls back if an error occurs or if no matching record is found.
*/
CREATE PROCEDURE TransferAnimal
    @AnimalId INT,
    @NewType NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Update the animal type
        UPDATE dbo.Animals
        SET [Type] = @NewType
        WHERE Id = @AnimalId;

        -- Check if any row was affected; if not, raise an error.
        IF @@ROWCOUNT = 0
        BEGIN
            THROW 50000, 'No animal found with the provided Id.', 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

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

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
