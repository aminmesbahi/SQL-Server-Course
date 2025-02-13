/**************************************************************
 * SQL Server 2022 Database Tutorial
 * Description: This script demonstrates common operations for 
 *              creating and managing a database, filegroups, 
 *              files, and monitoring their properties.
 **************************************************************/

-------------------------------------------------
-- Region: Initialization & Cleanup
-------------------------------------------------
/*
  Optional: Drop the database if it exists.
  Uncomment the below section if you wish to start from a clean slate.
*/
-- IF EXISTS (SELECT name FROM sys.databases WHERE name = N'TestDB')
-- BEGIN
--     PRINT 'Dropping existing database: TestDB';
--     ALTER DATABASE TestDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--     DROP DATABASE TestDB;
-- END
-- GO

-------------------------------------------------
-- Region: 1. Creating Databases
-------------------------------------------------
/*
  1.1 Simplest way to create a database in SQL Server
*/
CREATE DATABASE TestDB;
GO

/*
  1.2 Creating a database with one data file and one log file
*/
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

/*
  1.3 Creating a database with multiple files and filegroups
*/
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

-------------------------------------------------
-- Region: 2. Managing Database Properties
-------------------------------------------------
/*
  2.1 Altering the recovery model
  Options: SIMPLE, FULL, BULK_LOGGED
*/
ALTER DATABASE TestDB SET RECOVERY SIMPLE;
GO

/*
  2.2 Changing database collation
*/
ALTER DATABASE TestDB COLLATE Persian_100_CI_AS;
GO

/*
  2.3 Adding extended properties to the database
*/
EXEC sp_addextendedproperty 
    @name = N'ver', 
    @value = N'1.0.0';
GO

-------------------------------------------------
-- Region: 3. Managing Filegroups and Files
-------------------------------------------------
/*
  3.1 Adding a new filegroup to an existing database
*/
ALTER DATABASE TestDB ADD FILEGROUP FG3;
GO

/*
  3.2 Adding a new file to a specific filegroup
*/
ALTER DATABASE TestDB ADD FILE 
(
    NAME = TestDB_Data5,
    FILENAME = N'C:\db\TestDB_Data5.ndf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10%
) TO FILEGROUP FG3;
GO

/*
  3.3 Adding a new log file to the database
*/
ALTER DATABASE TestDB ADD LOG FILE 
(
    NAME = TestDB_Log3,
    FILENAME = N'C:\db\TestDB_Log3.ldf',
    SIZE = 10MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 10MB
);
GO

/*
  3.4 Changing the default filegroup to FG3
*/
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 DEFAULT;
GO

/*
  3.5 Setting filegroup FG3 to READ_ONLY mode
*/
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 READ_ONLY;
GO

-------------------------------------------------
-- Region: 4. File and Filegroup Cleanup
-------------------------------------------------
/*
  4.1 Removing a specific file from the database
  (Ensure no objects depend on the file before removal.)
*/
ALTER DATABASE TestDB REMOVE FILE TestDB_Data5;
GO

/*
  4.2 Migrating files from a filegroup before removal:
  SQL Server does not support direct merging of filegroups.
  Instead, move files manually to a different filegroup.
*/
ALTER DATABASE TestDB MODIFY FILE (NAME = TestDB_Data5, NEWNAME = 'TestDB_Data5_Primary');
ALTER DATABASE TestDB MODIFY FILE (NAME = TestDB_Data5_Primary, FILEGROUP = 'PRIMARY');
GO

/*
  4.3 Removing the filegroup (after ensuring it is empty)
*/
ALTER DATABASE TestDB REMOVE FILEGROUP FG3;
GO

-------------------------------------------------
-- Region: 5. Monitoring and Queries
-------------------------------------------------
/*
  5.1 Retrieve information about database files
*/
SELECT 
    name AS FileName,
    size * 8 / 1024 AS FileSizeMB,
    CASE 
        WHEN max_size = -1 THEN 'Unlimited'
        ELSE CAST(max_size * 8 / 1024 AS VARCHAR(20))
    END AS MaxSizeMB,
    growth AS GrowthSetting -- Note: growth is in MB if FILEGROWTH specified in MB
FROM sys.master_files
WHERE database_id = DB_ID('TestDB');
GO

/*
  5.2 Retrieve information about filegroups in the database
*/
SELECT 
    fg.name AS FileGroupName,
    fg.type_desc AS FileGroupType,
    fg.is_default AS IsDefault
FROM sys.filegroups AS fg
INNER JOIN sys.databases AS d ON d.database_id = DB_ID('TestDB')
WHERE d.name = 'TestDB';
GO

/*
  5.3 Retrieve file sizes from sys.master_files (alternative query)
*/
SELECT 
    name AS FileName,
    size * 8 / 1024 AS FileSizeMB
FROM sys.master_files
WHERE database_id = DB_ID('TestDB');
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------

