-------------------------------------
-- 7: Triggers
-------------------------------------

USE TestDB;
GO

-- Simple DML trigger for INSERT
CREATE TRIGGER trgAfterInsertAnimals
ON dbo.Animals
AFTER INSERT
AS
BEGIN
    PRINT 'A new animal has been added.';
    SELECT * FROM inserted;
END;
GO

-- Simple DML trigger for UPDATE
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

-- Simple DML trigger for DELETE
CREATE TRIGGER trgAfterDeleteAnimals
ON dbo.Animals
AFTER DELETE
AS
BEGIN
    PRINT 'An animal record has been deleted.';
    SELECT * FROM deleted;
END;
GO

-- Complex DML trigger with error handling
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

-- DDL trigger for CREATE TABLE
CREATE TRIGGER trgAfterCreateTable
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    PRINT 'A new table has been created.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

-- DDL trigger for ALTER TABLE
CREATE TRIGGER trgAfterAlterTable
ON DATABASE
FOR ALTER_TABLE
AS
BEGIN
    PRINT 'A table has been altered.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

-- DDL trigger for DROP TABLE
CREATE TRIGGER trgAfterDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'A table has been dropped.';
    SELECT EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)') AS TableName;
END;
GO

-- Advanced DML trigger using JSON
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

-- Advanced DML trigger using SQL Server 2022 features
CREATE TRIGGER trgAfterInsertAnimals2022
ON dbo.Animals
AFTER INSERT
AS
BEGIN
    DECLARE @AnimalData NVARCHAR(MAX);
    SELECT @AnimalData = (SELECT * FROM inserted FOR JSON AUTO);
    
    -- Use new SQL Server 2022 feature: JSON_OBJECT
    DECLARE @AnimalJson NVARCHAR(MAX) = JSON_OBJECT('AnimalData' VALUE @AnimalData);
    PRINT 'New animal record inserted: ' + @AnimalJson;
END;
GO

-- Advanced DDL trigger for auditing
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

-- Create audit table
CREATE TABLE dbo.DDLAudit
(
    AuditID INT IDENTITY PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(128),
    EventData XML,
    EventTime DATETIME
);
GO