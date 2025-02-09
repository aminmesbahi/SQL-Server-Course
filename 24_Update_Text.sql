-------------------------------------
-- UPDATETEXT (Transact-SQL)
-------------------------------------

USE TestDB;
GO

-- Create a sample table with TEXT data type
CREATE TABLE dbo.TextData
(
    ID INT PRIMARY KEY,
    Content TEXT
);
GO

-- Insert sample data
INSERT INTO dbo.TextData (ID, Content)
VALUES
    (1, 'This is the original content of the text data.'),
    (2, 'Another piece of text data for testing.');
GO

-- UPDATETEXT to update a portion of the text data
-- Update the first record by replacing 'original' with 'updated'
DECLARE @ptrval BINARY(16);
SELECT @ptrval = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 1;
UPDATETEXT dbo.TextData.Content @ptrval 10 8 'updated';
GO

-- Verify the update
SELECT ID, Content
FROM dbo.TextData;
GO

-- UPDATETEXT to insert text into the text data
-- Insert 'additional ' at position 10 in the second record
DECLARE @ptrval BINARY(16);
SELECT @ptrval = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 2;
UPDATETEXT dbo.TextData.Content @ptrval 10 0 'additional ';
GO

-- Verify the update
SELECT ID, Content
FROM dbo.TextData;
GO

-- UPDATETEXT to delete a portion of the text data
-- Delete 'additional ' from the second record
DECLARE @ptrval BINARY(16);
SELECT @ptrval = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 2;
UPDATETEXT dbo.TextData.Content @ptrval 10 10 NULL;
GO

-- Verify the update
SELECT ID, Content
FROM dbo.TextData;
GO

-- UPDATETEXT to append text to the end of the text data
-- Append ' Appended text.' to the first record
DECLARE @ptrval BINARY(16);
SELECT @ptrval = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 1;
UPDATETEXT dbo.TextData.Content @ptrval NULL 0 ' Appended text.';
GO

-- Verify the update
SELECT ID, Content
FROM dbo.TextData;
GO

-- Clean up the sample table
DROP TABLE dbo.TextData;
GO