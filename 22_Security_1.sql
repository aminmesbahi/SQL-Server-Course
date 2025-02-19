/**************************************************************
 * SQL Server 2022 Enhanced Security Tutorial
 * Description: This script demonstrates advanced security features 
 *              in SQL Server 2022 including modern login and RBAC, 
 *              Transparent Data Encryption (TDE), ledger tables, 
 *              certificate management with enclave computations, 
 *              Always Encrypted, dynamic data masking, row-level security, 
 *              firewall rules, Azure Key Vault integration, temporal tables 
 *              with security policies, encryption hierarchy, Query Store 
 *              security, and audit specifications.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Server-Level Security Setup
-------------------------------------------------
/*
  0.1 Use the master database for login and audit operations.
*/
USE master;
GO

/*
  0.2 Create a modern login with enhanced password policies.
       2022 enhancements include MUST_CHANGE and CHECK_EXPIRATION.
*/
CREATE LOGIN TestLogin 
WITH PASSWORD = 'StrongPassword123!' 
  MUST_CHANGE, 
  CHECK_EXPIRATION = ON, 
  CHECK_POLICY = ON;
GO

/*
  0.3 (Optional) Create an Azure AD login for hybrid environments.
  -- CREATE LOGIN [user@domain.com] FROM EXTERNAL PROVIDER;
  -- GO
*/

/*
  0.4 Create a database scoped credential for Azure integration.
*/
CREATE DATABASE SCOPED CREDENTIAL AzureCredential
WITH IDENTITY = 'Managed Identity';
GO

/*
  0.5 Create a server audit for security monitoring.
       2022 enhancements include QUEUE_DELAY and ON_FAILURE options.
*/
CREATE SERVER AUDIT SecurityAudit
TO FILE (FILEPATH = 'C:\Audits\')
WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
GO

ALTER SERVER AUDIT SecurityAudit WITH (STATE = ON);
GO

-------------------------------------------------
-- Region: 1. Database-Level Security Setup
-------------------------------------------------
USE TestDB;
GO

/*
  1.1 Create a database user mapped to the login using modern syntax.
*/
CREATE USER TestUser 
  FOR LOGIN TestLogin
  WITH DEFAULT_SCHEMA = dbo;
GO

/*
  1.2 Enable Ledger for the database (new 2022 feature).
*/
ALTER DATABASE TestDB SET LEDGER = ON;
GO

-------------------------------------------------
-- Region: 2. Ledger Table and Certificate Management
-------------------------------------------------
/*
  2.1 Create a ledger-enabled table for immutable data tracking.
       2022 enhancements include APPEND_ONLY and LEDGER_VIEW options.
*/
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

/*
  2.2 Create a certificate with enclave computations (2022 enhancements).
*/
CREATE CERTIFICATE TestCertificate
  WITH SUBJECT = 'Test Certificate',
       EXPIRY_DATE = '20251231',
       ENCLAVE_COMPUTATIONS;
GO

/*
  2.3 Backup the certificate with private key protection.
*/
BACKUP CERTIFICATE TestCertificate
  TO FILE = 'C:\Certificates\TestCertificate.cer'
  WITH PRIVATE KEY 
  (
    FILE = 'C:\Certificates\TestCertificate.pvk',
    ENCRYPTION_PASSWORD = 'StrongPassword123!'
  );
GO

-------------------------------------------------
-- Region: 3. Always Encrypted and Dynamic Data Masking
-------------------------------------------------
/*
  3.1 Create a column encryption key (placeholder for encrypted value).
       Note: Replace 0x... with the actual encrypted value.
*/
CREATE COLUMN ENCRYPTION KEY TestCEK
WITH VALUES
(
  COLUMN_MASTER_KEY = TestCertificate,
  ALGORITHM = 'RSA_OAEP',
  ENCRYPTED_VALUE = 0x...
);
GO

/*
  3.2 Apply dynamic data masking on an existing table.
       (Assuming dbo.Animals exists; adjust table/column names as needed.)
*/
ALTER TABLE dbo.Animals
ALTER COLUMN SSN ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)');
GO

-------------------------------------------------
-- Region: 4. Row-Level Security (RLS)
-------------------------------------------------
/*
  4.1 Create a security predicate function for row-level security.
       (Assuming a function that filters on UserID; adjust as necessary.)
*/
IF OBJECT_ID(N'dbo.fn_securitypredicate', N'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_securitypredicate;
GO

CREATE FUNCTION dbo.fn_securitypredicate(@UserID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
    SELECT 1 AS fn_Result
    WHERE @UserID = CAST(SESSION_CONTEXT(N'UserID') AS INT);
GO

/*
  4.2 Create a security policy on dbo.Animals using the predicate.
*/
CREATE SECURITY POLICY AnimalFilter
ADD FILTER PREDICATE dbo.fn_securitypredicate(UserID)
ON dbo.Animals
WITH (STATE = ON, SCHEMABINDING = ON);
GO

-------------------------------------------------
-- Region: 5. Modern Permissions and Firewall Rules
-------------------------------------------------
/*
  5.1 Grant modern permissions using RBAC improvements.
*/
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Animals TO TestUser;
GRANT SHOWPLAN TO TestUser;  -- Granular permission for query plans.
GRANT VIEW SERVER STATE TO TestUser;
GRANT IMPERSONATE ANY LOGIN TO TestUser WITH GRANT OPTION;
GO

/*
  5.2 Create a database-level firewall rule.
       2022 enhancement for IP-based access control.
*/
CREATE DATABASE FIREWALL RULE ClientAppRule
  WITH START_IP = '192.168.1.100',
       END_IP = '192.168.1.100';
GO

-------------------------------------------------
-- Region: 6. Azure Key Vault Integration
-------------------------------------------------
/*
  6.1 Create a cryptographic provider for Azure Key Vault.
*/
CREATE CRYPTOGRAPHIC PROVIDER AzureKeyVaultProvider
FROM FILE = 'C:\Providers\AzureKeyVault.dll';
GO

/*
  6.2 Create a credential for Azure Key Vault.
*/
CREATE CREDENTIAL AzureKeyVaultCredential
WITH IDENTITY = 'https://testvault.vault.azure.net/',
     SECRET = 'AzureADCredential';
GO

-------------------------------------------------
-- Region: 7. Temporal Table with Security Enhancements
-------------------------------------------------
/*
  7.1 Create a system-versioned temporal table with security.
*/
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

/*
  7.2 Create a security predicate function for the temporal table.
*/
IF OBJECT_ID(N'dbo.fn_temporal_security', N'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_temporal_security;
GO

CREATE FUNCTION dbo.fn_temporal_security(@ValidFrom DATETIME2)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
    SELECT 1 AS result
    WHERE @ValidFrom > DATEADD(YEAR, -1, GETUTCDATE());
GO

/*
  7.3 Create a security policy for temporal data access.
*/
CREATE SECURITY POLICY TemporalSecurityPolicy
ADD FILTER PREDICATE dbo.fn_temporal_security(ValidFrom)
ON dbo.SecureTemporal,
ADD BLOCK PREDICATE dbo.fn_temporal_security(ValidFrom)
ON dbo.SecureTemporal AFTER INSERT;
GO

-------------------------------------------------
-- Region: 8. Modern Encryption Hierarchy and Query Store Security
-------------------------------------------------
/*
  8.1 Create a column master key integrated with Azure Key Vault.
*/
CREATE COLUMN MASTER KEY TestCMK
WITH (KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
      KEY_PATH = 'https://testvault.vault.azure.net/keys/TestCMK');
GO

/*
  8.2 Configure Query Store with enhanced security options.
*/
ALTER DATABASE TestDB SET QUERY_STORE = ON
  (QUERY_CAPTURE_MODE = AUTO, 
   MAX_PLANS_PER_QUERY = 200,
   WAIT_STATS_CAPTURE_MODE = ON);
GO

-------------------------------------------------
-- Region: 9. Audit Specifications
-------------------------------------------------
/*
  9.1 Create a database audit specification for tracking schema and data changes.
*/
CREATE DATABASE AUDIT SPECIFICATION DataChanges
FOR SERVER AUDIT SecurityAudit
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Animals BY public);
GO

-------------------------------------------------
-- Region: 10. Security Verification and Ledger Checks
-------------------------------------------------
/*
  10.1 Verify object permissions using HAS_PERMS_BY_NAME.
*/
SELECT 
  name,
  HAS_PERMS_BY_NAME(name, 'OBJECT', 'SELECT') AS has_select,
  HAS_PERMS_BY_NAME(name, 'OBJECT', 'UPDATE') AS has_update
FROM sys.objects 
WHERE type = 'U';
GO

/*
  10.2 Check ledger integrity using the ledger verification stored procedure.
*/
EXEC sp_generate_ledger_verification 
  @database_name = N'TestDB',
  @table_name = N'dbo.LedgerTable';
GO

-------------------------------------------------
-- Region: 11. Cleanup
-------------------------------------------------
/*
  Clean up security objects using modern DROP syntax.
*/
DROP SECURITY POLICY IF EXISTS AnimalFilter;
DROP SECURITY POLICY IF EXISTS TemporalSecurityPolicy;
DROP USER IF EXISTS TestUser;
DROP LOGIN IF EXISTS TestLogin;
DROP CERTIFICATE IF EXISTS TestCertificate CASCADE;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------