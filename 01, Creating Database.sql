-------------------------------------
-- 1: Creating Database
-------------------------------------

-- Simplest way to create a database in SQL Server
CREATE DATABASE TestDB;
GO

-- Creating a database with 1 datafile and 1 logfile
CREATE DATABASE TestDB
ON PRIMARY
       (
           NAME = TestDB_Data,
           FILENAME = N'c:\db\TestDB_Data.mdf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       )
LOG ON
    (
        NAME = TestDB_Log,
        FILENAME = N'c:\db\TestDB_Log.ldf',
        SIZE = 10MB,
        MAXSIZE = 10GB,
        FILEGROWTH = 10MB
    );
GO

-- Creating a database with multiple files and filegroups
CREATE DATABASE TestDB
ON PRIMARY
       (
           NAME = TestDB_Data,
           FILENAME = N'c:\db\TestDB_Data.mdf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       ),
       (
           NAME = TestDB_Data2,
           FILENAME = N'c:\db\TestDB_Data2.ndf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       ),
   FILEGROUP FG2
       (
           NAME = TestDB_Data3,
           FILENAME = N'c:\db\TestDB_Data3.ndf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       ),
       (
           NAME = TestDB_Data4,
           FILENAME = N'c:\db\TestDB_Data4.ndf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       )
LOG ON
    (
        NAME = TestDB_Log,
        FILENAME = N'c:\db\TestDB_Log.ldf',
        SIZE = 10MB,
        MAXSIZE = 10GB,
        FILEGROWTH = 10MB
    ),
    (
        NAME = TestDB_Log2,
        FILENAME = N'c:\db\TestDB_Log2.ldf',
        SIZE = 10MB,
        MAXSIZE = 10GB,
        FILEGROWTH = 10%
    );
GO


-- Altering database recovery model
ALTER DATABASE TestDB SET RECOVERY SIMPLE; -- {Full | BULK_LOGGED}
GO


-- Add new filegroup to existing database
ALTER DATABASE TestDB ADD FILEGROUP FG3;
GO

-- Add new file to database
ALTER DATABASE TestDB ADD FILE (
           NAME = TestDB_Data5,
           FILENAME = N'c:\db\TestDB_Data5.ndf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       ) TO FILEGROUP FG3;
GO

-- Add new log file to existing database
ALTER DATABASE TestDB ADD LOG FILE (
           NAME = TestDB_Log3,
           FILENAME = N'c:\db\TestDB_Log3.ldf',
           SIZE = 10MB,
           MAXSIZE = 10GB,
           FILEGROWTH = 10%
       );
GO

-- Change default filegroup
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 DEFAULT;
GO

-- Modify a filegroup to readonly
ALTER DATABASE TestDB MODIFY FILEGROUP FG3 READ_ONLY;
GO

-- Change database collation
ALTER DATABASE TestDB COLLATE Persian_100_CI_AS;
GO

-- Add extended property
EXEC sp_addextendedproperty @name=N'ver', @value=N'1.0.0';
GO

       