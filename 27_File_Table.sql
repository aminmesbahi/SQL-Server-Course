/****************************************************************************************************
 * FileTable Demo Script
 * 
 * This script demonstrates a complete FileTable setup and usage scenario:
 *  1. Creating a FILESTREAM‑enabled database.
 *  2. Creating a FileTable.
 *  3. Performing basic operations (inserting directories, querying files).
 *  4. Advanced operations such as triggers and hierarchical queries.
 *
 * Note:
 *  - Replace file paths with valid paths on your system.
 *  - FILESTREAM must be enabled on the SQL Server instance before running this script.
 ****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
  Step 0. Pre-requisites and Instance Settings
  -----------------------------------------------------------------------------------------------
  Ensure FILESTREAM is enabled on your SQL Server instance.
  
  Run (if not already done):
  
    EXEC sp_configure filestream_access_level, 2;
    RECONFIGURE;
  
  Also, verify in SQL Server Configuration Manager that FILESTREAM is enabled.
*/


/*-----------------------------------------------------------------------------------------------
  Step 1. Create a FILESTREAM‑Enabled Database
  -----------------------------------------------------------------------------------------------
  This database will store its FILESTREAM data in a designated folder.
-----------------------------------------------------------------------------------------------*/
-- Drop the database if it exists (for testing purposes)
IF DB_ID('FileTableDemo') IS NOT NULL
BEGIN
    ALTER DATABASE FileTableDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FileTableDemo;
END
GO

CREATE DATABASE FileTableDemo
ON PRIMARY 
( 
    NAME = FileTableDemo_data,
    FILENAME = 'C:\SQLData\FileTableDemo_data.mdf'  -- Adjust to your system
),
FILEGROUP FileStreamGroup CONTAINS FILESTREAM 
( 
    NAME = FileTableDemo_FS,
    FILENAME = 'C:\SQLData\FileTableDemo_FS'  -- Adjust to your system
)
LOG ON 
( 
    NAME = FileTableDemo_log,
    FILENAME = 'C:\SQLData\FileTableDemo_log.ldf'  -- Adjust to your system
);
GO

-- Switch to the new database
USE FileTableDemo;
GO


/*-----------------------------------------------------------------------------------------------
  Step 2. Create a Basic FileTable
  -----------------------------------------------------------------------------------------------
  Create a FileTable named Documents. SQL Server will create a corresponding 
  file system directory under the special share (e.g. \\<server>\MSSQLSERVER\FileTableDemo\Documents)
-----------------------------------------------------------------------------------------------*/
IF OBJECT_ID('Documents', 'U') IS NOT NULL
    DROP TABLE Documents;
GO

CREATE TABLE Documents AS FILETABLE
WITH
(
    FILETABLE_DIRECTORY = 'Documents',          -- Logical folder name
    FILETABLE_COLLATE_FILENAME = database_default -- Collation for file names
);
GO

/*-----------------------------------------------------------------------------------------------
  Step 3. Basic Operations on the FileTable
  -----------------------------------------------------------------------------------------------
  3.1 Query the FileTable metadata.
  3.2 Insert a new directory record via T‑SQL.
  3.3 (Note: To insert a file, use Windows Explorer to copy a file into the FileTable share.)
-----------------------------------------------------------------------------------------------*/

-- 3.1 Query the FileTable to list existing files and directories
SELECT 
    file_stream_id, 
    name, 
    file_type, 
    is_directory,
    GET_PATHNAME(path_locator) AS UNCPath,
    creation_time,
    last_write_time
FROM Documents;
GO

-- 3.2 Insert a new directory into the FileTable (this creates a folder record)
INSERT INTO Documents (name, is_directory)
VALUES (N'NewFolder', 1);
GO

-- Confirm the insertion
SELECT file_stream_id, name, is_directory, GET_PATHNAME(path_locator) AS UNCPath
FROM Documents
WHERE name = 'NewFolder';
GO

/*
  3.3 To insert a file, open Windows Explorer and navigate to:
      \\<YourServerName>\MSSQLSERVER\FileTableDemo\Documents
  and copy a file (e.g., example.txt) into that directory.
*/


/*-----------------------------------------------------------------------------------------------
  Step 4. Advanced Operations and Queries
  -----------------------------------------------------------------------------------------------
  4.1: Create a trigger on the FileTable to log file insertions.
  4.2: Advanced query – retrieve files by extension.
-----------------------------------------------------------------------------------------------*/

/* 4.1 Create an audit table and a trigger that logs every new file (not directories)
   Note: Triggers on FileTables work similarly to regular tables.
*/
IF OBJECT_ID('DocumentAudit', 'U') IS NOT NULL
    DROP TABLE DocumentAudit;
GO

CREATE TABLE DocumentAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260),
    InsertedTime DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- Create a trigger on Documents FileTable for AFTER INSERT
IF OBJECT_ID('trg_Documents_Insert', 'TR') IS NOT NULL
    DROP TRIGGER trg_Documents_Insert;
GO

CREATE TRIGGER trg_Documents_Insert
ON Documents
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log only file insertions (not directories)
    INSERT INTO DocumentAudit (FileName)
    SELECT name
    FROM inserted
    WHERE is_directory = 0;
END;
GO

/* 4.2 Advanced Query: Find all PDF files in the FileTable.
   This query uses string functions to filter files with a .pdf extension.
*/
SELECT 
    name,
    GET_PATHNAME(path_locator) AS UNCPath,
    file_type
FROM Documents
WHERE is_directory = 0
  AND LOWER(RIGHT(name, 4)) = '.pdf';  -- Change '.pdf' as needed
GO


/*-----------------------------------------------------------------------------------------------
  Step 5. Hierarchical Query on FileTable
  -----------------------------------------------------------------------------------------------
  Use the hierarchyid methods to query the FileTable structure.
  For example, list all files and folders under a specific directory.
-----------------------------------------------------------------------------------------------*/
DECLARE @ParentPath hierarchyid;

-- Assume you want to list contents under 'NewFolder'
SELECT TOP 1 @ParentPath = path_locator
FROM Documents
WHERE name = 'NewFolder'
  AND is_directory = 1;

-- List all items (files/folders) under 'NewFolder'
SELECT 
    name,
    is_directory,
    GET_PATHNAME(path_locator) AS UNCPath
FROM Documents
WHERE path_locator.IsDescendantOf(@ParentPath) = 1;
GO

/*-----------------------------------------------------------------------------------------------
  Step 6. Cleanup and Best Practices
  -----------------------------------------------------------------------------------------------
  Remember:
    - To insert actual file data, use the Windows file system.
    - FileTable rows and FILESTREAM data are included in database backups.
    - Secure the underlying FILESTREAM folder with proper Windows permissions.
-----------------------------------------------------------------------------------------------

*/
