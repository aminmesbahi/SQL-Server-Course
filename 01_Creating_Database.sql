-- ===============================
-- 1: Creating Databases
-- ===============================

-- 1.1 Simplest way to create a database in SQL Server
CREATE DATABASE TestDB;
GO

-- 1.2 Creating a database with one data file and one log file
CREATE DATABASE TestDB
ON PRIMARY
(
    NAME = TestDB_Data,
    FILENAME = N'C:\db\TestDB_Data.mdf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = TestDB_Log,
    FILENAME = N'C:\db\TestDB_Log.ldf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10MB
);
GO

-- 1.3 Creating a database with multiple files and filegroups
CREATE DATABASE TestDB
ON PRIMARY
(
    NAME = TestDB_Data,
    FILENAME = N'C:\db\TestDB_Data.mdf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
),
(
    NAME = TestDB_Data2,
    FILENAME = N'C:\db\TestDB_Data2.ndf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
),
FILEGROUP FG2
(
    NAME = TestDB_Data3,
    FILENAME = N'C:\db\TestDB_Data3.ndf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
),
(
    NAME = TestDB_Data4,
    FILENAME = N'C:\db\TestDB_Data4.ndf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = TestDB_Log,
    FILENAME = N'C:\db\TestDB_Log.ldf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10MB
),
(
    NAME = TestDB_Log2,
    FILENAME = N'C:\db\TestDB_Log2.ldf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
);
GO

-- ===============================
-- 2: Managing Database Properties
-- ===============================

-- 2.1 Altering the recovery model
ALTER DATABASE TestDB SET RECOVERY SIMPLE; -- Options: FULL | BULK_LOGGED
GO

-- 2.2 Changing database collation
ALTER DATABASE TestDB COLLATE Persian_100_CI_AS;
GO

-- 2.3 Adding extended properties
EXEC sp_addextendedproperty 
    @name = N'ver', 
    @value = N'1.0.0';
GO

-- ===============================
-- 3: Managing Filegroups and Files
-- ===============================

-- 3.1 Adding a new filegroup to an existing database
ALTER DATABASE TestDB ADD FILEGROUP FG3;
GO

-- 3.2 Adding a new file to a specific filegroup
ALTER DATABASE TestDB ADD FILE 
(
    NAME = TestDB_Data5,
    FILENAME = N'C:\db\TestDB_Data5.ndf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
) TO FILEGROUP FG3;
GO

-- 3.3 Adding a new log file to an existing database
ALTER DATABASE TestDB ADD LOG FILE 
(
    NAME = TestDB_Log3,
    FILENAME = N'C:\db\TestDB_Log3.ldf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
);
GO

-- 3.4 Changing the default filegroup
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 DEFAULT;
GO

-- 3.5 Setting a filegroup to READ_ONLY
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 READ_ONLY;
GO

-- ===============================
-- 4: File and Filegroup Cleanup
-- ===============================

-- 4.1 Removing a specific file from the database
ALTER DATABASE TestDB REMOVE FILE TestDB_Data5;
GO

-- 4.2 Removing a filegroup after migrating files
-- (SQL Server does not support direct filegroup merging. Files must be moved manually.)
ALTER DATABASE TestDB MODIFY FILE (NAME = TestDB_Data5, NEWNAME = 'TestDB_Data5_Primary');
ALTER DATABASE TestDB MODIFY FILE (NAME = TestDB_Data5_Primary, FILEGROUP = 'PRIMARY');
GO
ALTER DATABASE TestDB REMOVE FILEGROUP FG3;
GO

-- ===============================
-- 5: Monitoring and Queries
-- ===============================

-- 5.1 Get information about database files
SELECT 
    name AS FileName,
    size * 8 / 1024 AS FileSizeMB,
    max_size * 8 / 1024 AS MaxSizeMB,
    growth * 8 / 1024 AS GrowthMB
FROM sys.master_files
WHERE database_id = DB_ID('TestDB');
GO

-- 5.2 Get information about filegroups
SELECT 
    name AS FileGroupName,
    type_desc AS FileGroupType,
    is_default AS IsDefault
FROM sys.filegroups
WHERE database_id = DB_ID('TestDB');
GO

-- 5.3 Get information about file sizes
SELECT 
    name AS FileName,
    size * 8 / 1024 AS FileSizeMB
FROM sys.master_files
WHERE database_id = DB_ID('TestDB');
GO
