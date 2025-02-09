-------------------------------------
-- Full-Text Search with FREETEXTTABLE and CONTAINSTABLE
-- Includes: Semantic Search, Thesaurus, Statistics, and Security
-------------------------------------

USE TestDB;
GO

-- Modern table with compression and security
DROP TABLE IF EXISTS dbo.Documents;
CREATE TABLE dbo.Documents
(
    DocumentID INT PRIMARY KEY,
    Title NVARCHAR(255),
    Content NVARCHAR(MAX),
    FileExtension NVARCHAR(10),
    SecurityLevel INT DEFAULT 1,
    IndexedDate DATETIME2 DEFAULT GETDATE(),
    INDEX idx_Content_FT (Content) WITH (DATA_COMPRESSION = PAGE)
);
GO

-- Insert larger dataset using GENERATE_SERIES (2022 feature)
INSERT INTO dbo.Documents (DocumentID, Title, Content, FileExtension)
SELECT 
    n AS DocumentID,
    CONCAT('Document ', n),
    CONCAT(
        'This document discusses ', 
        CASE WHEN n % 5 = 0 THEN 'SQL Server 2022' ELSE 'database management' END,
        ' and ', 
        CASE WHEN n % 3 = 0 THEN 'full-text search capabilities' ELSE 'data analysis' END,
        '. Keywords: ', STRING_AGG(CONVERT(NVARCHAR(max), NEWID()), ', ') 
    ),
    CASE WHEN n % 4 = 0 THEN '.docx' ELSE '.pdf' END
FROM GENERATE_SERIES(1, 10000) AS s(n)
CROSS APPLY (SELECT TOP 5 NEWID() FROM sys.objects) AS k(keys);
GO

-- Create modern full-text catalog with security
CREATE FULLTEXT CATALOG ftCatalog 
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT;
GO

-- Advanced full-text index with stoplist and search property list
CREATE FULLTEXT INDEX ON dbo.Documents
(
    Title LANGUAGE 1033,
    Content LANGUAGE 1033 
        STATISTICAL_SEMANTICS  -- Enable semantic search
)
KEY INDEX PK_Documents
ON ftCatalog
WITH 
(
    STOPLIST = SYSTEM,
    SEARCH PROPERTY LIST = SYSTEM,
    CHANGE_TRACKING AUTO,
    DATA_COMPRESSION = PAGE
);
GO

-- Configure thesaurus for synonym expansion (2022 improvements)
EXEC sys.sp_fulltext_load_thesaurus_file 1033;
GO

-- Security configuration for search
CREATE ROLE SearchUsers;
GRANT SELECT ON dbo.Documents TO SearchUsers;
GRANT REFERENCES ON FULLTEXT CATALOG::ftCatalog TO SearchUsers;
GO

-- Advanced FREETEXTTABLE with security filter
SELECT 
    d.DocumentID,
    d.Title,
    d.Content,
    ftt.RANK,
    d.SecurityLevel
FROM FREETEXTTABLE(dbo.Documents, (Title, Content), 'database management system') AS ftt
INNER JOIN dbo.Documents AS d 
    ON ftt.[KEY] = d.DocumentID
WHERE d.SecurityLevel <= 1  -- Row-level security
ORDER BY ftt.RANK DESC
OPTION (USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'));
GO

-- Semantic search with key phrase extraction
SELECT 
    doc.DocumentID,
    doc.Title,
    ssp.key_phrase,
    ssp.score
FROM sys.dm_fts_semantic_keyphrase_by_document('default') AS ssp
JOIN dbo.Documents doc 
    ON ssp.document_id = doc.DocumentID
WHERE ssp.key_phrase LIKE '%database%'
ORDER BY ssp.score DESC;
GO

-- CONTAINSTABLE with proximity search and weighting
DECLARE @SearchTerm NVARCHAR(100) = N'FORMSOF(THESAURUS, "search") NEAR FORMSOF(INFLECTIONAL, "manage")';

SELECT 
    d.DocumentID,
    d.Title,
    ct.RANK,
    DATALENGTH(d.Content)/1024 AS SizeKB,
    ct.[KEY]
FROM CONTAINSTABLE(dbo.Documents, (Title, Content), @SearchTerm) AS ct
INNER JOIN dbo.Documents AS d 
    ON ct.[KEY] = d.DocumentID
WHERE d.FileExtension = '.pdf'
ORDER BY ct.RANK DESC;
GO

-- Full-text search performance statistics
SET STATISTICS TIME, IO ON;

-- FREETEXT vs CONTAINS comparison
SELECT * FROM FREETEXTTABLE(dbo.Documents, Content, 'security configuration');
SELECT * FROM CONTAINSTABLE(dbo.Documents, Content, '"security" AND "configuration"');

SET STATISTICS TIME, IO OFF;
GO

-- Full-text index maintenance
ALTER FULLTEXT INDEX ON dbo.Documents START UPDATE POPULATION;
GO

-- Index statistics using DMVs
SELECT 
    ftsi.index_id,
    ftsi.row_count,
    ftsi.unique_key_count,
    ftsi.status,
    ftsi.language_id,
    ftsi.crawl_type_desc
FROM sys.dm_fts_index_population AS ftsi;
GO

-- Error handling for full-text search
BEGIN TRY
    SELECT * FROM CONTAINSTABLE(dbo.Documents, Content, '"invalid:operator"');
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorCode,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity;
END CATCH;
GO

-- Cleanup with modern syntax
DROP FULLTEXT INDEX IF EXISTS ON dbo.Documents;
DROP FULLTEXT CATALOG IF EXISTS ftCatalog;
DROP ROLE IF EXISTS SearchUsers;
GO