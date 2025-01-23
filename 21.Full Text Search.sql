-------------------------------------
-- Full-Text Search with FREETEXTTABLE and CONTAINSTABLE
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

-- FREETEXTTABLE (Transact-SQL)
-- Search for documents containing the phrase 'content of document'
SELECT DocumentID, Title, Content, RANK
FROM FREETEXTTABLE(dbo.Documents, Content, 'content of document') AS ft
JOIN dbo.Documents AS d ON ft.[KEY] = d.DocumentID
ORDER BY RANK DESC;
GO

-- CONTAINSTABLE (Transact-SQL)
-- Search for documents containing the word 'content'
SELECT DocumentID, Title, Content, RANK
FROM CONTAINSTABLE(dbo.Documents, Content, 'content') AS ct
JOIN dbo.Documents AS d ON ct.[KEY] = d.DocumentID
ORDER BY RANK DESC;
GO