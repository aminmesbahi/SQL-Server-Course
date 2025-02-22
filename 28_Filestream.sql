/**************************************************************
 * SQL Server 2022 FILESTREAM Implementation Tutorial
 * Description: This script demonstrates advanced FILESTREAM features 
 *              in SQL Server 2022, including:
 *              - Enabling FILESTREAM at the instance level.
 *              - Creating a modern database with multiple FILESTREAM groups.
 *              - Creating a temporal table with FILESTREAM and ledger capabilities.
 *              - Creating a filetable with compression and security.
 *              - Configuring security roles and granular permissions.
 *              - Encrypting FILESTREAM data with Always Encrypted integration.
 *              - A stored procedure for secure file upload.
 *              - Inserting sample data using modern BULK INSERT via OPENROWSET.
 *              - Querying FILESTREAM data with temporal and security filters.
 *              - Managed backup to Azure Blob Storage.
 *              - Performance monitoring and garbage collection.
 *              - Azure integration using PolyBase for external data sources.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Instance-Level Configuration
-------------------------------------------------
/*
  Enable FILESTREAM at the instance level if not already enabled.
*/
EXEC sp_configure 'filestream_access_level', 2;
RECONFIGURE;
GO

-------------------------------------------------
-- Region: 1. Database and FILESTREAM Filegroups Setup
-------------------------------------------------
/*
  Drop the database if it exists, then create a new database with:
    - A primary filegroup.
    - Two FILESTREAM filegroups.
    - A log file.
    - FILESTREAM options including non-transacted access and a directory name.
*/
DROP DATABASE IF EXISTS FileStreamDB;
GO

CREATE DATABASE FileStreamDB
ON PRIMARY (
    NAME = fsdb_primary,
    FILENAME = 'C:\Data\FileStreamDB.mdf'
),
FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM (
    NAME = fsdb_fg1,
    FILENAME = 'C:\Data\FileStreamDB_FG1'
),
FILEGROUP FileStreamGroup2 CONTAINS FILESTREAM (
    NAME = fsdb_fg2,
    FILENAME = 'C:\Data\FileStreamDB_FG2'
)
LOG ON (
    NAME = fsdb_log,
    FILENAME = 'C:\Data\FileStreamDB.ldf'
)
WITH FILESTREAM (
    NON_TRANSACTED_ACCESS = FULL,
    DIRECTORY_NAME = N'FileStreamDB'
);
GO

USE FileStreamDB;
GO

-------------------------------------------------
-- Region: 2. Creating FILESTREAM and Temporal Table with Ledger
-------------------------------------------------
/*
  Create a schema for file assets.
*/
CREATE SCHEMA FileAssets;
GO

/*
  Create a temporal table with FILESTREAM storage and ledger capabilities.
  - SYSTEM_VERSIONING is enabled to track history.
  - FILESTREAM_ON assigns the table to a specific FILESTREAM filegroup.
  - DATA_COMPRESSION is applied.
  - A clustered index is created on RecordID.
*/
CREATE TABLE FileAssets.Documents
(
    DocumentID UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE DEFAULT NEWSEQUENTIALID(),
    RecordID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    FileName NVARCHAR(255) NOT NULL,
    FileType NVARCHAR(10) NOT NULL,
    FileDescription NVARCHAR(1000) SPARSE NULL,
    FileAttributes XML NULL,
    FileContent VARBINARY(MAX) FILESTREAM NULL,
    FileSize AS DATALENGTH(FileContent) PERSISTED,
    SecurityLevel INT NOT NULL DEFAULT 1,
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
    INDEX idx_FileContent_FS ORGANIZED BY FILEGROUP FileStreamGroup1,
    LEDGER = ON (LEDGER_VIEW = FileAssets.DocumentsLedgerView)
)
WITH (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = FileAssets.DocumentsHistory),
    FILESTREAM_ON = FileStreamGroup1,
    DATA_COMPRESSION = PAGE
);
GO

-------------------------------------------------
-- Region: 3. Creating a Filetable with Enhanced Features
-------------------------------------------------
/*
  Create a filetable for secure file storage with compression enabled.
  FILETABLE_SECURITY = 'ENABLE' applies built-in security.
*/
CREATE TABLE FileAssets.SecureFiles AS FILETABLE
WITH (
    FILETABLE_DIRECTORY = 'SecureDocuments',
    FILETABLE_COLLATE_FILENAME = database_default,
    FILETABLE_PRIMARY_KEY_CONSTRAINT_NAME = PK_SecureFiles,
    FILETABLE_STREAMID_UNIQUE_CONSTRAINT_NAME = UQ_SecureFiles_StreamID,
    FILETABLE_FULLPATH_UNIQUE_CONSTRAINT_NAME = UQ_SecureFiles_Path,
    DATA_COMPRESSION = PAGE,
    FILETABLE_SECURITY = 'ENABLE'
);
GO

-------------------------------------------------
-- Region: 4. Security Configuration and Permissions
-------------------------------------------------
/*
  Create security roles for file access.
*/
CREATE ROLE FileViewer;
CREATE ROLE FileManager;
GO

/*
  Grant granular permissions:
    - FileViewer: SELECT on Documents.
    - FileManager: DML permissions on Documents and ALTER rights on FILESTREAM group.
*/
GRANT SELECT ON FileAssets.Documents TO FileViewer;
GRANT INSERT, UPDATE, DELETE ON FileAssets.Documents TO FileManager;
GRANT ALTER ON FILEGROUP::FileStreamGroup1 TO FileManager;
GO

-------------------------------------------------
-- Region: 5. Encrypting FILESTREAM Data with Always Encrypted
-------------------------------------------------
/*
  Create a COLUMN MASTER KEY integrated with Azure Key Vault.
  Adjust KEY_PATH to match your Azure Key Vault configuration.
*/
CREATE COLUMN MASTER KEY FileCMK
WITH (
    KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
    KEY_PATH = 'https://vault.azure.net/keys/FileCMK/version'
);
GO

/*
  Create a COLUMN ENCRYPTION KEY (placeholder for ENCRYPTED_VALUE).
  Replace 0x... with the actual encrypted value.
*/
CREATE COLUMN ENCRYPTION KEY FileCEK
WITH VALUES (
    COLUMN_MASTER_KEY = FileCMK,
    ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x...
);
GO

-------------------------------------------------
-- Region: 6. Stored Procedure for Secure File Upload
-------------------------------------------------
/*
  Create a stored procedure to securely upload a document.
  Uses EXECUTE AS OWNER for elevated permissions.
*/
CREATE PROCEDURE FileAssets.UploadDocument
    @FileName NVARCHAR(255),
    @FileType NVARCHAR(10),
    @Content VARBINARY(MAX)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO FileAssets.Documents (FileName, FileType, FileContent)
        VALUES (@FileName, @FileType, @Content);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-------------------------------------------------
-- Region: 7. Inserting Sample FILESTREAM Data
-------------------------------------------------
/*
  Insert sample data using modern OPENROWSET BULK INSERT enhancements.
  Adjust the file path as needed.
*/
INSERT INTO FileAssets.Documents (FileName, FileType, FileContent)
SELECT 
    'Manual.pdf',
    'PDF',
    CAST(bulkcolumn AS VARBINARY(MAX))
FROM OPENROWSET(BULK N'C:\SampleFiles\Sample.pdf', SINGLE_BLOB) AS f;
GO

-------------------------------------------------
-- Region: 8. Querying FILESTREAM Data with Temporal and Security Filters
-------------------------------------------------
/*
  Query the Documents table (with system versioning) along with a filetable.
  Use a security filter to only retrieve documents with SecurityLevel <= 1 and of type 'PDF'.
*/
SELECT 
    d.DocumentID,
    d.FileName,
    d.FileType,
    d.FileSize,
    f.file_stream.GetFileNamespacePath() AS FilePath,
    d.SecurityLevel
FROM FileAssets.Documents FOR SYSTEM_TIME ALL AS d
CROSS APPLY FileAssets.SecureFiles AS f
WHERE d.SecurityLevel <= 1
    AND d.FileType = 'PDF'
ORDER BY d.FileSize DESC;
GO

-------------------------------------------------
-- Region: 9. Backup Strategy with FILESTREAM to Azure Blob Storage
-------------------------------------------------
/*
  Backup the FileStreamDB database to Azure Blob Storage.
  Adjust the URL to your Azure storage endpoint.
*/
BACKUP DATABASE FileStreamDB
TO URL = 'https://storageaccount.blob.core.windows.net/container/FileStreamDB.bak'
WITH FILESTREAM, COMPRESSION, CHECKSUM;
GO

-------------------------------------------------
-- Region: 10. Performance Monitoring and Garbage Collection
-------------------------------------------------
/*
  Query performance details for FILESTREAM files.
*/
SELECT 
    fs.database_id,
    fs.name AS file_stream_name,
    fs.physical_name,
    fs.size * 8 / 1024 AS SizeMB,
    fs.space_used * 8 / 1024 AS UsedMB,
    fs.type_desc
FROM sys.database_files AS fs
WHERE fs.type = 2;  -- FILESTREAM files
GO

/*
  Force FILESTREAM garbage collection (2022 improved cleanup).
*/
EXEC sp_filestream_force_garbage_collection @dbname = N'FileStreamDB';
GO

-------------------------------------------------
-- Region: 11. Azure Integration using PolyBase
-------------------------------------------------
/*
  Create an external data source pointing to Azure Blob Storage.
  Replace 'storageaccount' and 'container' with your values.
*/
CREATE EXTERNAL DATA SOURCE AzureStorage
WITH (
    LOCATION = 'wasbs://container@storageaccount.blob.core.windows.net',
    CREDENTIAL = AzureStorageCredential
);
GO

/*
  Create an external file format (example: ZipFileFormat).
*/
CREATE EXTERNAL FILE FORMAT ZipFileFormat
WITH (FORMAT_TYPE = DELIMITEDTEXT);
GO

/*
  Create an external table to access archived files from Azure Storage.
*/
CREATE EXTERNAL TABLE FileAssets.ArchiveFiles
(
    FileName NVARCHAR(255),
    FileContent VARBINARY(MAX)
)
WITH (
    LOCATION = '/archive/',
    DATA_SOURCE = AzureStorage,
    FILE_FORMAT = ZipFileFormat
);
GO

-------------------------------------------------
-- Region: 12. Cleanup
-------------------------------------------------
/*
  Clean up security objects and drop the database.
  Uncomment the following lines if you wish to clean up:
*/
-- DROP TABLE IF EXISTS FileAssets.Documents;
-- DROP DATABASE IF EXISTS FileStreamDB;
-- DROP ROLE IF EXISTS FileViewer;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
