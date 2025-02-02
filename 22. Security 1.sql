-------------------------------------
-- Enhanced Security Script for SQL Server 2022
-- Includes: Modern authentication, RBAC, TDE, Ledger, Certificates, and Azure integration
-------------------------------------

USE master;
GO

-- Modern login creation with password options (2022 enhancements)
CREATE LOGIN TestLogin 
WITH PASSWORD = 'StrongPassword123!' 
  MUST_CHANGE, 
  CHECK_EXPIRATION = ON, 
  CHECK_POLICY = ON;
GO

-- Create Azure AD login (if using hybrid environment)
-- CREATE LOGIN [user@domain.com] FROM EXTERNAL PROVIDER;
-- GO

-- Create database scoped credential for Azure integration
CREATE DATABASE SCOPED CREDENTIAL AzureCredential
WITH IDENTITY = 'Managed Identity';
GO

-- Create server audit (2022 enhancements)
CREATE SERVER AUDIT SecurityAudit
TO FILE (FILEPATH = 'C:\Audits\')
WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
GO

ALTER SERVER AUDIT SecurityAudit WITH (STATE = ON);
GO

USE TestDB;
GO

-- Create user with modern syntax
CREATE USER TestUser 
  FOR LOGIN TestLogin
  WITH DEFAULT_SCHEMA = dbo;
GO

-- Ledger table configuration (2022 new feature)
ALTER DATABASE TestDB SET LEDGER = ON;
GO

CREATE TABLE dbo.LedgerTable
(
    ID INT PRIMARY KEY,
    Data NVARCHAR(100)
)
WITH 
(
  LEDGER = ON 
  (
    APPEND_ONLY = ON,
    LEDGER_VIEW = [dbo].[LedgerTableView]
  )
);
GO

-- Certificate management with enclave (2022 enhancements)
CREATE CERTIFICATE TestCertificate
  WITH SUBJECT = 'Test Certificate',
  EXPIRY_DATE = '20251231',
  ENCLAVE_COMPUTATIONS;
GO

BACKUP CERTIFICATE TestCertificate
  TO FILE = 'C:\Certificates\TestCertificate.cer'
  WITH PRIVATE KEY 
  (
    FILE = 'C:\Certificates\TestCertificate.pvk',
    ENCRYPTION_PASSWORD = 'StrongPassword123!'
  );
GO

-- Always Encrypted configuration (2022 improvements)
CREATE COLUMN ENCRYPTION KEY TestCEK
WITH VALUES
(
  COLUMN_MASTER_KEY = TestCertificate,
  ALGORITHM = 'RSA_OAEP',
  ENCRYPTED_VALUE = 0x...
);
GO

-- Dynamic Data Masking (2022 updates)
ALTER TABLE dbo.Animals
ALTER COLUMN SSN ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)');
GO

-- Row-Level Security (2022 enhancements)
CREATE SECURITY POLICY AnimalFilter
ADD FILTER PREDICATE dbo.fn_securitypredicate(UserID)
ON dbo.Animals
WITH (STATE = ON, SCHEMABINDING = ON);
GO

-- Modern permissions management (2022 RBAC improvements)
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Animals TO TestUser;
GRANT SHOWPLAN TO TestUser;  -- 2022 granular permission
GRANT VIEW SERVER STATE TO TestUser;
GRANT IMPERSONATE ANY LOGIN TO TestUser WITH GRANT OPTION;
GO

-- Database-level firewall rule (2022 enhancement)
CREATE DATABASE FIREWALL RULE ClientAppRule
  WITH START_IP = '192.168.1.100',
       END_IP = '192.168.1.100';
GO

-- Azure Key Vault integration (2022 improved syntax)
CREATE CRYPTOGRAPHIC PROVIDER AzureKeyVaultProvider
FROM FILE = 'C:\Providers\AzureKeyVault.dll';
GO

CREATE CREDENTIAL AzureKeyVaultCredential
WITH IDENTITY = 'https://testvault.vault.azure.net/',
SECRET = 'AzureADCredential';
GO

-- Temporal table with security (2022 features)
CREATE TABLE dbo.SecureTemporal
(
    ID INT PRIMARY KEY,
    Data NVARCHAR(100),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.SecureTemporalHistory));
GO

-- Security predicate for temporal table
CREATE FUNCTION dbo.fn_temporal_security(@ValidFrom DATETIME2)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
WHERE @ValidFrom > DATEADD(YEAR, -1, GETUTCDATE());
GO

-- Security policy for temporal data access
CREATE SECURITY POLICY TemporalSecurityPolicy
ADD FILTER PREDICATE dbo.fn_temporal_security(ValidFrom)
ON dbo.SecureTemporal,
ADD BLOCK PREDICATE dbo.fn_temporal_security(ValidFrom)
ON dbo.SecureTemporal AFTER INSERT;
GO

-- Modern encryption hierarchy
CREATE COLUMN MASTER KEY TestCMK
WITH (KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
      KEY_PATH = 'https://testvault.vault.azure.net/keys/TestCMK');
GO

-- Query Store security (2022 feature)
ALTER DATABASE TestDB SET QUERY_STORE = ON
  (QUERY_CAPTURE_MODE = AUTO, 
   MAX_PLANS_PER_QUERY = 200,
   WAIT_STATS_CAPTURE_MODE = ON);
GO

-- Audit specification (2022 updates)
CREATE DATABASE AUDIT SPECIFICATION DataChanges
FOR SERVER AUDIT SecurityAudit
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Animals BY public);
GO

-- Security verification queries
SELECT 
  name,
  HAS_PERMS_BY_NAME(name, 'OBJECT', 'SELECT') AS has_select,
  HAS_PERMS_BY_NAME(name, 'OBJECT', 'UPDATE') AS has_update
FROM sys.objects 
WHERE type = 'U';

-- Check ledger verification
EXEC sp_generate_ledger_verification 
  @database_name = N'TestDB',
  @table_name = N'dbo.LedgerTable';
GO

-- Cleanup with modern syntax
DROP SECURITY POLICY IF EXISTS AnimalFilter;
DROP USER IF EXISTS TestUser;
DROP LOGIN IF EXISTS TestLogin;
DROP CERTIFICATE IF EXISTS TestCertificate CASCADE;
GO