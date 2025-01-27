-- ===============================
-- 4: Indices Part 1
-- ===============================

-- 4.1 Preparing the Sample Table
USE TestDB;
GO

-- Create a simple table and insert sample data
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

-- 4.2 Query Execution Plan Comparison
-- Before index creation: table scan
SELECT [Name] FROM dbo.Animals WHERE [Name] = N'Cat';
GO

-- Create a non-clustered index on the [Name] column
CREATE NONCLUSTERED INDEX IX_Animals_Name ON dbo.Animals([Name]);
GO

-- After index creation: index seek
SELECT [Name] FROM dbo.Animals WHERE [Name] = N'Cat';
GO

-- 4.3 Adding Identity Column and Index on ID
ALTER TABLE dbo.Animals ADD Id INT IDENTITY(1,1);
GO

-- Create a non-clustered index on [Id] with additional options
CREATE NONCLUSTERED INDEX IX_Animals_Id ON dbo.Animals(Id)
WITH (PAD_INDEX = ON, FILLFACTOR = 90, DROP_EXISTING = ON, ONLINE = ON, SORT_IN_TEMPDB = ON);
GO

-- Query using a predicate on [Id]
SELECT [Name] FROM dbo.Animals WHERE [Name] LIKE N'C%' AND Id > 5;
GO

-- 4.4 Index Maintenance
-- Rebuild an index
ALTER INDEX IX_Animals_Name ON dbo.Animals REBUILD WITH (ONLINE = ON);
GO

-- Reorganize all indices
ALTER INDEX ALL ON dbo.Animals REORGANIZE;
GO

-- 4.5 Checking Index Fragmentation
SELECT 
    OBJECT_NAME(ips.OBJECT_ID) AS TableName,
    i.NAME AS IndexName,
    ips.index_id,
    ips.page_count,
    ips.avg_fragmentation_in_percent,
    ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Animals'), NULL, NULL, 'DETAILED') ips
JOIN sys.indexes i ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id;
GO

-- 4.6 Advanced Index Types
-- 4.6.1 Memory-Optimized Table and Index
CREATE TABLE dbo.AnimalsMemoryOptimized
(
    Id INT IDENTITY PRIMARY KEY NONCLUSTERED,
    [Name] NVARCHAR(50) NOT NULL
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

-- Create a clustered columnstore index
CREATE CLUSTERED COLUMNSTORE INDEX IX_AnimalsMemoryOptimized_ColumnStore ON dbo.AnimalsMemoryOptimized;
GO

-- Create a filtered index
CREATE NONCLUSTERED INDEX IX_AnimalsMemoryOptimized_Filtered ON dbo.AnimalsMemoryOptimized([Name])
WHERE [Name] LIKE N'C%';
GO

-- 4.6.2 XML and JSON Indexing
CREATE TABLE dbo.AnimalsWithXMLJSON
(
    Id INT IDENTITY PRIMARY KEY,
    AnimalData XML,
    AnimalInfo NVARCHAR(MAX)
);
GO

-- Insert sample data for XML and JSON columns
INSERT INTO dbo.AnimalsWithXMLJSON (AnimalData, AnimalInfo)
VALUES
    (N'<Animal><Name>Cat</Name><Type>Mammal</Type></Animal>', N'{"Name": "Cat", "Type": "Mammal"}'),
    (N'<Animal><Name>Dog</Name><Type>Mammal</Type></Animal>', N'{"Name": "Dog", "Type": "Mammal"}');
GO

-- Create a primary XML index
CREATE PRIMARY XML INDEX IX_AnimalsWithXMLJSON_AnimalData ON dbo.AnimalsWithXMLJSON(AnimalData);
GO

-- Create a JSON index
CREATE NONCLUSTERED INDEX IX_AnimalsWithXMLJSON_AnimalInfo ON dbo.AnimalsWithXMLJSON(AnimalInfo)
WITH (PAD_INDEX = ON, FILLFACTOR = 90, DROP_EXISTING = ON, ONLINE = ON, SORT_IN_TEMPDB = ON);
GO

-- 4.7 Monitoring Index Statistics
-- Get page and record counts for indices
SELECT 
    OBJECT_NAME(ips.OBJECT_ID) AS TableName,
    i.NAME AS IndexName,
    ips.index_id,
    ips.page_count,
    ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.AnimalsWithXMLJSON'), NULL, NULL, 'DETAILED') ips
JOIN sys.indexes i ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id;
GO
