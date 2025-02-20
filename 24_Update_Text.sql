/**************************************************************
 * SQL Server 2022 UPDATETEXT Tutorial
 * Description: This script demonstrates how to use UPDATETEXT 
 *              to modify TEXT data in SQL Server. It covers:
 *              - Replacing a portion of text.
 *              - Inserting new text into existing data.
 *              - Deleting a portion of text.
 *              - Appending text to the end.
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
-- Region: 1. Creating and Populating the Sample Table
-------------------------------------------------
/*
  1.1 Create a sample table with a TEXT column.
*/
IF OBJECT_ID(N'dbo.TextData', N'U') IS NOT NULL
    DROP TABLE dbo.TextData;
GO

CREATE TABLE dbo.TextData
(
    ID INT PRIMARY KEY,
    Content TEXT
);
GO

/*
  1.2 Insert sample data into the table.
*/
INSERT INTO dbo.TextData (ID, Content)
VALUES
    (1, 'This is the original content of the text data.'),
    (2, 'Another piece of text data for testing.');
GO

-------------------------------------------------
-- Region: 2. UPDATETEXT: Replacing Text
-------------------------------------------------
/*
  2.1 Update the first record by replacing 'original' with 'updated'.
      - Retrieve the text pointer for the Content column.
      - Replace 8 characters starting at position 10 with 'updated'.
*/
DECLARE @ptrval BINARY(16);
SELECT @ptrval = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 1;
UPDATETEXT dbo.TextData.Content @ptrval 10 8 'updated';
GO

/*
  2.2 Verify the update.
*/
SELECT ID, Content
FROM dbo.TextData;
GO

-------------------------------------------------
-- Region: 3. UPDATETEXT: Inserting Text
-------------------------------------------------
/*
  3.1 Insert text into the second record:
      - Retrieve the text pointer.
      - Insert 'additional ' at position 10 (length=0 means insertion).
*/
DECLARE @ptrval2 BINARY(16);
SELECT @ptrval2 = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 2;
UPDATETEXT dbo.TextData.Content @ptrval2 10 0 'additional ';
GO

/*
  3.2 Verify the update.
*/
SELECT ID, Content
FROM dbo.TextData;
GO

-------------------------------------------------
-- Region: 4. UPDATETEXT: Deleting Text
-------------------------------------------------
/*
  4.1 Delete the inserted 'additional ' text from the second record:
      - Retrieve the text pointer.
      - Delete 10 characters starting at position 10.
*/
DECLARE @ptrval3 BINARY(16);
SELECT @ptrval3 = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 2;
UPDATETEXT dbo.TextData.Content @ptrval3 10 10 NULL;
GO

/*
  4.2 Verify the deletion.
*/
SELECT ID, Content
FROM dbo.TextData;
GO

-------------------------------------------------
-- Region: 5. UPDATETEXT: Appending Text
-------------------------------------------------
/*
  5.1 Append ' Appended text.' to the end of the first record:
      - Retrieve the text pointer.
      - Set the starting position to NULL (to append) with length 0.
*/
DECLARE @ptrval4 BINARY(16);
SELECT @ptrval4 = TEXTPTR(Content) FROM dbo.TextData WHERE ID = 1;
UPDATETEXT dbo.TextData.Content @ptrval4 NULL 0 ' Appended text.';
GO

/*
  5.2 Verify the appended text.
*/
SELECT ID, Content
FROM dbo.TextData;
GO

-------------------------------------------------
-- Region: 6. Cleanup
-------------------------------------------------
/*
  Clean up the sample table.
*/
DROP TABLE dbo.TextData;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
