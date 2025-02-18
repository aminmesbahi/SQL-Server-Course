/**************************************************************
 * SQL Server 2022 Search Conditions and Predicates Tutorial
 * Description: This script demonstrates various search conditions
 *              and predicates in Transact-SQL, including full-text
 *              search, IS [NOT] DISTINCT FROM, IS NULL, BETWEEN,
 *              EXISTS, IN, LIKE, and combining multiple conditions.
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
-- Region: 1. Creating and Populating the Documents Table
-------------------------------------------------
/*
  1.1 Create the Documents table to store document data.
*/
IF OBJECT_ID(N'dbo.Documents', N'U') IS NOT NULL
    DROP TABLE dbo.Documents;
GO

CREATE TABLE dbo.Documents
(
    DocumentID INT PRIMARY KEY,
    Title NVARCHAR(100),
    Content NVARCHAR(MAX)
);
GO

/*
  1.2 Insert sample document data.
*/
INSERT INTO dbo.Documents (DocumentID, Title, Content)
VALUES
    (1, 'Document 1', 'This is the content of document 1.'),
    (2, 'Document 2', 'This is the content of document 2.'),
    (3, 'Document 3', 'This is the content of document 3.'),
    (4, 'Document 4', 'This is the content of document 4.'),
    (5, 'Document 5', 'This is the content of document 5.');
GO

-------------------------------------------------
-- Region: 2. Full-Text Search Setup and Queries
-------------------------------------------------
/*
  2.1 Create a full-text catalog (set as default).
*/
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
GO

/*
  2.2 Create a full-text index on the Content column of the Documents table.
       Note: Ensure that the primary key index exists.
*/
CREATE FULLTEXT INDEX ON dbo.Documents(Content) KEY INDEX PK_Documents ON ftCatalog;
GO

/*
  2.3 Use CONTAINS to search for documents containing the word 'content'.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE CONTAINS(Content, 'content');
GO

/*
  2.4 Use FREETEXT to search for documents containing the phrase 'content of document'.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE FREETEXT(Content, 'content of document');
GO

-------------------------------------------------
-- Region: 3. Demonstrating IS [NOT] DISTINCT FROM
-------------------------------------------------
/*
  3.1 Create a sample table for demonstrating IS [NOT] DISTINCT FROM.
*/
IF OBJECT_ID(N'dbo.SampleData', N'U') IS NOT NULL
    DROP TABLE dbo.SampleData;
GO

CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Value1 INT,
    Value2 INT
);
GO

/*
  3.2 Insert sample data.
*/
INSERT INTO dbo.SampleData (ID, Value1, Value2)
VALUES
    (1, 10, 10),
    (2, 20, NULL),
    (3, NULL, 30),
    (4, NULL, NULL),
    (5, 40, 40);
GO

/*
  3.3 Query using IS DISTINCT FROM to return rows where Value1 and Value2 differ.
*/
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS DISTINCT FROM Value2;
GO

/*
  3.4 Query using IS NOT DISTINCT FROM to return rows where Value1 and Value2 are the same.
*/
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS NOT DISTINCT FROM Value2;
GO

-------------------------------------------------
-- Region: 4. Other Predicates: IS NULL, BETWEEN, EXISTS, IN, LIKE
-------------------------------------------------
/*
  4.1 IS NULL: Find rows in SampleData where Value1 is NULL.
*/
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS NULL;
GO

/*
  4.2 BETWEEN: Find documents with DocumentID between 2 and 4.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID BETWEEN 2 AND 4;
GO

/*
  4.3 EXISTS: Find documents where a related record exists in SampleData.
       (Here, we assume matching IDs for demonstration.)
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE EXISTS (SELECT 1 FROM dbo.SampleData WHERE dbo.SampleData.ID = dbo.Documents.DocumentID);
GO

/*
  4.4 IN: Find documents with DocumentID in a specified list.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID IN (1, 3, 5);
GO

/*
  4.5 LIKE: Find documents with a Title starting with 'Document'.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE Title LIKE 'Document%';
GO

/*
  4.6 Combining Multiple Search Conditions:
       Retrieve documents with DocumentID between 1 and 3, Title starting with 'Document',
       and where a related record exists in SampleData.
*/
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID BETWEEN 1 AND 3
  AND Title LIKE 'Document%'
  AND EXISTS (SELECT 1 FROM dbo.SampleData WHERE dbo.SampleData.ID = dbo.Documents.DocumentID);
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
