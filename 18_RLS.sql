/**************************************************************
 * SQL Server 2022 Row-Level Security (RLS) Tutorial
 * Description: This script demonstrates how to implement row-level
 *              security using a security policy and a predicate
 *              function in SQL Server. It covers:
 *              - Creating a sample table and inserting data.
 *              - Creating a security predicate function.
 *              - Creating a security policy to filter rows.
 *              - Testing row-level security using SESSION_CONTEXT.
 *              - Enabling/disabling and cleaning up the security policy.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure that the target database is being used.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating Sample Table and Inserting Data
-------------------------------------------------
/*
  1.1 Create a sample Orders table to demonstrate RLS.
*/
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    Amount DECIMAL(10, 2)
);
GO

/*
  1.2 Insert sample orders into the Orders table.
*/
INSERT INTO dbo.Orders (OrderID, CustomerID, OrderDate, Amount)
VALUES
    (1, 1, '2023-01-01', 100.00),
    (2, 2, '2023-01-02', 150.00),
    (3, 1, '2023-01-03', 200.00),
    (4, 3, '2023-01-04', 250.00),
    (5, 2, '2023-01-05', 300.00);
GO

-------------------------------------------------
-- Region: 2. Implementing Row-Level Security
-------------------------------------------------
/*
  2.1 Create a security predicate function.
       This function filters rows based on the CustomerID value 
       stored in the SESSION_CONTEXT.
*/
IF OBJECT_ID(N'dbo.fn_SecurityPredicate', N'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_SecurityPredicate;
GO

CREATE FUNCTION dbo.fn_SecurityPredicate(@CustomerID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
    SELECT 1 AS fn_SecurityPredicateResult
    WHERE @CustomerID = CAST(SESSION_CONTEXT(N'CustomerID') AS INT);
GO

/*
  2.2 Create a security policy using the predicate function.
       This policy will filter rows in the Orders table.
*/
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'dbo.OrderSecurityPolicy')
    DROP SECURITY POLICY dbo.OrderSecurityPolicy;
GO

CREATE SECURITY POLICY dbo.OrderSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicate(CustomerID) ON dbo.Orders
WITH (STATE = ON);
GO

-------------------------------------------------
-- Region: 3. Testing Row-Level Security
-------------------------------------------------
/*
  3.1 Set SESSION_CONTEXT for CustomerID = 1 and query the Orders table.
*/
EXEC sp_set_session_context @key = N'CustomerID', @value = 1;
GO

SELECT * FROM dbo.Orders;
GO

/*
  3.2 Set SESSION_CONTEXT for CustomerID = 2 and query the Orders table.
*/
EXEC sp_set_session_context @key = N'CustomerID', @value = 2;
GO

SELECT * FROM dbo.Orders;
GO

/*
  3.3 Set SESSION_CONTEXT for CustomerID = 3 and query the Orders table.
*/
EXEC sp_set_session_context @key = N'CustomerID', @value = 3;
GO

SELECT * FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: 4. Managing the Security Policy
-------------------------------------------------
/*
  4.1 Disable the security policy.
*/
ALTER SECURITY POLICY dbo.OrderSecurityPolicy
WITH (STATE = OFF);
GO

/*
  4.2 Query the Orders table without the security policy in effect.
*/
SELECT * FROM dbo.Orders;
GO

/*
  4.3 Re-enable the security policy.
*/
ALTER SECURITY POLICY dbo.OrderSecurityPolicy
WITH (STATE = ON);
GO

-------------------------------------------------
-- Region: 5. Cleanup
-------------------------------------------------
/*
  5.1 Drop the security policy.
*/
DROP SECURITY POLICY dbo.OrderSecurityPolicy;
GO

/*
  5.2 Drop the security predicate function.
*/
DROP FUNCTION dbo.fn_SecurityPredicate;
GO

/*
  5.3 Drop the sample Orders table.
*/
DROP TABLE dbo.Orders;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
