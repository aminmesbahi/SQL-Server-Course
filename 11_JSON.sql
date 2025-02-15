/**************************************************************
 * SQL Server 2022 JSON Data Tutorial
 * Description: This script demonstrates working with JSON data 
 *              in SQL Server. It covers table creation with JSON 
 *              columns, inserting and validating JSON, constructing 
 *              JSON arrays and objects, modifying JSON values, 
 *              testing JSON paths, and extracting JSON data using 
 *              built-in JSON functions.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating Table with JSON Data
-------------------------------------------------
/*
  1.1 Create a table to store orders with a JSON column.
*/
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    OrderDetails NVARCHAR(MAX)  -- Stores JSON data
);
GO

-------------------------------------------------
-- Region: 2. Inserting Sample JSON Data
-------------------------------------------------
/*
  2.1 Insert sample records containing JSON-formatted order details.
*/
INSERT INTO dbo.Orders (OrderID, OrderDetails)
VALUES
    (1, N'{"Customer":"John Doe","Items":[{"Product":"Laptop","Quantity":1},{"Product":"Mouse","Quantity":2}]}'),
    (2, N'{"Customer":"Jane Smith","Items":[{"Product":"Tablet","Quantity":1},{"Product":"Keyboard","Quantity":1}]}');
GO

-------------------------------------------------
-- Region: 3. Validating JSON Data
-------------------------------------------------
/*
  3.1 Test whether the string in OrderDetails is valid JSON.
*/
SELECT 
    OrderID, 
    ISJSON(OrderDetails) AS IsValidJSON
FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: 4. Constructing JSON Arrays
-------------------------------------------------
/*
  4.1 Construct a JSON array from explicit expressions.
*/
SELECT JSON_ARRAY('Laptop', 'Mouse', 'Keyboard') AS ProductsArray;
GO

/*
  4.2 Construct a JSON array from an aggregation of SQL data.
*/
SELECT JSON_ARRAYAGG(ProductName) AS ProductsArray
FROM (VALUES ('Laptop'), ('Mouse'), ('Keyboard')) AS Products(ProductName);
GO

-------------------------------------------------
-- Region: 5. Modifying JSON Data
-------------------------------------------------
/*
  5.1 Update the value of a property in a JSON string.
  This example updates the Customer name in OrderDetails for OrderID = 1.
*/
UPDATE dbo.Orders
SET OrderDetails = JSON_MODIFY(OrderDetails, '$.Customer', 'John Smith')
WHERE OrderID = 1;
GO

-------------------------------------------------
-- Region: 6. Constructing JSON Objects
-------------------------------------------------
/*
  6.1 Construct a JSON object from explicit expressions.
*/
SELECT JSON_OBJECT('Customer' VALUE 'John Doe', 'OrderID' VALUE 1) AS OrderObject;
GO

-------------------------------------------------
-- Region: 7. Testing JSON Paths
-------------------------------------------------
/*
  7.1 Test whether a specified SQL/JSON path exists in the input JSON string.
*/
SELECT 
    OrderID, 
    JSON_PATH_EXISTS(OrderDetails, '$.Items[0].Product') AS PathExists
FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: 8. Extracting Data from JSON
-------------------------------------------------
/*
  8.1 Extract an object or array from a JSON string.
  This example extracts the Items array.
*/
SELECT 
    OrderID, 
    JSON_QUERY(OrderDetails, '$.Items') AS ItemsArray
FROM dbo.Orders;
GO

/*
  8.2 Extract a scalar value from a JSON string.
  This example extracts the Customer name.
*/
SELECT 
    OrderID, 
    JSON_VALUE(OrderDetails, '$.Customer') AS CustomerName
FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: 9. Combining Multiple JSON Functions
-------------------------------------------------
/*
  9.1 Combine multiple JSON functions to validate, test path, construct
      JSON object, and build a JSON array of specific properties.
*/
SELECT 
    OrderID,
    ISJSON(OrderDetails) AS IsValidJSON,
    JSON_PATH_EXISTS(OrderDetails, '$.Items[0].Product') AS PathExists,
    JSON_OBJECT('OrderID' VALUE OrderID, 'Customer' VALUE JSON_VALUE(OrderDetails, '$.Customer')) AS OrderObject,
    JSON_ARRAY(
        JSON_VALUE(OrderDetails, '$.Items[0].Product'),
        JSON_VALUE(OrderDetails, '$.Items[1].Product')
    ) AS ProductsArray
FROM dbo.Orders;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
