/**************************************************************
 * SQL Server 2022 Localization and Globalization Tutorial
 * Description: This script demonstrates how to work with localization
 *              and globalization features in SQL Server 2022. It covers:
 *              - Working with different language settings
 *              - Date and time formatting across locales
 *              - Currency formatting and conversion
 *              - Collation settings and impact
 *              - String sorting and comparison in different cultures
 *              - Using locale-specific functions
 *              - Handling multilingual data and internationalization
 **************************************************************/

-------------------------------------------------
-- Region: 1. Understanding Language and Locale Settings
-------------------------------------------------
USE master;
GO

/*
  Create a test database for our examples.
*/
IF DB_ID('LocalizationDemo') IS NOT NULL
BEGIN
    ALTER DATABASE LocalizationDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LocalizationDemo;
END
GO

CREATE DATABASE LocalizationDemo;
GO

USE LocalizationDemo;
GO

/*
  Check the current language settings.
  This will show the current language and associated settings.
*/
SELECT @@LANGUAGE AS CurrentLanguage;
GO

/*
  Check available languages in SQL Server.
*/
SELECT * FROM sys.syslanguages;
GO

/*
  Set a specific language for the current session.
  This affects how dates, messages, and other locale-specific data are displayed.
*/
SET LANGUAGE us_english;
GO

-- Compare with a different language setting
SET LANGUAGE French;
GO

SELECT @@LANGUAGE AS CurrentLanguage;
GO

-- Reset to English for subsequent examples
SET LANGUAGE us_english;
GO

-------------------------------------------------
-- Region: 2. Working with Date Formats
-------------------------------------------------
/*
  Date formats vary significantly between languages and regions.
  SQL Server handles dates differently based on language settings.
*/

-- Create a sample table with dates
CREATE TABLE dbo.DateExamples
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(100),
    EventDate DATETIME2
);
GO

-- Insert sample data
INSERT INTO dbo.DateExamples (EventName, EventDate)
VALUES 
    ('New Year', '2023-01-01'),
    ('Independence Day', '2023-07-04'),
    ('Christmas', '2023-12-25');
GO

-- Show date display in different language settings
-- US English (MM/DD/YYYY)
SET LANGUAGE us_english;
SELECT 
    EventName,
    EventDate,
    CONVERT(VARCHAR, EventDate, 101) AS FormattedDate -- mm/dd/yyyy
FROM dbo.DateExamples;
GO

-- British English (DD/MM/YYYY)
SET LANGUAGE British;
SELECT 
    EventName,
    EventDate,
    CONVERT(VARCHAR, EventDate, 103) AS FormattedDate -- dd/mm/yyyy
FROM dbo.DateExamples;
GO

-- German (DD.MM.YYYY)
SET LANGUAGE German;
SELECT 
    EventName,
    EventDate,
    CONVERT(VARCHAR, EventDate, 104) AS FormattedDate -- dd.mm.yyyy
FROM dbo.DateExamples;
GO

-- Japanese (YYYY/MM/DD)
SET LANGUAGE Japanese;
SELECT 
    EventName,
    EventDate,
    CONVERT(VARCHAR, EventDate, 111) AS FormattedDate -- yyyy/mm/dd
FROM dbo.DateExamples;
GO

/*
  Date input and interpretation also depends on language settings.
  The same date string might be interpreted differently.
*/
SET LANGUAGE us_english;
SELECT 
    TRY_CONVERT(DATETIME2, '02/03/2023') AS US_English, -- February 3, 2023
    FORMAT(TRY_CONVERT(DATETIME2, '02/03/2023'), 'MMMM d, yyyy', 'en-US') AS US_Interpretation;

SET LANGUAGE British;
SELECT 
    TRY_CONVERT(DATETIME2, '02/03/2023') AS British_English, -- March 2, 2023
    FORMAT(TRY_CONVERT(DATETIME2, '02/03/2023'), 'MMMM d, yyyy', 'en-GB') AS British_Interpretation;
GO

/*
  Using the DATE_FORMAT function (SQL Server 2022) to handle cultural date formatting.
*/
SET LANGUAGE us_english;
GO

-- Format using specific cultures
SELECT 
    EventDate,
    FORMAT(EventDate, 'd', 'en-US') AS US_ShortDate,        -- M/d/yyyy
    FORMAT(EventDate, 'd', 'en-GB') AS British_ShortDate,   -- dd/MM/yyyy
    FORMAT(EventDate, 'd', 'de-DE') AS German_ShortDate,    -- dd.MM.yyyy
    FORMAT(EventDate, 'd', 'ja-JP') AS Japanese_ShortDate,  -- yyyy/MM/dd
    FORMAT(EventDate, 'D', 'fr-FR') AS French_LongDate      -- Long date format in French
FROM dbo.DateExamples;
GO

-- Using custom date formats with FORMAT
SELECT
    EventDate,
    FORMAT(EventDate, 'yyyy-MM-dd') AS ISO_Format,
    FORMAT(EventDate, 'MMM d, yyyy', 'en-US') AS US_CustomFormat,
    FORMAT(EventDate, 'dd MMMM yyyy', 'fr-FR') AS French_CustomFormat,
    FORMAT(EventDate, 'yyyy年MM月dd日', 'ja-JP') AS Japanese_CustomFormat
FROM dbo.DateExamples;
GO

-------------------------------------------------
-- Region: 3. Working with Currency Formats
-------------------------------------------------
/*
  Currency formats vary by culture, including symbol position, 
  decimal separator, and grouping.
*/

-- Create a table for price examples
CREATE TABLE dbo.ProductCatalog
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2)
);
GO

-- Insert sample data
INSERT INTO dbo.ProductCatalog (ProductName, Price)
VALUES 
    ('Laptop', 1299.99),
    ('Smartphone', 799.50),
    ('Headphones', 249.95),
    ('Monitor', 349.99),
    ('Tablet', 599.00);
GO

-- Format currency values using different cultures
SELECT 
    ProductName,
    Price,
    FORMAT(Price, 'C', 'en-US') AS US_Currency,         -- $1,299.99
    FORMAT(Price, 'C', 'en-GB') AS British_Currency,    -- £1,299.99
    FORMAT(Price, 'C', 'fr-FR') AS French_Currency,     -- 1 299,99 €
    FORMAT(Price, 'C', 'de-DE') AS German_Currency,     -- 1.299,99 €
    FORMAT(Price, 'C', 'ja-JP') AS Japanese_Currency,   -- ¥1,300
    FORMAT(Price, 'C', 'zh-CN') AS Chinese_Currency     -- ¥1,299.99
FROM dbo.ProductCatalog;
GO

-- Create a function to convert between currencies
CREATE OR ALTER FUNCTION dbo.ConvertCurrency
(
    @Amount DECIMAL(18,2),
    @FromCurrency VARCHAR(3),
    @ToCurrency VARCHAR(3),
    @ConversionDate DATE = NULL
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    -- In a real scenario, you would look up current exchange rates
    -- from a table or external service. For demonstration, we use static rates.
    
    DECLARE @Result DECIMAL(18,2);
    DECLARE @ToUSD DECIMAL(18,6);
    DECLARE @FromUSD DECIMAL(18,6);
    
    -- Use today's date if none provided
    IF @ConversionDate IS NULL
        SET @ConversionDate = GETDATE();
    
    -- Example exchange rates to USD (as of a specific date)
    SELECT @ToUSD = CASE @FromCurrency
        WHEN 'USD' THEN 1.0
        WHEN 'EUR' THEN 1.09  -- 1 EUR = 1.09 USD
        WHEN 'GBP' THEN 1.27  -- 1 GBP = 1.27 USD
        WHEN 'JPY' THEN 0.0068 -- 1 JPY = 0.0068 USD
        WHEN 'CNY' THEN 0.14  -- 1 CNY = 0.14 USD
        ELSE 1.0
    END;
    
    -- Example exchange rates from USD
    SELECT @FromUSD = CASE @ToCurrency
        WHEN 'USD' THEN 1.0
        WHEN 'EUR' THEN 0.92  -- 1 USD = 0.92 EUR
        WHEN 'GBP' THEN 0.79  -- 1 USD = 0.79 GBP
        WHEN 'JPY' THEN 147.0 -- 1 USD = 147 JPY
        WHEN 'CNY' THEN 7.14  -- 1 USD = 7.14 CNY
        ELSE 1.0
    END;
    
    -- Convert to USD first, then to target currency
    SET @Result = @Amount * @ToUSD * @FromUSD;
    
    RETURN @Result;
END;
GO

-- Use the currency conversion function
SELECT 
    ProductName,
    Price AS USD_Price,
    dbo.ConvertCurrency(Price, 'USD', 'EUR', GETDATE()) AS EUR_Price,
    dbo.ConvertCurrency(Price, 'USD', 'GBP', GETDATE()) AS GBP_Price,
    dbo.ConvertCurrency(Price, 'USD', 'JPY', GETDATE()) AS JPY_Price,
    dbo.ConvertCurrency(Price, 'USD', 'CNY', GETDATE()) AS CNY_Price
FROM dbo.ProductCatalog;
GO

-- Format the converted amounts with appropriate currency symbols
SELECT 
    ProductName,
    FORMAT(Price, 'C', 'en-US') AS USD_Price,
    FORMAT(dbo.ConvertCurrency(Price, 'USD', 'EUR', GETDATE()), 'C', 'fr-FR') AS EUR_Price,
    FORMAT(dbo.ConvertCurrency(Price, 'USD', 'GBP', GETDATE()), 'C', 'en-GB') AS GBP_Price,
    FORMAT(dbo.ConvertCurrency(Price, 'USD', 'JPY', GETDATE()), 'C', 'ja-JP') AS JPY_Price,
    FORMAT(dbo.ConvertCurrency(Price, 'USD', 'CNY', GETDATE()), 'C', 'zh-CN') AS CNY_Price
FROM dbo.ProductCatalog;
GO

-------------------------------------------------
-- Region: 4. Working with Collations
-------------------------------------------------
/*
  Collations determine how text data is stored, compared, and sorted.
  They affect case sensitivity, accent sensitivity, and character sorting.
*/

-- Check the server's default collation
SELECT SERVERPROPERTY('Collation') AS ServerCollation;
GO

-- Check the database collation
SELECT name, collation_name 
FROM sys.databases 
WHERE name = 'LocalizationDemo';
GO

-- Create tables with different collations
CREATE TABLE dbo.Names_CI_AS 
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PersonName NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS -- Case Insensitive, Accent Sensitive
);

CREATE TABLE dbo.Names_CS_AS 
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PersonName NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AS -- Case Sensitive, Accent Sensitive
);

CREATE TABLE dbo.Names_CI_AI 
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    PersonName NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI -- Case Insensitive, Accent Insensitive
);
GO

-- Insert the same data into all tables
INSERT INTO dbo.Names_CI_AS (PersonName)
VALUES ('John'), ('john'), ('José'), ('Jose'), ('Zoë'), ('Zoe');

INSERT INTO dbo.Names_CS_AS (PersonName)
VALUES ('John'), ('john'), ('José'), ('Jose'), ('Zoë'), ('Zoe');

INSERT INTO dbo.Names_CI_AI (PersonName)
VALUES ('John'), ('john'), ('José'), ('Jose'), ('Zoë'), ('Zoe');
GO

-- Compare results from different collations
SELECT PersonName FROM dbo.Names_CI_AS WHERE PersonName = 'john'; -- Returns 'John' and 'john'
SELECT PersonName FROM dbo.Names_CS_AS WHERE PersonName = 'john'; -- Returns only 'john'
SELECT PersonName FROM dbo.Names_CI_AI WHERE PersonName = 'jose'; -- Returns 'José' and 'Jose'
GO

-- Sorting behavior with different collations
SELECT PersonName FROM dbo.Names_CI_AS ORDER BY PersonName;
SELECT PersonName FROM dbo.Names_CS_AS ORDER BY PersonName;
SELECT PersonName FROM dbo.Names_CI_AI ORDER BY PersonName;
GO

-- Using COLLATE to override default collation in queries
SELECT PersonName 
FROM dbo.Names_CS_AS 
WHERE PersonName COLLATE SQL_Latin1_General_CP1_CI_AS = 'john';
GO

/*
  Collations with different languages sort strings differently
*/
CREATE TABLE dbo.MultilingualSort
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Word NVARCHAR(50)
);
GO

-- Insert words with special characters from different languages
INSERT INTO dbo.MultilingualSort (Word)
VALUES 
    ('Apple'), ('Árbol'), ('Zebra'), ('Ångström'), ('Café'), ('Château'), ('Über'), ('Ñandu');
GO

-- Compare sorting in different language collations
SELECT Word FROM dbo.MultilingualSort 
ORDER BY Word COLLATE SQL_Latin1_General_CP1_CI_AS;

SELECT Word FROM dbo.MultilingualSort 
ORDER BY Word COLLATE Finnish_Swedish_CI_AS;

SELECT Word FROM dbo.MultilingualSort 
ORDER BY Word COLLATE Spanish_CI_AS;
GO

-------------------------------------------------
-- Region: 5. Multilingual Data Storage
-------------------------------------------------
/*
  For applications that need to support multiple languages,
  it's common to store translations in a structured format.
*/

-- Create a products table
CREATE TABLE dbo.Products
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    SKU NVARCHAR(20) NOT NULL,
    Price MONEY NOT NULL
);
GO

-- Create a translations table
CREATE TABLE dbo.ProductTranslations
(
    TranslationID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    LanguageCode NVARCHAR(10) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    CONSTRAINT FK_ProductTranslations_Products FOREIGN KEY (ProductID) REFERENCES dbo.Products (ProductID),
    CONSTRAINT UQ_ProductTranslation UNIQUE (ProductID, LanguageCode)
);
GO

-- Insert sample products
INSERT INTO dbo.Products (SKU, Price)
VALUES 
    ('LAPTOP-001', 1299.99),
    ('PHONE-001', 799.50),
    ('HDPHONE-001', 249.95);
GO

-- Insert translations for each product
INSERT INTO dbo.ProductTranslations (ProductID, LanguageCode, ProductName, Description)
VALUES
    -- English translations
    (1, 'en-US', 'Professional Laptop', 'High-performance laptop for professionals'),
    (2, 'en-US', 'Smartphone', 'Feature-rich smartphone with high-resolution camera'),
    (3, 'en-US', 'Wireless Headphones', 'Premium noise-cancelling wireless headphones'),
    
    -- Spanish translations
    (1, 'es-ES', 'Portátil Profesional', 'Portátil de alto rendimiento para profesionales'),
    (2, 'es-ES', 'Teléfono Inteligente', 'Teléfono inteligente con cámara de alta resolución'),
    (3, 'es-ES', 'Auriculares Inalámbricos', 'Auriculares inalámbricos premium con cancelación de ruido'),
    
    -- French translations
    (1, 'fr-FR', 'Ordinateur Portable Professionnel', 'Ordinateur portable haute performance pour les professionnels'),
    (2, 'fr-FR', 'Smartphone', 'Smartphone riche en fonctionnalités avec caméra haute résolution'),
    (3, 'fr-FR', 'Écouteurs Sans Fil', 'Écouteurs sans fil haut de gamme à réduction de bruit'),
    
    -- German translations
    (1, 'de-DE', 'Profi-Laptop', 'Hochleistungs-Laptop für Profis'),
    (2, 'de-DE', 'Smartphone', 'Funktionsreiches Smartphone mit hochauflösender Kamera'),
    (3, 'de-DE', 'Kabellose Kopfhörer', 'Premium-Noise-Cancelling-Kopfhörer')
GO

-- Create a function to get product details in a specific language
CREATE OR ALTER FUNCTION dbo.GetProductDetails
(
    @LanguageCode NVARCHAR(10) = 'en-US'
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.ProductID,
        p.SKU,
        p.Price,
        ISNULL(pt.ProductName, pt_en.ProductName) AS ProductName,
        ISNULL(pt.Description, pt_en.Description) AS Description,
        FORMAT(p.Price, 'C', @LanguageCode) AS FormattedPrice
    FROM dbo.Products p
    LEFT JOIN dbo.ProductTranslations pt ON p.ProductID = pt.ProductID AND pt.LanguageCode = @LanguageCode
    LEFT JOIN dbo.ProductTranslations pt_en ON p.ProductID = pt_en.ProductID AND pt_en.LanguageCode = 'en-US'
);
GO

-- Get product details in different languages
SELECT * FROM dbo.GetProductDetails('en-US'); -- English
SELECT * FROM dbo.GetProductDetails('es-ES'); -- Spanish
SELECT * FROM dbo.GetProductDetails('fr-FR'); -- French
SELECT * FROM dbo.GetProductDetails('de-DE'); -- German
SELECT * FROM dbo.GetProductDetails('ja-JP'); -- Japanese (falls back to English)
GO

-------------------------------------------------
-- Region: 6. Numbers and Measurement Conversions
-------------------------------------------------
/*
  Different regions use different units of measurement.
  Here we create functions to convert between them.
*/

-- Create a function for temperature conversion
CREATE OR ALTER FUNCTION dbo.ConvertTemperature
(
    @Value DECIMAL(10,2),
    @FromUnit CHAR(1),
    @ToUnit CHAR(1)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Result DECIMAL(10,2);
    
    -- Convert to Celsius first (as the intermediate step)
    DECLARE @Celsius DECIMAL(10,2);
    SET @Celsius = CASE @FromUnit
        WHEN 'C' THEN @Value
        WHEN 'F' THEN (@Value - 32) * 5 / 9
        WHEN 'K' THEN @Value - 273.15
        ELSE @Value -- Default to Celsius
    END;
    
    -- Convert from Celsius to target unit
    SET @Result = CASE @ToUnit
        WHEN 'C' THEN @Celsius
        WHEN 'F' THEN (@Celsius * 9 / 5) + 32
        WHEN 'K' THEN @Celsius + 273.15
        ELSE @Celsius -- Default to Celsius
    END;
    
    RETURN @Result;
END;
GO

-- Create a function for length conversion
CREATE OR ALTER FUNCTION dbo.ConvertLength
(
    @Value DECIMAL(18,6),
    @FromUnit VARCHAR(10),
    @ToUnit VARCHAR(10)
)
RETURNS DECIMAL(18,6)
AS
BEGIN
    DECLARE @Result DECIMAL(18,6);
    
    -- Convert to meters first (as the intermediate step)
    DECLARE @Meters DECIMAL(18,6);
    SET @Meters = CASE @FromUnit
        WHEN 'meter' THEN @Value
        WHEN 'kilometer' THEN @Value * 1000
        WHEN 'centimeter' THEN @Value / 100
        WHEN 'millimeter' THEN @Value / 1000
        WHEN 'inch' THEN @Value * 0.0254
        WHEN 'foot' THEN @Value * 0.3048
        WHEN 'yard' THEN @Value * 0.9144
        WHEN 'mile' THEN @Value * 1609.344
        ELSE @Value -- Default to meters
    END;
    
    -- Convert from meters to target unit
    SET @Result = CASE @ToUnit
        WHEN 'meter' THEN @Meters
        WHEN 'kilometer' THEN @Meters / 1000
        WHEN 'centimeter' THEN @Meters * 100
        WHEN 'millimeter' THEN @Meters * 1000
        WHEN 'inch' THEN @Meters / 0.0254
        WHEN 'foot' THEN @Meters / 0.3048
        WHEN 'yard' THEN @Meters / 0.9144
        WHEN 'mile' THEN @Meters / 1609.344
        ELSE @Meters -- Default to meters
    END;
    
    RETURN @Result;
END;
GO

-- Create a function for weight/mass conversion
CREATE OR ALTER FUNCTION dbo.ConvertWeight
(
    @Value DECIMAL(18,6),
    @FromUnit VARCHAR(10),
    @ToUnit VARCHAR(10)
)
RETURNS DECIMAL(18,6)
AS
BEGIN
    DECLARE @Result DECIMAL(18,6);
    
    -- Convert to kilograms first (as the intermediate step)
    DECLARE @Kilograms DECIMAL(18,6);
    SET @Kilograms = CASE @FromUnit
        WHEN 'kilogram' THEN @Value
        WHEN 'gram' THEN @Value / 1000
        WHEN 'milligram' THEN @Value / 1000000
        WHEN 'pound' THEN @Value * 0.45359237
        WHEN 'ounce' THEN @Value * 0.0283495
        WHEN 'ton' THEN @Value * 907.18474
        WHEN 'tonne' THEN @Value * 1000
        ELSE @Value -- Default to kilograms
    END;
    
    -- Convert from kilograms to target unit
    SET @Result = CASE @ToUnit
        WHEN 'kilogram' THEN @Kilograms
        WHEN 'gram' THEN @Kilograms * 1000
        WHEN 'milligram' THEN @Kilograms * 1000000
        WHEN 'pound' THEN @Kilograms / 0.45359237
        WHEN 'ounce' THEN @Kilograms / 0.0283495
        WHEN 'ton' THEN @Kilograms / 907.18474
        WHEN 'tonne' THEN @Kilograms / 1000
        ELSE @Kilograms -- Default to kilograms
    END;
    
    RETURN @Result;
END;
GO

-- Test the conversion functions
SELECT 
    -- Temperature conversions
    dbo.ConvertTemperature(32, 'F', 'C') AS Freezing_F_to_C,
    dbo.ConvertTemperature(100, 'C', 'F') AS Boiling_C_to_F,
    dbo.ConvertTemperature(20, 'C', 'K') AS Room_Temp_C_to_K,
    
    -- Length conversions
    dbo.ConvertLength(1, 'mile', 'kilometer') AS Mile_to_KM,
    dbo.ConvertLength(1, 'meter', 'foot') AS Meter_to_Feet,
    dbo.ConvertLength(1, 'inch', 'centimeter') AS Inch_to_CM,
    
    -- Weight conversions
    dbo.ConvertWeight(1, 'pound', 'kilogram') AS Pound_to_KG,
    dbo.ConvertWeight(1, 'tonne', 'ton') AS Metric_to_US_Ton,
    dbo.ConvertWeight(100, 'gram', 'ounce') AS Gram_to_Ounce;
GO

-- Create a table for product specifications with different units
CREATE TABLE dbo.ProductSpecs
(
    SpecID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT REFERENCES dbo.Products (ProductID),
    SpecName NVARCHAR(100),
    NumericValue DECIMAL(18,6),
    Unit VARCHAR(10),
    CONSTRAINT UQ_ProductSpec UNIQUE (ProductID, SpecName)
);
GO

-- Insert some sample specifications
INSERT INTO dbo.ProductSpecs (ProductID, SpecName, NumericValue, Unit)
VALUES
    (1, 'Weight', 2.1, 'kilogram'),  -- Laptop weight in kg
    (1, 'Screen Size', 15.6, 'inch'), -- Laptop screen in inches
    (1, 'Thickness', 18, 'millimeter'), -- Laptop thickness in mm
    
    (2, 'Weight', 180, 'gram'),      -- Phone weight in g
    (2, 'Screen Size', 6.5, 'inch'),  -- Phone screen in inches
    (2, 'Thickness', 7.5, 'millimeter'), -- Phone thickness in mm
    
    (3, 'Weight', 250, 'gram'),      -- Headphones weight in g
    (3, 'Cable Length', 1.2, 'meter'), -- Cable length in m
    (3, 'Driver Size', 40, 'millimeter'); -- Driver size in mm
GO

-- Create a procedure to get product specs in different unit systems
CREATE OR ALTER PROCEDURE dbo.GetProductSpecsInUnitSystem
    @ProductID INT,
    @UnitSystem VARCHAR(10) = 'metric' -- 'metric' or 'imperial'
AS
BEGIN
    SELECT 
        p.ProductID,
        pt.ProductName,
        ps.SpecName,
        CASE
            -- Weight conversions
            WHEN ps.SpecName = 'Weight' AND ps.Unit = 'kilogram' AND @UnitSystem = 'imperial'
                THEN dbo.ConvertWeight(ps.NumericValue, 'kilogram', 'pound')
            WHEN ps.SpecName = 'Weight' AND ps.Unit = 'gram' AND @UnitSystem = 'imperial'
                THEN dbo.ConvertWeight(ps.NumericValue, 'gram', 'ounce')
                
            -- Length/size conversions
            WHEN ps.SpecName LIKE '%Size%' AND ps.Unit = 'inch' AND @UnitSystem = 'metric'
                THEN dbo.ConvertLength(ps.NumericValue, 'inch', 'centimeter')
            WHEN ps.SpecName LIKE '%Length%' AND ps.Unit = 'meter' AND @UnitSystem = 'imperial'
                THEN dbo.ConvertLength(ps.NumericValue, 'meter', 'foot')
            WHEN ps.SpecName LIKE '%Thickness%' AND ps.Unit = 'millimeter' AND @UnitSystem = 'imperial'
                THEN dbo.ConvertLength(ps.NumericValue, 'millimeter', 'inch')
                
            ELSE ps.NumericValue
        END AS Value,
        CASE
            -- Weight unit conversions
            WHEN ps.SpecName = 'Weight' AND ps.Unit = 'kilogram' AND @UnitSystem = 'imperial'
                THEN 'pound'
            WHEN ps.SpecName = 'Weight' AND ps.Unit = 'gram' AND @UnitSystem = 'imperial'
                THEN 'ounce'
                
            -- Length/size unit conversions
            WHEN ps.SpecName LIKE '%Size%' AND ps.Unit = 'inch' AND @UnitSystem = 'metric'
                THEN 'centimeter'
            WHEN ps.SpecName LIKE '%Length%' AND ps.Unit = 'meter' AND @UnitSystem = 'imperial'
                THEN 'foot'
            WHEN ps.SpecName LIKE '%Thickness%' AND ps.Unit = 'millimeter' AND @UnitSystem = 'imperial'
                THEN 'inch'
                
            ELSE ps.Unit
        END AS Unit
    FROM 
        dbo.ProductSpecs ps
    JOIN 
        dbo.Products p ON ps.ProductID = p.ProductID
    JOIN 
        dbo.ProductTranslations pt ON p.ProductID = pt.ProductID AND pt.LanguageCode = 'en-US'
    WHERE 
        p.ProductID = @ProductID
    ORDER BY 
        ps.SpecName;
END;
GO

-- Test product specs in different unit systems
EXEC dbo.GetProductSpecsInUnitSystem @ProductID = 1, @UnitSystem = 'metric';
EXEC dbo.GetProductSpecsInUnitSystem @ProductID = 1, @UnitSystem = 'imperial';
GO

-------------------------------------------------
-- Region: 7. Formatting Numbers and Percentages
-------------------------------------------------
/*
  Number formatting varies by culture, including decimal separator,
  thousand separator, and digit grouping.
*/

-- Create a sample table with numeric data
CREATE TABLE dbo.SalesStatistics
(
    RegionID INT IDENTITY(1,1) PRIMARY KEY,
    RegionName NVARCHAR(100),
    SalesAmount DECIMAL(18,2),
    GrowthRate DECIMAL(9,4)
);
GO

-- Insert sample data
INSERT INTO dbo.SalesStatistics (RegionName, SalesAmount, GrowthRate)
VALUES 
    ('North America', 1234567.89, 0.1245),
    ('Europe', 987654.32, 0.0875),
    ('Asia Pacific', 2345678.90, 0.1657),
    ('Latin America', 567890.12, 0.2134),
    ('Middle East', 345678.90, -0.0325);
GO

-- Format numbers for different regions
SELECT 
    RegionName,
    SalesAmount,
    GrowthRate,
    -- Numbers
    FORMAT(SalesAmount, 'N', 'en-US') AS US_Number,        -- 1,234,567.89
    FORMAT(SalesAmount, 'N', 'de-DE') AS German_Number,    -- 1.234.567,89
    FORMAT(SalesAmount, 'N', 'fr-FR') AS French_Number,    -- 1 234 567,89
    
    -- Percentages
    FORMAT(GrowthRate, 'P', 'en-US') AS US_Percentage,     -- 12.45%
    FORMAT(GrowthRate, 'P', 'de-DE') AS German_Percentage, -- 12,45%
    FORMAT(GrowthRate, 'P', 'fr-FR') AS French_Percentage  -- 12,45%
FROM dbo.SalesStatistics;
GO

-- Using CAST with local settings vs. FORMAT with specific culture
SET LANGUAGE us_english;
SELECT 
    CAST(SalesAmount AS NVARCHAR) AS Default_Cast,
    FORMAT(SalesAmount, '0,0.00', 'en-US') AS US_Format,
    FORMAT(SalesAmount, '0,0.00', 'de-DE') AS German_Format,
    FORMAT(SalesAmount, '0,0.00', 'fr-FR') AS French_Format
FROM dbo.SalesStatistics;
GO

-- Number of digits after decimal point
SELECT 
    GrowthRate,
    FORMAT(GrowthRate, 'P0', 'en-US') AS Percent_0Decimal,  -- 12%
    FORMAT(GrowthRate, 'P1', 'en-US') AS Percent_1Decimal,  -- 12.5%
    FORMAT(GrowthRate, 'P2', 'en-US') AS Percent_2Decimal,  -- 12.45%
    FORMAT(GrowthRate, 'P3', 'en-US') AS Percent_3Decimal   -- 12.450%
FROM dbo.SalesStatistics;
GO

-------------------------------------------------
-- Region: 8. Handling Right-to-Left Languages
-------------------------------------------------
/*
  Right-to-Left (RTL) languages like Arabic and Hebrew require special handling.
  SQL Server stores the data correctly, but display is managed by the client.
*/

-- Create a table for multilingual content
CREATE TABLE dbo.MultilingualContent
(
    ContentID INT IDENTITY(1,1) PRIMARY KEY,
    LanguageCode NVARCHAR(10) NOT NULL,
    IsRightToLeft BIT NOT NULL DEFAULT 0,
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL
);
GO

-- Insert sample content in different languages
INSERT INTO dbo.MultilingualContent (LanguageCode, IsRightToLeft, Title, Content)
VALUES 
    -- English (Left-to-Right)
    ('en-US', 0, 'Welcome to SQL Server', 'SQL Server provides powerful features for globalization and localization.'),
    
    -- French (Left-to-Right)
    ('fr-FR', 0, 'Bienvenue à SQL Server', 'SQL Server offre des fonctionnalités puissantes pour la mondialisation et la localisation.'),
    
    -- Arabic (Right-to-Left)
    ('ar-SA', 1, N'مرحبًا بك في SQL Server', N'يوفر SQL Server ميزات قوية للعولمة والتوطين.'),
    
    -- Hebrew (Right-to-Left)
    ('he-IL', 1, N'ברוך הבא ל- SQL Server', N'SQL Server מספק תכונות חזקות לגלובליזציה ולוקליזציה.');
GO

-- Query the multilingual content
SELECT * FROM dbo.MultilingualContent;
GO

/*
  Note: When displaying RTL text in applications,
  you typically need to set appropriate CSS (direction: rtl) 
  or use equivalent settings in your application UI.
*/

-------------------------------------------------
-- Region: 9. Localization Best Practices
-------------------------------------------------
/*
  Summary of best practices for localization in SQL Server.
*/

-- 1. Use Unicode data types for international character support
CREATE TABLE dbo.LocalizationGuidelines
(
    GuidelineID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200),
    Description NVARCHAR(MAX)
);
GO

-- 2. Use appropriate collations for language-specific sorting and comparison
CREATE TABLE dbo.LanguageSpecificData
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Text NVARCHAR(200) COLLATE Latin1_General_100_CI_AI_SC_UTF8
);
GO

-- 3. Use FORMAT function for culture-specific formatting
SELECT 
    FORMAT(GETDATE(), 'd', 'en-US') AS US_Date,
    FORMAT(GETDATE(), 'd', 'fr-FR') AS French_Date,
    FORMAT(1234.56, 'C', 'en-US') AS US_Currency,
    FORMAT(1234.56, 'C', 'fr-FR') AS French_Currency;
GO

-- 4. Store language/culture preferences with user data
CREATE TABLE dbo.UserPreferences
(
    UserID INT PRIMARY KEY,
    PreferredLanguage NVARCHAR(10) NOT NULL DEFAULT 'en-US',
    PreferredCurrency CHAR(3) NOT NULL DEFAULT 'USD',
    DateFormat NVARCHAR(20) NOT NULL DEFAULT 'MM/dd/yyyy',
    TimeFormat NVARCHAR(20) NOT NULL DEFAULT 'hh:mm tt',
    UseMetricSystem BIT NOT NULL DEFAULT 1
);
GO

-- 5. Create procedures that adapt to the user's preferred language
CREATE OR ALTER PROCEDURE dbo.GetLocalizedContent
    @UserID INT
AS
BEGIN
    DECLARE @Language NVARCHAR(10);
    
    -- Get the user's preferred language
    SELECT @Language = PreferredLanguage 
    FROM dbo.UserPreferences 
    WHERE UserID = @UserID;
    
    -- If user not found, default to English
    IF @Language IS NULL
        SET @Language = 'en-US';
    
    -- Get content in the preferred language, fall back to English if not available
    SELECT 
        c.ContentID,
        c.Title,
        c.Content,
        c.IsRightToLeft
    FROM dbo.MultilingualContent c
    WHERE c.LanguageCode = @Language
    
    UNION ALL
    
    SELECT 
        c.ContentID,
        c.Title,
        c.Content,
        c.IsRightToLeft
    FROM dbo.MultilingualContent c
    WHERE c.LanguageCode = 'en-US'
      AND c.ContentID NOT IN (
          SELECT ContentID FROM dbo.MultilingualContent WHERE LanguageCode = @Language
      );
END;
GO

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
/*
  Clean up the objects created for this tutorial.
*/

-- Drop all procedures, functions, and tables
DROP PROCEDURE IF EXISTS dbo.GetLocalizedContent;
DROP PROCEDURE IF EXISTS dbo.GetProductSpecsInUnitSystem;

DROP FUNCTION IF EXISTS dbo.GetProductDetails;
DROP FUNCTION IF EXISTS dbo.ConvertWeight;
DROP FUNCTION IF EXISTS dbo.ConvertLength;
DROP FUNCTION IF EXISTS dbo.ConvertTemperature;
DROP FUNCTION IF EXISTS dbo.ConvertCurrency;

DROP TABLE IF EXISTS dbo.UserPreferences;
DROP TABLE IF EXISTS dbo.LanguageSpecificData;
DROP TABLE IF EXISTS dbo.LocalizationGuidelines;
DROP TABLE IF EXISTS dbo.MultilingualContent;
DROP TABLE IF EXISTS dbo.SalesStatistics;
DROP TABLE IF EXISTS dbo.ProductSpecs;
DROP TABLE IF EXISTS dbo.ProductTranslations;
DROP TABLE IF EXISTS dbo.Products;
DROP TABLE IF EXISTS dbo.MultilingualSort;
DROP TABLE IF EXISTS dbo.Names_CI_AI;
DROP TABLE IF EXISTS dbo.Names_CS_AS;
DROP TABLE IF EXISTS dbo.Names_CI_AS;
DROP TABLE IF EXISTS dbo.ProductCatalog;
DROP TABLE IF EXISTS dbo.DateExamples;
GO

-- Drop the database
USE master;
GO

ALTER DATABASE LocalizationDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE LocalizationDemo;
GO