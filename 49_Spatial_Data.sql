/**************************************************************
 * SQL Server 2022 Spatial Data Tutorial
 * Description: This script demonstrates how to work with Spatial Data
 *              in SQL Server 2022. It covers:
 *              - Creating tables with geometry and geography data types
 *              - Populating spatial data using different methods
 *              - Creating and using spatial indexes
 *              - Performing spatial queries and operations
 *              - Converting between different spatial formats
 *              - Importing and exporting spatial data
 *              - Practical use cases for spatial queries
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database Setup
-------------------------------------------------
USE master;
GO

/*
  Create a database for the spatial data examples.
*/
IF DB_ID('SpatialDataDemo') IS NOT NULL
BEGIN
    ALTER DATABASE SpatialDataDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SpatialDataDemo;
END
GO

CREATE DATABASE SpatialDataDemo;
GO

USE SpatialDataDemo;
GO

-------------------------------------------------
-- Region: 2. Creating Tables with Spatial Data Types
-------------------------------------------------
/*
  Create a table using the GEOMETRY data type for 2D planar data.
  Geometry is best for local/regional coordinate systems.
*/
CREATE TABLE SpatialShapes
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ShapeName NVARCHAR(50) NOT NULL,
    GeomShape GEOMETRY NULL,
    ShapeType AS GeomShape.STGeometryType(),
    Area AS GeomShape.STArea() PERSISTED,
    CONSTRAINT CK_ShapeNotEmpty CHECK (GeomShape IS NULL OR GeomShape.STIsEmpty() = 0)
);
GO

/*
  Create a table using the GEOGRAPHY data type for earth-based spatial data.
  Geography is best for global data (using latitude/longitude).
*/
CREATE TABLE WorldLocations
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    LocationName NVARCHAR(100) NOT NULL,
    GeoLocation GEOGRAPHY NULL,
    LocationType AS GeoLocation.STGeometryType(),
    CONSTRAINT CK_LocationNotEmpty CHECK (GeoLocation IS NULL OR GeoLocation.STIsEmpty() = 0)
);
GO

/*
  Create a table for cities with point geometries
*/
CREATE TABLE Cities
(
    CityID INT IDENTITY(1,1) PRIMARY KEY,
    CityName NVARCHAR(100) NOT NULL,
    StateName NVARCHAR(50) NULL,
    CountryName NVARCHAR(50) NOT NULL,
    Population INT NULL,
    Location GEOGRAPHY NULL
);
GO

/*
  Create a table for regions (states, provinces, etc.) with polygon geometries
*/
CREATE TABLE Regions
(
    RegionID INT IDENTITY(1,1) PRIMARY KEY,
    RegionName NVARCHAR(100) NOT NULL,
    CountryName NVARCHAR(50) NOT NULL,
    Population INT NULL,
    Boundary GEOGRAPHY NULL,
    Area AS Boundary.STArea() PERSISTED
);
GO

/*
  Create a table for routes/roads with linestring geometries
*/
CREATE TABLE Routes
(
    RouteID INT IDENTITY(1,1) PRIMARY KEY,
    RouteName NVARCHAR(100) NOT NULL,
    RouteType NVARCHAR(50) NULL,
    Path GEOGRAPHY NULL,
    Length AS Path.STLength() PERSISTED
);
GO

-------------------------------------------------
-- Region: 3. Populating Tables with Spatial Data
-------------------------------------------------
/*
  Insert geometric shapes using Well-Known Text (WKT) format.
*/
INSERT INTO SpatialShapes (ShapeName, GeomShape)
VALUES 
    -- Point at coordinate (3, 4)
    ('Simple Point', geometry::STGeomFromText('POINT (3 4)', 0)),
    
    -- LineString with 3 points
    ('Simple Line', geometry::STGeomFromText('LINESTRING (0 0, 5 5, 10 0)', 0)),
    
    -- Polygon with exterior ring (square)
    ('Square', geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))', 0)),
    
    -- Circle approximated by a 36-point polygon
    ('Circle', geometry::STGeomFromText('POLYGON ((10 0, 9.781 1.951, 9.135 3.827, 8.09 5.556, 6.691 7.071, 5 8.315, 3.09 9.239, 1.045 9.781, -1.045 9.781, -3.09 9.239, -5 8.315, -6.691 7.071, -8.09 5.556, -9.135 3.827, -9.781 1.951, -10 0, -9.781 -1.951, -9.135 -3.827, -8.09 -5.556, -6.691 -7.071, -5 -8.315, -3.09 -9.239, -1.045 -9.781, 1.045 -9.781, 3.09 -9.239, 5 -8.315, 6.691 -7.071, 8.09 -5.556, 9.135 -3.827, 9.781 -1.951, 10 0))', 0)),
    
    -- Polygon with a hole in it (donut)
    ('Donut', geometry::STGeomFromText('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 8 2, 8 8, 2 8, 2 2))', 0)),
    
    -- MultiPoint with 3 points
    ('Multiple Points', geometry::STGeomFromText('MULTIPOINT ((0 0), (5 5), (10 10))', 0)),
    
    -- MultiLineString with 2 linestrings
    ('Multiple Lines', geometry::STGeomFromText('MULTILINESTRING ((0 0, 5 5), (10 10, 15 15))', 0)),
    
    -- MultiPolygon with 2 rectangles
    ('Multiple Polygons', geometry::STGeomFromText('MULTIPOLYGON (((0 0, 5 0, 5 5, 0 5, 0 0)), ((10 10, 15 10, 15 15, 10 15, 10 10)))', 0));
GO

/*
  Insert world locations using geography type and various formats.
*/
INSERT INTO WorldLocations (LocationName, GeoLocation)
VALUES
    -- New York City (POINT)
    ('New York', geography::STGeomFromText('POINT (-74.0060 40.7128)', 4326)),
    
    -- London (using the Point() constructor)
    ('London', geography::Point(51.5074, -0.1278, 4326)),
    
    -- Sydney using ParseText (another way to create from WKT)
    ('Sydney', geography::Parse('POINT(151.2093 -33.8688)')),
    
    -- Mount Everest using STPointFromText (specific point constructor)
    ('Mount Everest', geography::STPointFromText('POINT(86.9250 27.9881)', 4326)),
    
    -- US-Canada border section (LINESTRING)
    ('US-Canada Border Section', geography::STGeomFromText('LINESTRING(-122.7333 49.0000, -95.1533 49.0000, -95.1533 49.3900, -94.4500 49.0000)', 4326)),
    
    -- Amazon River (simplified path)
    ('Amazon River', geography::STGeomFromText('LINESTRING(-70.5625 -4.2158, -69.9609 -4.5656, -67.8516 -4.5656, -66.0938 -3.5134, -62.5781 -3.5134, -61.5234 -2.4609, -59.0625 -2.4609, -54.8438 -2.4609, -52.6758 -1.0107, -50.2734 -0.1758)', 4326)),
    
    -- Italy (simplified polygon)
    ('Italy', geography::STGeomFromText('POLYGON((12.4500 41.9000, 15.3000 41.0000, 16.6000 38.0000, 15.9000 37.0000, 13.8000 37.6000, 12.4000 38.0000, 9.0000 44.0000, 12.4500 41.9000))', 4326)),
    
    -- Great Barrier Reef (simplified polygon)
    ('Great Barrier Reef', geography::STGeomFromText('POLYGON((145.0000 -16.0000, 146.0000 -16.0000, 146.0000 -18.0000, 145.0000 -18.0000, 145.0000 -16.0000))', 4326));
GO

/*
  Insert major cities with their coordinates
*/
INSERT INTO Cities (CityName, StateName, CountryName, Population, Location)
VALUES
    ('New York', 'New York', 'United States', 8804190, geography::Point(40.7128, -74.0060, 4326)),
    ('Los Angeles', 'California', 'United States', 3898747, geography::Point(34.0522, -118.2437, 4326)),
    ('Chicago', 'Illinois', 'United States', 2746388, geography::Point(41.8781, -87.6298, 4326)),
    ('Toronto', 'Ontario', 'Canada', 2731571, geography::Point(43.6532, -79.3832, 4326)),
    ('Mexico City', NULL, 'Mexico', 9209944, geography::Point(19.4326, -99.1332, 4326)),
    ('London', NULL, 'United Kingdom', 8982000, geography::Point(51.5074, -0.1278, 4326)),
    ('Paris', NULL, 'France', 2140526, geography::Point(48.8566, 2.3522, 4326)),
    ('Tokyo', NULL, 'Japan', 13960000, geography::Point(35.6762, 139.6503, 4326)),
    ('Sydney', 'New South Wales', 'Australia', 5312163, geography::Point(-33.8688, 151.2093, 4326)),
    ('Rio de Janeiro', NULL, 'Brazil', 6747815, geography::Point(-22.9068, -43.1729, 4326));
GO

/*
  Insert some sample routes (simplified)
*/
INSERT INTO Routes (RouteName, RouteType, Path)
VALUES
    ('Route 66', 'Highway', geography::STGeomFromText('LINESTRING(-118.2437 34.0522, -112.0740 33.4484, -106.6504 35.0844, -97.5171 35.4676, -94.5786 39.0997, -89.6501 39.8027, -90.1994 38.6270, -87.6298 41.8781)', 4326)),
    ('I-95 Section', 'Interstate', geography::STGeomFromText('LINESTRING(-74.0060 40.7128, -75.1652 39.9526, -76.6122 39.2904, -77.0369 38.9072, -78.6569 35.7796)', 4326)),
    ('Pacific Coast Highway', 'Scenic Route', geography::STGeomFromText('LINESTRING(-122.4324 37.7749, -122.1761 36.5729, -119.6982 34.4208, -118.2437 34.0522)', 4326));
GO

/*
  Insert sample regions (simplified boundaries)
*/
INSERT INTO Regions (RegionName, CountryName, Population, Boundary)
VALUES
    ('California', 'United States', 39538223, geography::STGeomFromText('POLYGON((-124.4097 42.0095, -120.0000 42.0095, -120.0000 39.0000, -114.6300 35.0000, -114.6300 32.5343, -117.1611 32.5343, -124.4097 38.0000, -124.4097 42.0095))', 4326)),
    
    ('Texas', 'United States', 29145505, geography::STGeomFromText('POLYGON((-106.6460 31.7674, -106.5048 31.7674, -103.0700 31.9000, -103.0430 36.5000, -100.0000 36.5000, -94.4300 33.6363, -94.0000 29.3838, -95.2000 28.0000, -96.5000 26.0000, -97.1400 25.8371, -99.2000 26.4300, -101.4000 29.7700, -104.5300 29.7700, -106.6460 31.7674))', 4326));
GO

-------------------------------------------------
-- Region: 4. Creating Spatial Indexes
-------------------------------------------------
/*
  Create spatial indexes to improve query performance.
  These are especially important for operations like STIntersects, STContains, etc.
*/

-- Create a spatial index on the City locations
CREATE SPATIAL INDEX SPIDX_Cities_Location
ON Cities(Location)
USING GEOGRAPHY_AUTO_GRID
WITH (
    CELLS_PER_OBJECT = 16,
    PAD_INDEX = ON,
    FILLFACTOR = 80
);
GO

-- Create a spatial index on Region boundaries
CREATE SPATIAL INDEX SPIDX_Regions_Boundary
ON Regions(Boundary)
USING GEOGRAPHY_AUTO_GRID
WITH (
    CELLS_PER_OBJECT = 64,  -- More cells for complex polygons
    PAD_INDEX = ON,
    FILLFACTOR = 75
);
GO

-- Create a spatial index on Routes
CREATE SPATIAL INDEX SPIDX_Routes_Path
ON Routes(Path)
USING GEOGRAPHY_AUTO_GRID
WITH (
    CELLS_PER_OBJECT = 32,  -- Appropriate for linestrings
    PAD_INDEX = ON
);
GO

-- Create a spatial index on geometric shapes
CREATE SPATIAL INDEX SPIDX_Shapes_Geometry
ON SpatialShapes(GeomShape)
USING GEOMETRY_AUTO_GRID
WITH (
    CELLS_PER_OBJECT = 16,
    PAD_INDEX = ON
);
GO

-------------------------------------------------
-- Region: 5. Basic Spatial Operations and Queries
-------------------------------------------------
/*
  Basic spatial properties and operations for geometry.
*/
SELECT 
    ShapeName,
    ShapeType,
    GeomShape.STDimension() AS Dimension,
    ROUND(Area, 2) AS Area,
    ROUND(GeomShape.STLength(), 2) AS Perimeter,
    GeomShape.STNumPoints() AS NumPoints,
    GeomShape.STNumGeometries() AS NumGeometries,
    GeomShape.STIsValid() AS IsValid
FROM 
    SpatialShapes;
GO

/*
  Basic spatial properties for geography objects.
*/
SELECT 
    LocationName,
    LocationType,
    ROUND(GeoLocation.STArea() / 1000000, 2) AS AreaInSquareKm,
    ROUND(GeoLocation.STLength() / 1000, 2) AS LengthInKm,
    GeoLocation.Lat AS Latitude,
    GeoLocation.Long AS Longitude,
    GeoLocation.STNumPoints() AS NumPoints
FROM 
    WorldLocations
ORDER BY 
    LocationType;
GO

/*
  Find distances between major cities.
*/
SELECT 
    c1.CityName AS FromCity,
    c2.CityName AS ToCity,
    c1.CountryName AS FromCountry,
    c2.CountryName AS ToCountry,
    ROUND(c1.Location.STDistance(c2.Location) / 1000, 2) AS DistanceInKm
FROM 
    Cities c1
CROSS JOIN 
    Cities c2
WHERE 
    c1.CityID < c2.CityID  -- Avoid duplicate pairs and self-comparisons
ORDER BY 
    DistanceInKm;
GO

/*
  Find all cities within a particular region.
*/
SELECT 
    c.CityName,
    r.RegionName,
    c.Population,
    ROUND(c.Location.STDistance(r.Boundary) / 1000, 2) AS DistanceToRegionBoundaryInKm
FROM 
    Cities c
JOIN 
    Regions r ON r.Boundary.STContains(c.Location) = 1
ORDER BY 
    r.RegionName, c.CityName;
GO

-------------------------------------------------
-- Region: 6. Advanced Spatial Operations
-------------------------------------------------
/*
  Buffer operations - find cities within 500km of Tokyo.
*/
DECLARE @TokyoLocation GEOGRAPHY = (SELECT Location FROM Cities WHERE CityName = 'Tokyo');
DECLARE @BufferDistance FLOAT = 500 * 1000; -- 500km in meters

SELECT 
    c.CityName,
    c.CountryName,
    ROUND(@TokyoLocation.STDistance(c.Location) / 1000, 2) AS DistanceInKm
FROM 
    Cities c
WHERE 
    @TokyoLocation.STBuffer(@BufferDistance).STContains(c.Location) = 1
    AND c.CityName <> 'Tokyo'
ORDER BY 
    DistanceInKm;
GO

/*
  Find intersections between routes.
*/
SELECT 
    r1.RouteName AS Route1,
    r2.RouteName AS Route2,
    r1.Path.STIntersection(r2.Path).ToString() AS IntersectionPoint,
    r1.Path.STIntersects(r2.Path) AS DoIntersect
FROM 
    Routes r1
CROSS JOIN 
    Routes r2
WHERE 
    r1.RouteID < r2.RouteID  -- Avoid duplicates
    AND r1.Path.STIntersects(r2.Path) = 1;
GO

/*
  Calculate the union of two regions to represent their combined area.
*/
SELECT 
    r1.RegionName AS Region1,
    r2.RegionName AS Region2,
    ROUND(r1.Boundary.STArea() / 1000000, 2) AS Area1InSquareKm,
    ROUND(r2.Boundary.STArea() / 1000000, 2) AS Area2InSquareKm,
    ROUND(r1.Boundary.STUnion(r2.Boundary).STArea() / 1000000, 2) AS CombinedAreaInSquareKm
FROM 
    Regions r1
CROSS JOIN 
    Regions r2
WHERE 
    r1.RegionID < r2.RegionID;  -- Avoid duplicates
GO

/*
  Calculate the shortest distance between a city and a route.
*/
SELECT 
    c.CityName,
    r.RouteName,
    ROUND(c.Location.STDistance(r.Path) / 1000, 2) AS ShortestDistanceInKm
FROM 
    Cities c
CROSS JOIN 
    Routes r
ORDER BY 
    c.CityName, ShortestDistanceInKm;
GO

-------------------------------------------------
-- Region: 7. Format Conversions
-------------------------------------------------
/*
  Convert between different spatial formats.
*/
SELECT TOP 5
    ID,
    LocationName,
    GeoLocation.ToString() AS WKT,
    GeoLocation.STAsText() AS WKT_Alternative,
    CAST(GeoLocation AS VARBINARY(MAX)) AS WKB,
    GeoLocation.Lat AS Latitude,
    GeoLocation.Long AS Longitude,
    'POINT(' + CAST(GeoLocation.Long AS VARCHAR(20)) + ' ' + 
    CAST(GeoLocation.Lat AS VARCHAR(20)) + ')' AS ConstructedWKT
FROM 
    WorldLocations;
GO

/*
  Convert to GeoJSON format (SQL Server 2016 and later).
*/
SELECT TOP 5
    ID,
    LocationName,
    GeoLocation.AsGeoJSON() AS GeoJSON
FROM 
    WorldLocations;
GO

/*
  Convert coordinates between different spatial reference systems.
  4326 = WGS 84 (standard GPS/lat-long)
  3857 = Web Mercator (used by many web mapping services)
*/
SELECT TOP 5
    CityName,
    Location.Lat AS WGS84_Latitude,
    Location.Long AS WGS84_Longitude,
    Location.STSrid AS OriginalSRID,
    Location.STTransform(3857).STY AS WebMercator_Y,
    Location.STTransform(3857).STX AS WebMercator_X,
    Location.STTransform(3857).STSrid AS NewSRID
FROM 
    Cities;
GO

-------------------------------------------------
-- Region: 8. Importing and Exporting Spatial Data
-------------------------------------------------
/*
  Prepare a table for importing spatial data from a CSV file.
  Assume CSV contains: ID,Name,Latitude,Longitude,Type
*/
CREATE TABLE ImportedLocations
(
    ID INT PRIMARY KEY,
    LocationName NVARCHAR(100),
    Latitude FLOAT,
    Longitude FLOAT,
    LocationType NVARCHAR(50),
    GeoLocation AS geography::Point(Latitude, Longitude, 4326) PERSISTED
);
GO

/*
  Insert sample data (simulating a CSV import).
*/
INSERT INTO ImportedLocations (ID, LocationName, Latitude, Longitude, LocationType)
VALUES
    (1, 'Eiffel Tower', 48.8584, 2.2945, 'Landmark'),
    (2, 'Statue of Liberty', 40.6892, -74.0445, 'Landmark'),
    (3, 'Sydney Opera House', -33.8568, 151.2153, 'Theater'),
    (4, 'Mount Fuji', 35.3606, 138.7274, 'Mountain'),
    (5, 'Taj Mahal', 27.1751, 78.0421, 'Monument');
GO

/*
  Example of importing a geometry from a GeoJSON string.
  Creating a function that converts GeoJSON to geometry.
*/
CREATE OR ALTER FUNCTION dbo.GeoJSONToGeography(@geoJSON NVARCHAR(MAX))
RETURNS GEOGRAPHY
AS
BEGIN
    DECLARE @result GEOGRAPHY;
    
    -- This is a simplified approach - production code would need more validation and parsing
    DECLARE @wkt NVARCHAR(MAX);
    
    -- For POINT type only in this example
    IF @geoJSON LIKE '%"type":"Point"%'
    BEGIN
        DECLARE @longitude FLOAT;
        DECLARE @latitude FLOAT;
        
        -- Extract coordinates (very simplified)
        DECLARE @coordsStart INT = CHARINDEX('"coordinates":[', @geoJSON) + 14;
        DECLARE @coordsEnd INT = CHARINDEX(']', @geoJSON, @coordsStart);
        DECLARE @coords NVARCHAR(100) = SUBSTRING(@geoJSON, @coordsStart, @coordsEnd - @coordsStart);
        
        -- Split coordinates
        DECLARE @commaPos INT = CHARINDEX(',', @coords);
        SET @longitude = CAST(SUBSTRING(@coords, 1, @commaPos - 1) AS FLOAT);
        SET @latitude = CAST(SUBSTRING(@coords, @commaPos + 1, 100) AS FLOAT);
        
        -- Create the geography point
        SET @result = geography::Point(@latitude, @longitude, 4326);
    END
    
    RETURN @result;
END;
GO

/*
  Using the GeoJSON conversion function.
*/
DECLARE @pointGeoJSON NVARCHAR(MAX) = N'{"type":"Point","coordinates":[135.7681,35.0116]}';
SELECT 
    @pointGeoJSON AS GeoJSON,
    dbo.GeoJSONToGeography(@pointGeoJSON) AS GeographyObject,
    dbo.GeoJSONToGeography(@pointGeoJSON).ToString() AS WKT,
    dbo.GeoJSONToGeography(@pointGeoJSON).Lat AS Latitude,
    dbo.GeoJSONToGeography(@pointGeoJSON).Long AS Longitude;
GO

/*
  Exporting spatial data as KML (for Google Earth)
*/
SELECT
    'placemark_' + CAST(CityID AS VARCHAR(10)) AS ID,
    CityName,
    '<Placemark><name>' + CityName + '</name><Point><coordinates>' + 
    CAST(Location.Long AS VARCHAR(20)) + ',' + 
    CAST(Location.Lat AS VARCHAR(20)) + ',0</coordinates></Point></Placemark>' AS KML
FROM
    Cities
ORDER BY CityName;
GO

-------------------------------------------------
-- Region: 9. Real-World Use Cases
-------------------------------------------------
/*
  Use Case 1: Geofencing - Find all cities within California.
*/
DECLARE @CaliforniaBoundary GEOGRAPHY = (SELECT Boundary FROM Regions WHERE RegionName = 'California');

SELECT
    c.CityName,
    c.StateName,
    c.Population,
    'Inside California' AS Status
FROM
    Cities c
WHERE
    @CaliforniaBoundary.STContains(c.Location) = 1
UNION
SELECT
    c.CityName,
    c.StateName,
    c.Population,
    CAST(ROUND(@CaliforniaBoundary.STDistance(c.Location) / 1000, 0) AS VARCHAR(10)) + ' km from California border' AS Status
FROM
    Cities c
WHERE
    @CaliforniaBoundary.STContains(c.Location) = 0
    AND @CaliforniaBoundary.STDistance(c.Location) <= 500000  -- 500 km buffer
ORDER BY
    Status;
GO

/*
  Use Case 2: Nearest neighbor search - Find the 3 closest cities to a given point.
*/
DECLARE @CurrentLocation GEOGRAPHY = geography::Point(34.0522, -118.2437, 4326);  -- Los Angeles coordinates

SELECT TOP 3
    c.CityName,
    c.CountryName,
    ROUND(@CurrentLocation.STDistance(c.Location) / 1000, 2) AS DistanceInKm
FROM
    Cities c
WHERE
    c.Location.STEquals(@CurrentLocation) = 0  -- Exclude exact match (current location)
ORDER BY
    @CurrentLocation.STDistance(c.Location);
GO

/*
  Use Case 3: Find cities along a route with a buffer of 100 km.
*/
DECLARE @Route GEOGRAPHY = (SELECT Path FROM Routes WHERE RouteName = 'Route 66');
DECLARE @BufferDistance FLOAT = 100000;  -- 100 km in meters

SELECT
    c.CityName,
    c.StateName,
    c.CountryName,
    ROUND(@Route.STDistance(c.Location) / 1000, 2) AS DistanceFromRouteInKm
FROM
    Cities c
WHERE
    @Route.STBuffer(@BufferDistance).STIntersects(c.Location) = 1
ORDER BY
    DistanceFromRouteInKm;
GO

/*
  Use Case 4: Creating a convex hull around a group of points.
*/
DECLARE @USCities GEOGRAPHY;
SET @USCities = (
    SELECT geography::UnionAggregate(Location)
    FROM Cities
    WHERE CountryName = 'United States'
);

SELECT
    'US Cities Area' AS Description,
    @USCities.STConvexHull() AS ConvexHull,
    ROUND(@USCities.STConvexHull().STArea() / 1000000, 2) AS AreaInSquareKm;
GO

/*
  Use Case 5: Generate a grid of points within a boundary for analysis.
*/
DECLARE @RegionBoundary GEOGRAPHY = (SELECT Boundary FROM Regions WHERE RegionName = 'Texas');
DECLARE @BoundingBox GEOMETRY = @RegionBoundary.STEnvelope().MakeValid().STAsText();

-- Create a numbers table for the grid
WITH Numbers AS (
    SELECT TOP 100 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.objects
)
SELECT
    'Grid Point ' + CAST((n1.n * 10 + n2.n) AS VARCHAR(10)) AS PointName,
    geography::Point(
        (SELECT @RegionBoundary.STEnvelope().STPointN(1).Lat) + 
        (n1.n * ((@RegionBoundary.STEnvelope().STPointN(3).Lat - @RegionBoundary.STEnvelope().STPointN(1).Lat) / 9)),
        (SELECT @RegionBoundary.STEnvelope().STPointN(1).Long) + 
        (n2.n * ((@RegionBoundary.STEnvelope().STPointN(3).Long - @RegionBoundary.STEnvelope().STPointN(1).Long) / 9)),
        4326
    ) AS GridPoint
FROM
    Numbers n1
CROSS JOIN
    Numbers n2
WHERE
    n1.n < 10 AND n2.n < 10
    AND geography::Point(
        (SELECT @RegionBoundary.STEnvelope().STPointN(1).Lat) + 
        (n1.n * ((@RegionBoundary.STEnvelope().STPointN(3).Lat - @RegionBoundary.STEnvelope().STPointN(1).Lat) / 9)),
        (SELECT @RegionBoundary.STEnvelope().STPointN(1).Long) + 
        (n2.n * ((@RegionBoundary.STEnvelope().STPointN(3).Long - @RegionBoundary.STEnvelope().STPointN(1).Long) / 9)),
        4326
    ).STIntersects(@RegionBoundary) = 1;
GO

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
/*
  Drop all created objects.
*/
-- Uncomment to clean up
/*
USE master;
GO

IF DB_ID('SpatialDataDemo') IS NOT NULL
BEGIN
    ALTER DATABASE SpatialDataDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SpatialDataDemo;
END
GO
*/