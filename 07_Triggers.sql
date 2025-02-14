/**************************************************************
 * SQL Server 2022 Triggers Tutorial
 * Description: This script demonstrates various types of triggers,
 *              including DML (AFTER, INSTEAD OF) and DDL triggers,
 *              along with advanced examples using JSON and SQL Server
 *              2022 features.
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
-- Region: 1. Simple DML Triggers
-------------------------------------------------
/*
  1.1 AFTER INSERT Trigger: Notifies when a new animal is added.
*/
CREATE TRIGGER trgAfterInsertAnimals
ON dbo.Animals
AFTER INSERT
AS
BEGIN
    PRINT 'A new animal has been added.';
    SELECT * FROM inserted;
END;
GO

/*
  1.2 AFTER UPDATE Trigger: Notifies when an animal record is updated.
*/
CREATE TRIGGER trgAfterUpdateAnimals
ON dbo.Animals
AFTER UPDATE
AS
BEGIN
    PRINT 'An animal record has been updated.';
    SELECT * FROM inserted;
    SELECT * FROM deleted;
END;
GO

/*
  1.3 AFTER DELETE Trigger: Notifies when an animal record is deleted.
*/
CREATE TRIGGER trgAfterDeleteAnimals
ON dbo.Animals
AFTER DELETE
AS
BEGIN
    PRINT 'An animal record has been deleted.';
    SELECT * FROM deleted;
END;
GO

-------------------------------------------------
-- Region: 2. Complex DML Trigger with Error Handling
-------------------------------------------------
/*
  2.1 INSTEAD OF INSERT Trigger: Checks for duplicates before insertion.
  If an animal with the same name exists, an error is raised.
*/
CREATE TRIGGER trgBeforeInsertAnimals
ON dbo.Animals
INSTEAD OF INSERT
AS
BEGIN
    BEGIN TRY
        DECLARE @Name NVARCHAR(60);
        SELECT @Name = [Name] FROM inserted;
        
        IF EXISTS (SELECT 1 FROM dbo.Animals WHERE [Name] = @Name)
        BEGIN
            RAISERROR('Animal with the same name already exists.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        INSERT INTO dbo.Animals ([Name])
        SELECT [Name] FROM inserted;
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred during insert operation.';
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

-------------------------------------------------
-- Region: 3. DDL Triggers for Schema Changes
-------------------------------------------------
/*
  3.1 DDL Trigger for CREATE TABLE events.
*/
CREATE TRIGGER trgAfterCreateTable
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    PRINT 'A new table has been created.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

/*
  3.2 DDL Trigger for ALTER TABLE events.
*/
CREATE TRIGGER trgAfterAlterTable
ON DATABASE
FOR ALTER_TABLE
AS
BEGIN
    PRINT 'A table has been altered.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

/*
  3.3 DDL Trigger for DROP TABLE events.
*/
CREATE TRIGGER trgAfterDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'A table has been dropped.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

-------------------------------------------------
-- Region: 4. Advanced DML Triggers with JSON and SQL Server 2022 Features
-------------------------------------------------
/*
  4.1 Advanced AFTER INSERT Trigger using JSON: Prints inserted rows as JSON.
*/
CREATE TRIGGER trgAfterInsertAnimalsJSON
ON dbo.Animals
AFTER INSERT
AS
BEGIN
    DECLARE @AnimalData NVARCHAR(MAX);
    SELECT @AnimalData = (SELECT * FROM inserted FOR JSON AUTO);
    PRINT 'New animal record inserted: ' + @AnimalData;
END;
GO

/*
  4.2 Advanced AFTER INSERT Trigger using SQL Server 2022 features:
       Uses JSON_OBJECT to format the inserted data.
*/
CREATE TRIGGER trgAfterInsertAnimals2022
ON dbo.Animals
AFTER INSERT
AS
BEGIN
    DECLARE @AnimalData NVARCHAR(MAX);
    SELECT @AnimalData = (SELECT * FROM inserted FOR JSON AUTO);
    
    -- Using SQL Server 2022 JSON_OBJECT feature for formatting
    DECLARE @AnimalJson NVARCHAR(MAX) = JSON_OBJECT('AnimalData' VALUE @AnimalData);
    PRINT 'New animal record inserted: ' + @AnimalJson;
END;
GO

-------------------------------------------------
-- Region: 5. Advanced DDL Trigger for Auditing Schema Changes
-------------------------------------------------
/*
  5.1 Create an audit table to log DDL changes.
*/
IF OBJECT_ID(N'dbo.DDLAudit', N'U') IS NOT NULL
    DROP TABLE dbo.DDLAudit;
GO

CREATE TABLE dbo.DDLAudit
(
    AuditID INT IDENTITY PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(128),
    EventData XML,
    EventTime DATETIME
);
GO

/*
  5.2 Advanced DDL Trigger: Audits CREATE_TABLE, ALTER_TABLE, and DROP_TABLE events.
*/
CREATE TRIGGER trgAuditDDLChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    DECLARE @EventData XML = EVENTDATA();
    INSERT INTO dbo.DDLAudit (EventType, ObjectName, EventData, EventTime)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)'),
        @EventData,
        GETDATE()
    );
    PRINT 'DDL change audited.';
END;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
