-------------------------------------
-- 11: JSON Data
-------------------------------------

USE TestDB;
GO

-- Create a table with JSON data type
CREATE TABLE dbo.Orders
(
    OrderID INT PRIMARY KEY,
    OrderDetails NVARCHAR(MAX)
);
GO

-- Insert sample records
INSERT INTO dbo.Orders (OrderID, OrderDetails)
VALUES
    (1, N'{"Customer":"John Doe","Items":[{"Product":"Laptop","Quantity":1},{"Product":"Mouse","Quantity":2}]}'),
    (2, N'{"Customer":"Jane Smith","Items":[{"Product":"Tablet","Quantity":1},{"Product":"Keyboard","Quantity":1}]}');
GO

-- Test whether a string contains valid JSON
SELECT OrderID, ISJSON(OrderDetails) AS IsValidJSON
FROM dbo.Orders;
GO

-- Construct JSON array text from expressions
SELECT JSON_ARRAY('Laptop', 'Mouse', 'Keyboard') AS ProductsArray;
GO

-- Construct a JSON array from an aggregation of SQL data
SELECT JSON_ARRAYAGG(ProductName) AS ProductsArray
FROM (VALUES ('Laptop'), ('Mouse'), ('Keyboard')) AS Products(ProductName);
GO

-- Update the value of a property in a JSON string
UPDATE dbo.Orders
SET OrderDetails = JSON_MODIFY(OrderDetails, '$.Customer', 'John Smith')
WHERE OrderID = 1;
GO

-- Construct JSON object text from expressions
SELECT JSON_OBJECT('Customer' VALUE 'John Doe', 'OrderID' VALUE 1) AS OrderObject;
GO

-- Construct a JSON object from an aggregation of SQL data
SELECT JSON_OBJECTAGG(OrderID, OrderDetails) AS OrdersObject
FROM dbo.Orders;
GO

-- Test whether a specified SQL/JSON path exists in the input JSON string
SELECT OrderID, JSON_PATH_EXISTS(OrderDetails, '$.Items[0].Product') AS PathExists
FROM dbo.Orders;
GO

-- Extract an object or an array from a JSON string
SELECT OrderID, JSON_QUERY(OrderDetails, '$.Items') AS ItemsArray
FROM dbo.Orders;
GO

-- Extract a scalar value from a JSON string
SELECT OrderID, JSON_VALUE(OrderDetails, '$.Customer') AS CustomerName
FROM dbo.Orders;
GO

-- Parse JSON text and return objects and properties as rows and columns
SELECT OrderID, Item.value('$.Product', 'NVARCHAR(100)') AS Product, Item.value('$.Quantity', 'INT') AS Quantity
FROM dbo.Orders
CROSS APPLY OPENJSON(OrderDetails, '$.Items') WITH (Product NVARCHAR(100), Quantity INT) AS Item;
GO