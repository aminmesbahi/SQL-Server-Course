/**************************************************************
 * SQL Server 2022 Indices Tutorial - Part 1
 * Description: This script demonstrates various indexing 
 *              techniques including basic non-clustered indexes, 
 *              index maintenance, advanced index types (memory-
 *              optimized, XML/JSON), and monitoring index 
 *              statistics.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Preparation and Environment Setup
-------------------------------------------------
/*
  Ensure you are using the target database for index operations.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Preparing the Sample Table
-------------------------------------------------
/*
  1.1 Create a sample table and insert data for indexing demonstrations.
  Note: Dropping the table if it already exists can be added for reusability.
*/
IF OBJECT_ID(N'dbo.Animals', N'U') IS NOT NULL
    DROP TABLE dbo.Animals;
GO

CREATE TABLE dbo.Animals
(
    [Name] NVARCHAR(60) NOT NULL
);
GO

INSERT INTO dbo.Animals ([Name])
VALUES
    (N'Dog'), (N'Puppy'), (N'Turtle'), (N'Rabbit'), (N'Parrot'), 
    (N'Cat'), (N'Kitten'), (N'Goldfish'), (N'Mouse'), (N'Tropical fish'),
    (N'Hamster'), (N'Cow'), (N'Rabbit'), (N'Ducks'), (N'Shrimp'),
    (N'Pig'), (N'Goat'), (N'Crab'), (N'Deer'), (N'Mouse'),
    (N'Bee'), (N'Sheep'), (N'Fish'), (N'Turkey'), (N'Dove'),
    (N'Chicken'), (N'Horse'), (N'Crow'), (N'Peacock'), (N'Dove'),
    (N'Sparrow'), (N'Goose'), (N'Stork'), (N'Pigeon'), (N'Turkey'),
    (N'Hawk'), (N'Bald eagle'), (N'Raven'), (N'Parrot'), (N'Flamingo'),
    (N'Seagull'), (N'Ostrich'), (N'Swallow'), (N'Black bird'),
    (N'Penguin'), (N'Robin'), (N'Swan'), (N'Owl'), (N'Woodpecker'),
    (N'Giraffe'), (N'Camel'), (N'Starfish'), (N'Koala'),
    (N'Alligator'), (N'Owl'), (N'Tiger'), (N'Bear'), (N'Blue whale'),
    (N'Coyote'), (N'Chimpanzee'), (N'Raccoon'), (N'Lion'),
    (N'Arctic wolf'), (N'Crocodile'), (N'Dolphin'), (N'Elephant'),
    (N'Squirrel'), (N'Snake'), (N'Kangaroo'), (N'Hippopotamus'),
    (N'Elk'), (N'Fox'), (N'Gorilla'), (N'Bat'), (N'Hare'),
    (N'Toad'), (N'Frog'), (N'Deer'), (N'Rat'), (N'Badger'),
    (N'Lizard'), (N'Mole'), (N'Hedgehog'), (N'Otter'), (N'Reindeer');
GO

-------------------------------------------------
-- Region: 2. Basic Indexing and Query Execution Plan Comparison
-------------------------------------------------
/*
  2.1 Execute a query before index creation.
  This should result in a table scan.
*/
SELECT [Name] 
FROM dbo.Animals 
WHERE [Name] = N'Cat';
GO

/*
  2.2 Create a non-clustered index on the [Name] column.
*/
CREATE NONCLUSTERED INDEX IX_Animals_Name 
ON dbo.Animals([Name]);
GO

/*
  2.3 Execute the same query after index creation.
  The query plan should now use an index seek.
*/
SELECT [Name] 
FROM dbo.Animals 
WHERE [Name] = N'Cat';
GO

-------------------------------------------------
-- Region: 3. Enhancing the Table with an Identity Column and Index on ID
-------------------------------------------------
/*
  3.1 Add an identity column to the table.
*/
ALTER TABLE dbo.Animals 
ADD Id INT IDENTITY(1,1);
GO

/*
  3.2 Create a non-clustered index on the [Id] column with additional options.
  Options explained:
    - PAD_INDEX: Padding index pages for better performance.
    - FILLFACTOR: Percentage of space to leave free on each page.
    - DROP_EXISTING: Replace the index if it already exists.
    - ONLINE: Allow concurrent access during index operation (Enterprise Edition).
    - SORT_IN_TEMPDB: Use tempdb to sort the index pages.
*/
CREATE NONCLUSTERED INDEX IX_Animals_Id 
ON dbo.Animals(Id)
WITH 
    (PAD_INDEX = ON, 
     FILLFACTOR = 90, 
     DROP_EXISTING = ON, 
     ONLINE = ON, 
     SORT_IN_TEMPDB = ON);
GO

/*
  3.3 Query using a predicate on [Name] and a filter on [Id]
  to illustrate composite index usage.
*/
SELECT [Name] 
FROM dbo.Animals 
WHERE [Name] LIKE N'C%' 
  AND Id > 5;
GO

-------------------------------------------------
-- Region: 4. Index Maintenance
-------------------------------------------------
/*
  4.1 Rebuild an index to remove fragmentation.
*/
ALTER INDEX IX_Animals_Name 
ON dbo.Animals 
REBUILD WITH (ONLINE = ON);
GO

/*
  4.2 Reorganize all indexes on the table.
*/
ALTER INDEX ALL 
ON dbo.Animals 
REORGANIZE;
GO

-------------------------------------------------
-- Region: 5. Checking Index Fragmentation
-------------------------------------------------
/*
  5.1 Query index fragmentation details using sys.dm_db_index_physical_stats.
*/
SELECT 
    OBJECT_NAME(ips.OBJECT_ID) AS TableName,
    i.NAME AS IndexName,
    ips.index_id,
    ips.page_count,
    ips.avg_fragmentation_in_percent,
    ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Animals'), NULL, NULL, 'DETAILED') AS ips
JOIN sys.indexes AS i 
    ON ips.OBJECT_ID = i.OBJECT_ID 
   AND ips.index_id = i.index_id;
GO

-------------------------------------------------
-- Region: 6. Advanced Index Types
-------------------------------------------------
/*
  6.1 Memory-Optimized Table and Index
*/
IF OBJECT_ID(N'dbo.AnimalsMemoryOptimized', N'U') IS NOT NULL
    DROP TABLE dbo.AnimalsMemoryOptimized;
GO

CREATE TABLE dbo.AnimalsMemoryOptimized
(
    Id INT IDENTITY PRIMARY KEY NONCLUSTERED,
    [Name] NVARCHAR(50) NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

/*
  Create a clustered columnstore index on the memory-optimized table.
*/
CREATE CLUSTERED COLUMNSTORE INDEX IX_AnimalsMemoryOptimized_ColumnStore 
ON dbo.AnimalsMemoryOptimized;
GO

/*
  Create a filtered non-clustered index on the memory-optimized table.
  This index includes only rows where [Name] starts with 'C'.
*/
CREATE NONCLUSTERED INDEX IX_AnimalsMemoryOptimized_Filtered 
ON dbo.AnimalsMemoryOptimized([Name])
WHERE [Name] LIKE N'C%';
GO

/*
  6.2 XML and JSON Indexing
*/
IF OBJECT_ID(N'dbo.AnimalsWithXMLJSON', N'U') IS NOT NULL
    DROP TABLE dbo.AnimalsWithXMLJSON;
GO

CREATE TABLE dbo.AnimalsWithXMLJSON
(
    Id INT IDENTITY PRIMARY KEY,
    AnimalData XML,
    AnimalInfo NVARCHAR(MAX)
);
GO

/*
  Insert sample data into the XML and JSON columns.
*/
INSERT INTO dbo.AnimalsWithXMLJSON (AnimalData, AnimalInfo)
VALUES
    (N'<Animal><Name>Cat</Name><Type>Mammal</Type></Animal>', 
     N'{"Name": "Cat", "Type": "Mammal"}'),
    (N'<Animal><Name>Dog</Name><Type>Mammal</Type></Animal>', 
     N'{"Name": "Dog", "Type": "Mammal"}');
GO

/*
  Create a primary XML index on the AnimalData column.
*/
CREATE PRIMARY XML INDEX IX_AnimalsWithXMLJSON_AnimalData 
ON dbo.AnimalsWithXMLJSON(AnimalData);
GO

/*
  Create a non-clustered JSON index on the AnimalInfo column.
*/
CREATE NONCLUSTERED INDEX IX_AnimalsWithXMLJSON_AnimalInfo 
ON dbo.AnimalsWithXMLJSON(AnimalInfo)
WITH 
    (PAD_INDEX = ON, 
     FILLFACTOR = 90, 
     DROP_EXISTING = ON, 
     ONLINE = ON, 
     SORT_IN_TEMPDB = ON);
GO

-------------------------------------------------
-- Region: 7. Monitoring Index Statistics for XML/JSON Table
-------------------------------------------------
/*
  7.1 Retrieve index page and record counts for the XML/JSON table.
*/
SELECT 
    OBJECT_NAME(ips.OBJECT_ID) AS TableName,
    i.NAME AS IndexName,
    ips.index_id,
    ips.page_count,
    ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.AnimalsWithXMLJSON'), NULL, NULL, 'DETAILED') AS ips
JOIN sys.indexes AS i 
    ON ips.OBJECT_ID = i.OBJECT_ID 
   AND ips.index_id = i.index_id;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
