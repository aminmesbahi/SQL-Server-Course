-- ===============================
-- 2: Backup Database
-- ===============================

-- 2.1 Minimal Database Backup
BACKUP DATABASE TestDB TO DISK = N'C:\db\backup\TestDB.bak';
GO

-- 2.2 Full Backup with Additional Options
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB.bak' 
WITH 
    COMPRESSION,                -- Compress the backup to save disk space
    STATS = 5,                  -- Display progress every 5% completed
    NAME = N'Full Backup Before Version 2.0', -- Logical name of the backup
    EXPIREDATE = '2025-12-31',  -- Prevent overwriting before this date
    RETAINDAYS = 10,            -- Prevent overwriting for 10 days
    DESCRIPTION = N'Backup taken on 2025-01-27 before deploying version 2.0.';
GO

-- 2.3 Differential Backup
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB_Differential.bak' 
WITH DIFFERENTIAL, COMPRESSION, STATS = 5;
GO

-- 2.4 Transaction Log Backup
BACKUP LOG TestDB 
TO DISK = N'C:\db\backup\TestDB_Log.bak' 
WITH NO_TRUNCATE, STATS = 5;
GO

-- 2.5 File and Filegroup Backup
BACKUP DATABASE TestDB 
FILE = 'TestDB_Data' 
TO DISK = N'C:\db\backup\TestDB_File.bak' 
WITH COMPRESSION, STATS = 5;
GO

BACKUP DATABASE TestDB 
FILEGROUP = 'PRIMARY' 
TO DISK = N'C:\db\backup\TestDB_FileGroup.bak' 
WITH COMPRESSION, STATS = 5;
GO

-- 2.6 Backup to a Backup Device
EXEC sp_addumpdevice 
    @devtype = N'disk', 
    @logicalname = N'MyBackups', 
    @physicalname = N'C:\db\backup\MyBackups.bak';
GO

BACKUP DATABASE TestDB TO MyBackups 
WITH COMPRESSION, STATS = 5;
GO

-- 2.7 Backup to Multiple Files
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB1.bak', 
   DISK = N'C:\db\backup\TestDB2.bak', 
   DISK = N'C:\db\backup\TestDB3.bak' 
WITH FORMAT, COMPRESSION, STATS = 5;
GO

-- 2.8 Mirror Backup
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB.bak' 
MIRROR TO DISK = N'C:\db\backup\TestDB_Mirror.bak' 
WITH FORMAT, COMPRESSION, STATS = 5;
GO

-- 2.9 Encrypted Backup
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB_Encrypted.bak' 
WITH 
    ENCRYPTION 
    (
        ALGORITHM = AES_256, 
        SERVER CERTIFICATE = BackupCertificate
    ),
    COMPRESSION, STATS = 5;
GO

-- 2.10 Verify Backup Integrity
RESTORE VERIFYONLY 
FROM DISK = N'C:\db\backup\TestDB.bak';
GO

-- 2.11 Viewing Backup File Content
RESTORE HEADERONLY 
FROM DISK = N'C:\db\backup\TestDB.bak';
GO

RESTORE FILELISTONLY 
FROM DISK = N'C:\db\backup\TestDB.bak';
GO

-- 2.12 Backup with Continue on Error
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB_ContinueOnError.bak' 
WITH CONTINUE_AFTER_ERROR, STATS = 5;
GO

-- ===============================
-- 3: Additional Backup Options
-- ===============================

-- 3.1 Copy-Only Backup (Does not affect the sequence of backups)
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB_CopyOnly.bak' 
WITH COPY_ONLY, COMPRESSION, STATS = 5;
GO

-- 3.2 Backup Compression Settings at the Server Level
EXEC sp_configure 'backup compression default', 1; -- 1 = Enable, 0 = Disable
RECONFIGURE;
GO

-- 3.3 Backup with Checksum
BACKUP DATABASE TestDB 
TO DISK = N'C:\db\backup\TestDB_Checksum.bak' 
WITH CHECKSUM, STATS = 5;
GO

-- 3.4 Partial Backup (Back up specific filegroups)
BACKUP DATABASE TestDB 
READ_WRITE_FILEGROUPS 
TO DISK = N'C:\db\backup\TestDB_Partial.bak' 
WITH COMPRESSION, STATS = 5;
GO
