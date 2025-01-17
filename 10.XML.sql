-------------------------------------
-- 10: XML Data
-------------------------------------

USE TestDB;
GO

-- Create a table with XML data type
CREATE TABLE dbo.Products
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    ProductDetails XML
);
GO

-- Insert sample records
INSERT INTO dbo.Products (ProductID, ProductName, ProductDetails)
VALUES
    (1, 'Product A', '<Product><Category>Electronics</Category><Price>100</Price></Product>'),
    (2, 'Product B', '<Product><Category>Home Appliances</Category><Price>200</Price></Product>');
GO

-- Query using FOR XML RAW
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML RAW;
GO

-- Query using FOR XML AUTO
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML AUTO;
GO

-- Query using FOR XML EXPLICIT
SELECT 1 AS Tag, NULL AS Parent, ProductID AS [Product!1!ProductID], ProductName AS [Product!1!ProductName]
FROM dbo.Products
FOR XML EXPLICIT;
GO

-- Query using FOR XML PATH
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML PATH('Product');
GO

-- Query using XML Data Type methods
SELECT ProductDetails.value('(/Product/Category)[1]', 'NVARCHAR(100)') AS Category,
       ProductDetails.value('(/Product/Price)[1]', 'DECIMAL(10,2)') AS Price
FROM dbo.Products;
GO

-- Create an XML index
CREATE PRIMARY XML INDEX PXML_ProductDetails ON dbo.Products(ProductDetails);
GO

-- Modify an XML record
UPDATE dbo.Products
SET ProductDetails.modify('replace value of (/Product/Price/text())[1] with 150')
WHERE ProductID = 1;
GO

-- Delete an XML record
DELETE FROM dbo.Products
WHERE ProductID = 2;
GO

-- Create an XML schema collection
CREATE XML SCHEMA COLLECTION ProductSchema AS
N'<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:element name="Product">
        <xs:complexType>
            <xs:sequence>
                <xs:element name="Category" type="xs:string"/>
                <xs:element name="Price" type="xs:decimal"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>
</xs:schema>';
GO

-- Alter table to use XML schema collection
ALTER TABLE dbo.Products
ADD CONSTRAINT CK_ProductDetails CHECK (ProductDetails IS NULL OR ProductDetails.exist('/Product') = 1);
GO

-- Query using FOR XML with schema collection
SELECT ProductID, ProductName, ProductDetails
FROM dbo.Products
FOR XML AUTO, ELEMENTS XSINIL, XMLSCHEMA('ProductSchema');
GO

-- Query using OPENXML
DECLARE @xmlDoc XML;
SET @xmlDoc = '<Products><Product><ProductID>3</ProductID><ProductName>Product C</ProductName></Product></Products>';

DECLARE @hDoc INT;
EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc;

SELECT *
FROM OPENXML(@hDoc, '/Products/Product', 2)
WITH (ProductID INT, ProductName NVARCHAR(100));

EXEC sp_xml_removedocument @hDoc;
GO

-- Query using XQuery and XPath
SELECT ProductDetails.query('/Product/Category') AS Category,
       ProductDetails.query('/Product/Price') AS Price
FROM dbo.Products;
GO