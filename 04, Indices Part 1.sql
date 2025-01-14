-------------------------------------
-- 4: Indices Part 1
-------------------------------------

-- Preparing the sample
USE TestDB;
GO
CREATE TABLE Animals(
[Name] NVARCHAR(60) NOT NULL
);
GO
INSERT INTO dbo.Animals ([Name])
VALUES
  (N'Dog'), (N'Puppy'), (N'Turtle'), (N'Rabbit'), (N'Parrot'), (N'Cat'), (N'Kitten'), (N'Goldfish'), (N'Mouse'), (N'Tropical fish'), (N'Hamster')
 ,(N'Cow'), (N'Rabbit'), (N'Ducks'), (N'Shrimp'), (N'Pig'), (N'Goat'), (N'Crab'), (N'Deer'), (N'Mouse'), (N'Bee'), (N'Sheep')
 ,(N'Fish'), (N'Turkey'), (N'Dove'), (N'Chicken'), (N'Horse'), (N'Crow'), (N'Peacock'), (N'Dove'), (N'Sparrow'), (N'Goose')
 ,(N'Stork'), (N'Pigeon'), (N'Turkey'), (N'Hawk'), (N'Bald eagle'), (N'Raven'), (N'Parrot'), (N'Flamingo'), (N'Seagull'), (N'Ostrich')
 ,(N'Swallow'), (N'Black bird'), (N'Penguin'), (N'Robin'), (N'Swan'), (N'Owl'), (N'Woodpecker'), (N'Giraffe'), (N'Woodpecker'), (N'Camel')
 , (N'Starfish'), (N'Koala'), (N'Alligator'), (N'Owl'), (N'Tiger'), (N'Bear'), (N'Blue whale'), (N'Coyote'), (N'Chimpanzee'), (N'Raccoon')
 , (N'Lion'), (N'Arctic wolf'), (N'Crocodile'), (N'Dolphin'), (N'Elephant'), (N'Squirrel'), (N'Snake'), (N'Kangaroo'), (N'Hippopotamus'), (N'Elk')
 , (N'Fox'), (N'Gorilla'), (N'Bat'), (N'Hare'), (N'Toad'), (N'Frog'), (N'Deer'), (N'Rat'), (N'Badger'), (N'Lizard'), (N'Mole'), (N'Hedgehog')
 , (N'Otter'), (N'Reindeer');
GO


-- Press Ctrl+M to enable showing actual execution plan
-- check the Execution Plan after executing this query
SELECT [Name] FROM dbo.Animals
    WHERE [Name]=N'Cat'
GO

-- Now you can create an index
CREATE NONCLUSTERED INDEX IX_Animals_Name ON dbo.Animals([Name]);
GO

-- And check the Execution Plan again, after creating index in previous step
SELECT [Name] FROM dbo.Animals
    WHERE [Name]=N'Cat'
GO

-- Adding a new column to this table (Heap, because it doesn't have clustered index)
ALTER TABLE dbo.Animals ADD Id INT IDENTITY;
GO

-- Checking Execution Plan --> it changed to Table Scan
SELECT [Name] FROM dbo.Animals
    WHERE [Name] LIKE N'C%' AND Id > 5;
GO

-- Create new index using id column and options
CREATE NONCLUSTERED INDEX IX_Animals_Id ON dbo.Animals(Id)
    WITH (PAD_INDEX = ON, FILLFACTOR=90, DROP_EXISTING=ON, ONLINE=ON, SORT_IN_TEMPDB=ON -- in SQL Server 2019 you can use RESUMABLE=ON
    );
GO

-- Rebuilding Index
ALTER INDEX IX_Animals_Name ON dbo.Animals REBUILD WITH (ONLINE=ON);
GO

-- Reorganizing all Indices on a table
ALTER INDEX ALL ON dbo.Animals REORGANIZE;
GO

-- Get index fragmentation and free space
SELECT OBJECT_NAME(ips.OBJECT_ID)
 ,i.NAME
 ,ips.index_id
 ,index_type_desc
 ,ips.page_count
 ,ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Animals'), NULL, NULL, 'DETAILED') ips
JOIN sys.indexes i ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id;
GO

-- Create memory-optimized table
CREATE TABLE dbo.AnimalsMemoryOptimized
(
    Id INT IDENTITY PRIMARY KEY NONCLUSTERED,
    [Name] NVARCHAR(50) NOT NULL
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

-- Create columnstore index
CREATE CLUSTERED COLUMNSTORE INDEX IX_AnimalsMemoryOptimized_ColumnStore ON dbo.AnimalsMemoryOptimized;
GO

-- Create filtered index
CREATE NONCLUSTERED INDEX IX_AnimalsMemoryOptimized_Filtered ON dbo.AnimalsMemoryOptimized([Name])
WHERE [Name] LIKE N'C%';
GO

-- Create table with XML and JSON columns
CREATE TABLE dbo.AnimalsWithXMLJSON
(
    Id INT IDENTITY PRIMARY KEY,
    AnimalData XML,
    AnimalInfo NVARCHAR(MAX)
);
GO

-- Insert sample data
INSERT INTO dbo.AnimalsWithXMLJSON (AnimalData, AnimalInfo)
VALUES
    (N'<Animal><Name>Cat</Name><Type>Mammal</Type></Animal>', N'{"Name": "Cat", "Type": "Mammal"}'),
    (N'<Animal><Name>Dog</Name><Type>Mammal</Type></Animal>', N'{"Name": "Dog", "Type": "Mammal"}');
GO

-- Create XML index
CREATE PRIMARY XML INDEX IX_AnimalsWithXMLJSON_AnimalData ON dbo.AnimalsWithXMLJSON(AnimalData);
GO

-- Create JSON index
CREATE NONCLUSTERED INDEX IX_AnimalsWithXMLJSON_AnimalInfo ON dbo.AnimalsWithXMLJSON(AnimalInfo)
    WITH (PAD_INDEX = ON, FILLFACTOR=90, DROP_EXISTING=ON, ONLINE=ON, SORT_IN_TEMPDB=ON);
GO

-- Check number of pages and records for each index
SELECT OBJECT_NAME(ips.OBJECT_ID)
 ,i.NAME
 ,ips.index_id
 ,index_type_desc
 ,ips.page_count
 ,ips.record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.AnimalsWithXMLJSON'), NULL, NULL, 'DETAILED') ips
JOIN sys.indexes i ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id;
GO