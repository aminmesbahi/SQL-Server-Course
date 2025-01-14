-------------------------------------
-- 2: Backup database
-------------------------------------

-- Minimal database backup
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB.bak'
GO

-- Backup database with more options
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB.bak' WITH COMPRESSION, STATS = 5, NAME = N'Last backup before 2.0'
, EXPIREDATE = '01-01-2020', RETAINDAYS = 10
, DESCRIPTION=N'This backup made by me on 01-01-2019 9:00AM before version 2.0.0';
GO

-- Viewing content of a backup file
RESTORE HEADERONLY FROM DISK = 'c:\db\backup\TestDB.bak'
GO

-- Create new backup device
EXEC sp_addumpdevice  @devtype = N'disk', @logicalname = N'MyBackups', @physicalname = N'C:\DB\Backup\MyBackups.bak'
GO

-- Backup database to backup device
BACKUP DATABASE TestDB TO DISK='MyBackups'
GO

-- Viewing content of a backup device
RESTORE HEADERONLY FROM DISK ='MyBackups'
GO

-- Backup one database on multiple files (WITH FORMAT is necessary when one or more files created with one-file backup)
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB.bak', DISK= N'c:\db\backup\TestDB2.bak', DISK = N'c:\db\backup\TestDB3.bak' WITH FORMAT;
GO

-- Mirror Backup (Backup database to multiple equivalent files [max 4 mirror files with same media types (Disk or Tape)])
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB.bak' MIRROR TO DISK=N'c:\db\backup\TestDB2.bak' WITH FORMAT;
GO

-- Backup database with compression and verify
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB_Compressed.bak' WITH COMPRESSION, VERIFYONLY;
GO

-- Backup database with continue on error
BACKUP DATABASE TestDB TO DISK=N'c:\db\backup\TestDB_ContinueOnError.bak' WITH CONTINUE_AFTER_ERROR;
GO