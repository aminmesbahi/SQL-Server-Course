-------------------------------------
-- Search Conditions and Predicates (Transact-SQL)
-------------------------------------

USE TestDB;
GO

-- Create a sample table
CREATE TABLE dbo.Documents
(
    DocumentID INT PRIMARY KEY,
    Title NVARCHAR(100),
    Content NVARCHAR(MAX)
);
GO

-- Insert sample data
INSERT INTO dbo.Documents (DocumentID, Title, Content)
VALUES
    (1, 'Document 1', 'This is the content of document 1.'),
    (2, 'Document 2', 'This is the content of document 2.'),
    (3, 'Document 3', 'This is the content of document 3.'),
    (4, 'Document 4', 'This is the content of document 4.'),
    (5, 'Document 5', 'This is the content of document 5.');
GO

-- Full-Text Index Setup
-- Create a full-text catalog
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
GO

-- Create a full-text index on the Content column
CREATE FULLTEXT INDEX ON dbo.Documents(Content) KEY INDEX PK_Documents ON ftCatalog;
GO

-- CONTAINS (Transact-SQL)
-- Search for documents containing the word 'content'
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE CONTAINS(Content, 'content');
GO

-- FREETEXT (Transact-SQL)
-- Search for documents containing the phrase 'content of document'
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE FREETEXT(Content, 'content of document');
GO

-- IS [NOT] DISTINCT FROM (Transact-SQL)
-- Create a sample table for IS [NOT] DISTINCT FROM
CREATE TABLE dbo.SampleData
(
    ID INT PRIMARY KEY,
    Value1 INT,
    Value2 INT
);
GO

-- Insert sample data
INSERT INTO dbo.SampleData (ID, Value1, Value2)
VALUES
    (1, 10, 10),
    (2, 20, NULL),
    (3, NULL, 30),
    (4, NULL, NULL),
    (5, 40, 40);
GO

-- Query using IS DISTINCT FROM
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS DISTINCT FROM Value2;
GO

-- Query using IS NOT DISTINCT FROM
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS NOT DISTINCT FROM Value2;
GO

-- IS NULL (Transact-SQL)
-- Query to find rows where Value1 is NULL
SELECT ID, Value1, Value2
FROM dbo.SampleData
WHERE Value1 IS NULL;
GO

-- BETWEEN (Transact-SQL)
-- Query to find documents with DocumentID between 2 and 4
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID BETWEEN 2 AND 4;
GO

-- EXISTS (Transact-SQL)
-- Query to find documents where a related record exists in SampleData
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE EXISTS (SELECT 1 FROM dbo.SampleData WHERE SampleData.ID = Documents.DocumentID);
GO

-- IN (Transact-SQL)
-- Query to find documents with DocumentID in a specific list
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID IN (1, 3, 5);
GO

-- LIKE (Transact-SQL)
-- Query to find documents with Title starting with 'Document'
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE Title LIKE 'Document%';
GO

-- Search condition (Transact-SQL)
-- Query using multiple search conditions
SELECT DocumentID, Title, Content
FROM dbo.Documents
WHERE DocumentID BETWEEN 1 AND 3
  AND Title LIKE 'Document%'
  AND EXISTS (SELECT 1 FROM dbo.SampleData WHERE SampleData.ID = Documents.DocumentID);
GO