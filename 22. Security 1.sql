-------------------------------------
-- Security, Login, User, Keys, Permissions
-------------------------------------

USE master;
GO

-- Create a new SQL Server login
CREATE LOGIN TestLogin WITH PASSWORD = 'StrongPassword123!';
GO

-- Create a new database user for the login
USE TestDB;
GO
CREATE USER TestUser FOR LOGIN TestLogin;
GO

-- Grant DML permissions to the user
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Animals TO TestUser;
GO

-- Grant DDL permissions to the user
GRANT CREATE TABLE, ALTER, DROP ON SCHEMA::dbo TO TestUser;
GO

-- Create a symmetric key
CREATE SYMMETRIC KEY TestSymmetricKey
WITH ALGORITHM = AES_256
ENCRYPTION BY PASSWORD = 'StrongPassword123!';
GO

-- Open the symmetric key
OPEN SYMMETRIC KEY TestSymmetricKey
DECRYPTION BY PASSWORD = 'StrongPassword123!';
GO

-- Encrypt data using the symmetric key
DECLARE @EncryptedData VARBINARY(MAX);
SET @EncryptedData = ENCRYPTBYKEY(KEY_GUID('TestSymmetricKey'), 'Sensitive Data');
SELECT @EncryptedData AS EncryptedData;
GO

-- Decrypt data using the symmetric key
DECLARE @DecryptedData NVARCHAR(MAX);
SET @DecryptedData = DECRYPTBYKEY(@EncryptedData);
SELECT @DecryptedData AS DecryptedData;
GO

-- Close the symmetric key
CLOSE SYMMETRIC KEY TestSymmetricKey;
GO

-- Create an asymmetric key
CREATE ASYMMETRIC KEY TestAsymmetricKey
WITH ALGORITHM = RSA_2048;
GO

-- Encrypt data using the asymmetric key
DECLARE @AsymEncryptedData VARBINARY(MAX);
SET @AsymEncryptedData = ENCRYPTBYASYMKEY(ASYMKEY_ID('TestAsymmetricKey'), 'Sensitive Data');
SELECT @AsymEncryptedData AS AsymEncryptedData;
GO

-- Decrypt data using the asymmetric key
DECLARE @AsymDecryptedData NVARCHAR(MAX);
SET @AsymDecryptedData = DECRYPTBYASYMKEY(ASYMKEY_ID('TestAsymmetricKey'), @AsymEncryptedData, N'');
SELECT @AsymDecryptedData AS AsymDecryptedData;
GO

-- Create a role and add the user to the role
CREATE ROLE TestRole;
GO
ALTER ROLE TestRole ADD MEMBER TestUser;
GO

-- Grant permissions to the role
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Animals TO TestRole;
GRANT CREATE TABLE, ALTER, DROP ON SCHEMA::dbo TO TestRole;
GO

-- Revoke permissions from the user
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.Animals FROM TestUser;
REVOKE CREATE TABLE, ALTER, DROP ON SCHEMA::dbo FROM TestUser;
GO

-- Drop the role
DROP ROLE TestRole;
GO

-- Drop the user
DROP USER TestUser;
GO

-- Drop the login
USE master;
GO
DROP LOGIN TestLogin;
GO

-- Drop the symmetric key
USE TestDB;
GO
DROP SYMMETRIC KEY TestSymmetricKey;
GO

-- Drop the asymmetric key
DROP ASYMMETRIC KEY TestAsymmetricKey;
GO