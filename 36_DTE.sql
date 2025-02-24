/**************************************************************
 * SQL Server 2022 TDE (Transparent Data Encryption) Tutorial
 * Description: This script demonstrates how to implement TDE 
 *              in SQL Server 2022. It covers:
 *              - Creating a master key and certificate in the master database.
 *              - Creating a database encryption key in the target database.
 *              - Enabling and verifying TDE on a database.
 *              - Disabling TDE and dropping the encryption key.
 *              - Backing up and restoring the certificate and encrypted database.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization (Master Database)
-------------------------------------------------
USE master;
GO

/*
  Create a master key in the master database.
  This key is used to encrypt certificates and other sensitive data.
*/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
GO

/*
  Create a certificate that will be used to encrypt the database encryption key.
*/
CREATE CERTIFICATE TDECert
WITH SUBJECT = 'TDE Certificate';
GO

-------------------------------------------------
-- Region: 1. Configure TDE on the Target Database (TestDB)
-------------------------------------------------
USE TestDB;
GO

/*
  Create a database encryption key using AES_256 encryption.
  The key is encrypted by the previously created certificate.
*/
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;
GO

/*
  Enable TDE on the TestDB database.
*/
ALTER DATABASE TestDB
SET ENCRYPTION ON;
GO

-------------------------------------------------
-- Region: 2. Verify TDE Status
-------------------------------------------------
/*
  Query the current encryption status of databases.
  Displays encryption state, encryptor type, algorithm, and key length.
*/
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

-------------------------------------------------
-- Region: 3. Disabling and Dropping TDE Objects
-------------------------------------------------
/*
  Optionally, disable encryption on the database.
*/
ALTER DATABASE TestDB
SET ENCRYPTION OFF;
GO

/*
  Drop the database encryption key from TestDB.
*/
USE TestDB;
GO
DROP DATABASE ENCRYPTION KEY;
GO

/*
  Switch back to master and drop the certificate.
*/
USE master;
GO
DROP CERTIFICATE TDECert;
GO

-------------------------------------------------
-- Region: 4. Backing Up the Certificate
-------------------------------------------------
/*
  Backup the certificate along with its private key.
  Adjust the file paths as needed.
*/
BACKUP CERTIFICATE TDECert
TO FILE = 'C:\Backup\TDECert.cer'
WITH PRIVATE KEY 
(
    FILE = 'C:\Backup\TDECert.pvk',
    ENCRYPTION BY PASSWORD = 'StrongPassword123!'
);
GO

-------------------------------------------------
-- Region: 5. Backing Up the Encrypted Database
-------------------------------------------------
/*
  Backup the encrypted database to a disk file.
  Adjust the backup file path as needed.
*/
BACKUP DATABASE TestDB
TO DISK = 'C:\Backup\TestDB.bak';
GO

-------------------------------------------------
-- Region: 6. Restoring the Certificate and Encrypted Database
-------------------------------------------------
/*
  Restore the certificate from backup.
  Adjust the file paths and decryption password as needed.
*/
CREATE CERTIFICATE TDECert
FROM FILE = 'C:\Backup\TDECert.cer'
WITH PRIVATE KEY 
(
    FILE = 'C:\Backup\TDECert.pvk',
    DECRYPTION BY PASSWORD = 'StrongPassword123!'
);
GO

/*
  Restore the encrypted database from backup.
*/
RESTORE DATABASE TestDB
FROM DISK = 'C:\Backup\TestDB.bak';
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------