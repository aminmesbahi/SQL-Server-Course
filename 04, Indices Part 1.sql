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
-- check the Execution Plan after exeting this query
SELECT [Name] FROM dbo.Animals
	WHERE [Name]=N'Cat'
GO

-- Now you can create an index
CREATE NONCLUSTERED INDEX IX_Animals_Name ON dbo.Animals([Name]);
GO

-- And check the Exection Plan again, after creting index in previous step
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

-- Crete new index using id column and options
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


-- Get index fragmentaion and free space
SELECT OBJECT_NAME(ips.OBJECT_ID)
 ,i.NAME
 ,ips.index_id
 ,index_type_desc
 ,avg_fragmentation_in_percent
 ,avg_page_space_used_in_percent
 ,page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Animals'), NULL, NULL, NULL) ips
INNER JOIN sys.indexes i ON (ips.object_id = i.object_id)
 AND (ips.index_id = i.index_id)
ORDER BY avg_fragmentation_in_percent DESC