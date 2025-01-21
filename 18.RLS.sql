-------------------------------------
-- Row-Level Security (Transact-SQL)
-------------------------------------

USE TestDB;
GO

-- Create a sample table
CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    Amount DECIMAL(10, 2)
);
GO

-- Insert sample data
INSERT INTO dbo.Orders (OrderID, CustomerID, OrderDate, Amount)
VALUES
    (1, 1, '2023-01-01', 100.00),
    (2, 2, '2023-01-02', 150.00),
    (3, 1, '2023-01-03', 200.00),
    (4, 3, '2023-01-04', 250.00),
    (5, 2, '2023-01-05', 300.00);
GO

-- Create a security policy
-- Step 1: Create a function to filter rows
CREATE FUNCTION dbo.fn_SecurityPredicate(@CustomerID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_SecurityPredicateResult
WHERE @CustomerID = CAST(SESSION_CONTEXT(N'CustomerID') AS INT);
GO

-- Step 2: Create a security policy using the function
CREATE SECURITY POLICY dbo.OrderSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicate(CustomerID) ON dbo.Orders
WITH (STATE = ON);
GO

-- Test row-level security
-- Set the SESSION_CONTEXT for CustomerID
EXEC sp_set_session_context @key = N'CustomerID', @value = 1;
GO

-- Query the Orders table as CustomerID = 1
SELECT * FROM dbo.Orders;
GO

-- Change the SESSION_CONTEXT for CustomerID
EXEC sp_set_session_context @key = N'CustomerID', @value = 2;
GO

-- Query the Orders table as CustomerID = 2
SELECT * FROM dbo.Orders;
GO

-- Change the SESSION_CONTEXT for CustomerID
EXEC sp_set_session_context @key = N'CustomerID', @value = 3;
GO

-- Query the Orders table as CustomerID = 3
SELECT * FROM dbo.Orders;
GO

-- Disable the security policy
ALTER SECURITY POLICY dbo.OrderSecurityPolicy
WITH (STATE = OFF);
GO

-- Query the Orders table without security policy
SELECT * FROM dbo.Orders;
GO

-- Enable the security policy
ALTER SECURITY POLICY dbo.OrderSecurityPolicy
WITH (STATE = ON);
GO

-- Drop the security policy
DROP SECURITY POLICY dbo.OrderSecurityPolicy;
GO

-- Drop the security function
DROP FUNCTION dbo.fn_SecurityPredicate;
GO

-- Clean up the sample table
DROP TABLE dbo.Orders;
GO