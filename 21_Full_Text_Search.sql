/**************************************************************
 * SQL Server 2022 Full-Text Search Tutorial:
 * FREETEXTTABLE and CONTAINSTABLE with Semantic Search,
 * Thesaurus, Statistics, and Security
 * Description: This script demonstrates full-text search using
 *              FREETEXTTABLE and CONTAINSTABLE. It covers:
 *              - Creating a modern, optimized table with compression
 *                and security.
 *              - Inserting a large dataset using GENERATE_SERIES.
 *              - Creating a full-text catalog and advanced full-text index
 *                with semantic search enabled.
 *              - Configuring thesaurus for synonym expansion.
 *              - Security configuration for search users.
 *              - Performing advanced full-text searches including:
 *                  * FREETEXTTABLE with security filtering.
 *                  * Semantic search with key phrase extraction.
 *                  * CONTAINSTABLE with proximity search and weighting.
 *              - Performance statistics and index maintenance.
 *              - Error handling for full-text search queries.
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
-- Region: 1. Creating the Optimized Documents Table
-------------------------------------------------
/*
  1.1 Drop the Documents table if it exists.
*/
DROP TABLE IF EXISTS dbo.Documents;
GO

/*
  1.2 Create the Documents table with modern features:
       - Memory-optimized and compressed storage.
       - A nonclustered index on the Content column with data compression.
*/
CREATE TABLE dbo.Documents
(
    DocumentID INT PRIMARY KEY,
    Title NVARCHAR(255),
    Content NVARCHAR(MAX),
    FileExtension NVARCHAR(10),
    SecurityLevel INT DEFAULT 1,
    IndexedDate DATETIME2 DEFAULT GETDATE(),
    INDEX idx_Content_FT (Content) WITH (DATA_COMPRESSION = PAGE)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

-------------------------------------------------
-- Region: 2. Inserting a Large Dataset using GENERATE_SERIES
-------------------------------------------------
/*
  2.1 Insert 10,000 documents using the new GENERATE_SERIES function.
       For each row, generate random keywords and choose file extensions.
*/
INSERT INTO dbo.Documents (DocumentID, Title, Content, FileExtension)
SELECT 
    n AS DocumentID,
    CONCAT('Document ', n) AS Title,
    CONCAT(
        'This document discusses ', 
        CASE WHEN n % 5 = 0 THEN 'SQL Server 2022' ELSE 'database management' END,
        ' and ', 
        CASE WHEN n % 3 = 0 THEN 'full-text search capabilities' ELSE 'data analysis' END,
        '. Keywords: ', STRING_AGG(CONVERT(NVARCHAR(MAX), NEWID()), ', ')
    ) AS Content,
    CASE WHEN n % 4 = 0 THEN '.docx' ELSE '.pdf' END AS FileExtension
FROM GENERATE_SERIES(1, 10000) AS s(n)
CROSS APPLY (SELECT TOP 5 NEWID() FROM sys.objects) AS k(keys);
GO

-------------------------------------------------
-- Region: 3. Creating Full-Text Catalog and Advanced Full-Text Index
-------------------------------------------------
/*
  3.1 Create a full-text catalog with accent sensitivity enabled.
*/
CREATE FULLTEXT CATALOG ftCatalog 
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT;
GO

/*
  3.2 Create an advanced full-text index on the Documents table.
       Enable statistical semantics for semantic search and specify a stoplist
       and search property list using the system defaults.
*/
CREATE FULLTEXT INDEX ON dbo.Documents
(
    Title LANGUAGE 1033,
    Content LANGUAGE 1033 STATISTICAL_SEMANTICS
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

-------------------------------------------------
-- Region: 4. Thesaurus and Security Configuration for Search
-------------------------------------------------
/*
  4.1 Load the full-text thesaurus for synonym expansion.
*/
EXEC sys.sp_fulltext_load_thesaurus_file 1033;
GO

/*
  4.2 Create a role for search users and grant necessary permissions.
*/
CREATE ROLE SearchUsers;
GRANT SELECT ON dbo.Documents TO SearchUsers;
GRANT REFERENCES ON FULLTEXT CATALOG::ftCatalog TO SearchUsers;
GO

-------------------------------------------------
-- Region: 5. Advanced Full-Text Search Queries
-------------------------------------------------
/*
  5.1 FREETEXTTABLE with a security filter:
       Search for documents related to 'database management system' and filter
       results based on SecurityLevel.
*/
SELECT 
    d.DocumentID,
    d.Title,
    d.Content,
    ftt.RANK,
    d.SecurityLevel
FROM FREETEXTTABLE(dbo.Documents, (Title, Content), 'database management system') AS ftt
INNER JOIN dbo.Documents AS d 
    ON ftt.[KEY] = d.DocumentID
WHERE d.SecurityLevel <= 1
ORDER BY ftt.RANK DESC
OPTION (USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'));
GO

/*
  5.2 Semantic search with key phrase extraction:
       Retrieve key phrases and scores from the semantic search DMV.
*/
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

/*
  5.3 CONTAINSTABLE with proximity search and weighting:
       Use a search term that combines thesaurus and inflectional forms.
*/
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

-------------------------------------------------
-- Region: 6. Performance Statistics Comparison
-------------------------------------------------
/*
  6.1 Enable performance statistics for I/O and time.
*/
SET STATISTICS TIME, IO ON;

/*
  6.2 Compare FREETEXTTABLE and CONTAINSTABLE performance.
*/
SELECT * FROM FREETEXTTABLE(dbo.Documents, Content, 'security configuration');
SELECT * FROM CONTAINSTABLE(dbo.Documents, Content, '"security" AND "configuration"');

SET STATISTICS TIME, IO OFF;
GO

-------------------------------------------------
-- Region: 7. Full-Text Index Maintenance and DMV Statistics
-------------------------------------------------
/*
  7.1 Start an update population for the full-text index.
*/
ALTER FULLTEXT INDEX ON dbo.Documents START UPDATE POPULATION;
GO

/*
  7.2 Retrieve full-text index statistics from DMVs.
*/
SELECT 
    ftsi.index_id,
    ftsi.row_count,
    ftsi.unique_key_count,
    ftsi.status,
    ftsi.language_id,
    ftsi.crawl_type_desc
FROM sys.dm_fts_index_population AS ftsi;
GO

-------------------------------------------------
-- Region: 8. Error Handling for Full-Text Search
-------------------------------------------------
/*
  8.1 Use TRY/CATCH to handle errors in full-text search queries.
*/
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

-------------------------------------------------
-- Region: 9. Cleanup
-------------------------------------------------
/*
  Clean up by dropping the full-text index, catalog, and search role.
*/
DROP FULLTEXT INDEX IF EXISTS ON dbo.Documents;
DROP FULLTEXT CATALOG IF EXISTS ftCatalog;
DROP ROLE IF EXISTS SearchUsers;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
