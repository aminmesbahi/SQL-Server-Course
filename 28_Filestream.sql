-------------------------------------
-- FILESTREAM Implementation for SQL Server 2022
-- Includes: Security, Compression, Temporal, and Azure Integration
-------------------------------------

-- Enable FILESTREAM at instance level (if not already enabled)
EXEC sp_configure 'filestream_access_level', 2;
RECONFIGURE;
GO

-- Create modern database with multiple FILESTREAM groups
DROP DATABASE IF EXISTS FileStreamDB;
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

-- Create security schema for FILESTREAM access
CREATE SCHEMA FileAssets;
GO

-- Create temporal table with FILESTREAM and ledger features
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

-- Create compression-enabled filetable (2022 enhancement)
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

-- Create security roles
CREATE ROLE FileViewer;
CREATE ROLE FileManager;
GO

-- Configure granular permissions
GRANT SELECT ON FileAssets.Documents TO FileViewer;
GRANT INSERT, UPDATE, DELETE ON FileAssets.Documents TO FileManager;
GRANT ALTER ON FILEGROUP::FileStreamGroup1 TO FileManager;
GO

-- Encrypt FILESTREAM data using Always Encrypted (2022 integration)
CREATE COLUMN MASTER KEY FileCMK
WITH (KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
      KEY_PATH = 'https://vault.azure.net/keys/FileCMK/version');

CREATE COLUMN ENCRYPTION KEY FileCEK
WITH VALUES (
    COLUMN_MASTER_KEY = FileCMK,
    ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x...
);
GO

-- Stored procedure for secure file upload
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

        -- 2022 ERROR_MESSAGE() enhancement
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Insert sample data using modern OPENROWSET (2022 BULK INSERT enhancement)
INSERT INTO FileAssets.Documents (FileName, FileType, FileContent)
SELECT 
    'Manual.pdf',
    'PDF',
    CAST(bulkcolumn AS VARBINARY(MAX))
FROM OPENROWSET(BULK N'C:\SampleFiles\Sample.pdf', SINGLE_BLOB) AS f;
GO

-- Query FILESTREAM data with temporal and security
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

-- Backup strategy with FILESTREAM (2022 managed backup)
BACKUP DATABASE FileStreamDB
TO URL = 'https://storageaccount.blob.core.windows.net/container/FileStreamDB.bak'
WITH FILESTREAM, COMPRESSION, CHECKSUM;
GO

-- Performance monitoring using DMVs
SELECT 
    fs.database_id,
    fs.name AS file_stream_name,
    fs.physical_name,
    fs.size * 8/1024 AS SizeMB,
    fs.space_used * 8/1024 AS UsedMB,
    fs.type_desc
FROM sys.database_files AS fs
WHERE fs.type = 2;  -- FILESTREAM files

-- Garbage collection management (2022 improved cleanup)
EXEC sp_filestream_force_garbage_collection @dbname = N'FileStreamDB';
GO

-- Azure integration using PolyBase (2022 enhancement)
CREATE EXTERNAL DATA SOURCE AzureStorage
WITH (
    LOCATION = 'wasbs://container@storageaccount.blob.core.windows.net',
    CREDENTIAL = AzureStorageCredential
);

CREATE EXTERNAL FILE FORMAT ZipFileFormat
WITH (FORMAT_TYPE = DELIMITEDTEXT);

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

-- Cleanup with modern syntax
DROP TABLE IF EXISTS FileAssets.Documents;
DROP DATABASE IF EXISTS FileStreamDB;
DROP ROLE IF EXISTS FileViewer;
GO