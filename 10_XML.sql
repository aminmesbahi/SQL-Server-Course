/**************************************************************
 * SQL Server 2022 XML Data Tutorial
 * Description: This script demonstrates working with XML data in 
 *              SQL Server. It covers table creation with XML columns, 
 *              inserting sample XML data, various FOR XML queries, 
 *              using XML data type methods, creating XML indexes, 
 *              modifying XML data, XML schema collections, OPENXML, 
 *              and XQuery.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the target database for XML operations.
*/
USE TestDB;
GO

-------------------------------------------------
-- Region: 1. Creating Table with XML Data Type
-------------------------------------------------
/*
  1.1 Create a table to store products, including an XML column.
*/
IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Products
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    ProductDetails XML
);
GO

-------------------------------------------------
-- Region: 2. Inserting Sample XML Data
-------------------------------------------------
/*
  2.1 Insert sample product records with XML details.
*/
INSERT INTO dbo.Products (ProductID, ProductName, ProductDetails)
VALUES
    (1, 'Product A', '<Product><Category>Electronics</Category><Price>100</Price></Product>'),
    (2, 'Product B', '<Product><Category>Home Appliances</Category><Price>200</Price></Product>');
GO

-------------------------------------------------
-- Region: 3. FOR XML Queries
-------------------------------------------------
/*
  3.1 Query using FOR XML RAW.
*/
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML RAW;
GO

/*
  3.2 Query using FOR XML AUTO.
*/
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML AUTO;
GO

/*
  3.3 Query using FOR XML EXPLICIT.
*/
SELECT 1 AS Tag, NULL AS Parent, ProductID AS [Product!1!ProductID], ProductName AS [Product!1!ProductName]
FROM dbo.Products
FOR XML EXPLICIT;
GO

/*
  3.4 Query using FOR XML PATH.
*/
SELECT ProductID, ProductName
FROM dbo.Products
FOR XML PATH('Product');
GO

-------------------------------------------------
-- Region: 4. XML Data Type Methods
-------------------------------------------------
/*
  4.1 Query XML data using XML methods to extract values.
*/
SELECT 
    ProductDetails.value('(/Product/Category)[1]', 'NVARCHAR(100)') AS Category,
    ProductDetails.value('(/Product/Price)[1]', 'DECIMAL(10,2)') AS Price
FROM dbo.Products;
GO

-------------------------------------------------
-- Region: 5. XML Indexes
-------------------------------------------------
/*
  5.1 Create a primary XML index on the ProductDetails column.
*/
CREATE PRIMARY XML INDEX PXML_ProductDetails 
ON dbo.Products(ProductDetails);
GO

-------------------------------------------------
-- Region: 6. Modifying and Deleting XML Data
-------------------------------------------------
/*
  6.1 Modify the XML data: Update the Price value for ProductID 1.
*/
UPDATE dbo.Products
SET ProductDetails.modify('replace value of (/Product/Price/text())[1] with 150')
WHERE ProductID = 1;
GO

/*
  6.2 Delete a product record (and its XML data) from the table.
*/
DELETE FROM dbo.Products
WHERE ProductID = 2;
GO

-------------------------------------------------
-- Region: 7. XML Schema Collections
-------------------------------------------------
/*
  7.1 Create an XML schema collection for product details.
*/
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'ProductSchema')
    DROP XML SCHEMA COLLECTION ProductSchema;
GO

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

/*
  7.2 Alter the Products table to enforce XML schema validation using a CHECK constraint.
*/
ALTER TABLE dbo.Products
ADD CONSTRAINT CK_ProductDetails CHECK (ProductDetails IS NULL OR ProductDetails.exist('/Product') = 1);
GO

/*
  7.3 Query using FOR XML with schema collection.
*/
SELECT ProductID, ProductName, ProductDetails
FROM dbo.Products
FOR XML AUTO, ELEMENTS XSINIL, XMLSCHEMA('ProductSchema');
GO

-------------------------------------------------
-- Region: 8. OPENXML Example
-------------------------------------------------
/*
  8.1 Demonstrate using OPENXML to shred XML data.
*/
DECLARE @xmlDoc XML;
SET @xmlDoc = '<Products>
                  <Product>
                      <ProductID>3</ProductID>
                      <ProductName>Product C</ProductName>
                  </Product>
               </Products>';

DECLARE @hDoc INT;
EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc;

SELECT *
FROM OPENXML(@hDoc, '/Products/Product', 2)
WITH (
    ProductID INT,
    ProductName NVARCHAR(100)
);

EXEC sp_xml_removedocument @hDoc;
GO

-------------------------------------------------
-- Region: 9. XQuery and XPath
-------------------------------------------------
/*
  9.1 Use XQuery to retrieve XML fragments.
*/
SELECT 
    ProductDetails.query('/Product/Category') AS Category,
    ProductDetails.query('/Product/Price') AS Price
FROM dbo.Products;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
