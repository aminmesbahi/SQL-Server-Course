-- Create a master key
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
GO

-- Create a certificate
CREATE CERTIFICATE TDECert
WITH SUBJECT = 'TDE Certificate';
GO

-- Switch to the database you want to encrypt
USE TestDB;
GO

-- Create a database encryption key
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;
GO


-- Enable encryption on the database
ALTER DATABASE TestDB
SET ENCRYPTION ON;
GO



-- Verify TDE status
SELECT 
    db.name,
    dek.encryption_state,
    dek.encryptor_type,
    dek.key_algorithm,
    dek.key_length
FROM 
    sys.dm_database_encryption_keys dek
JOIN 
    sys.databases db
ON 
    dek.database_id = db.database_id;
GO

-- Disable encryption on the database
ALTER DATABASE TestDB
SET ENCRYPTION OFF;
GO



-- Drop the database encryption key
USE TestDB;
GO
DROP DATABASE ENCRYPTION KEY;
GO

-- Drop the certificate
USE master;
GO
DROP CERTIFICATE TDECert;
GO


-- Backup the certificate
BACKUP CERTIFICATE TDECert
TO FILE = 'C:\Backup\TDECert.cer'
WITH PRIVATE KEY 
(
    FILE = 'C:\Backup\TDECert.pvk',
    ENCRYPTION BY PASSWORD = 'StrongPassword123!'
);
GO


-- Backup the encrypted database
BACKUP DATABASE TestDB
TO DISK = 'C:\Backup\TestDB.bak';
GO


-- Restore the certificate
CREATE CERTIFICATE TDECert
FROM FILE = 'C:\Backup\TDECert.cer'
WITH PRIVATE KEY 
(
    FILE = 'C:\Backup\TDECert.pvk',
    DECRYPTION BY PASSWORD = 'StrongPassword123!'
);
GO

-- Restore the encrypted database
RESTORE DATABASE TestDB
FROM DISK = 'C:\Backup\TestDB.bak';
GO