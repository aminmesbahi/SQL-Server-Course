/**************************************************************
 * SQL Server 2022 MATCH Clause Tutorial for Graph Data
 * Description: This script demonstrates the use of the MATCH clause 
 *              in SQL Server 2022 to perform pattern matching on graph 
 *              data. It covers basic and advanced queries including:
 *              - Basic pattern matching for relationships between nodes.
 *              - Filtering and variable pattern matching.
 *              - Multiple and recursive pattern matching.
 *              - Integration with JSON functions for output formatting.
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
-- Region: 1. Creating Graph Node and Edge Tables
-------------------------------------------------
/*
  1.1 Create node table for Person.
*/
IF OBJECT_ID(N'dbo.Person', N'U') IS NOT NULL
    DROP TABLE dbo.Person;
GO

CREATE TABLE dbo.Person (
    PersonID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;
GO

/*
  1.2 Create node table for City.
*/
IF OBJECT_ID(N'dbo.City', N'U') IS NOT NULL
    DROP TABLE dbo.City;
GO

CREATE TABLE dbo.City (
    CityID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;
GO

/*
  1.3 Create edge table for LivesIn.
*/
IF OBJECT_ID(N'dbo.LivesIn', N'U') IS NOT NULL
    DROP TABLE dbo.LivesIn;
GO

CREATE TABLE dbo.LivesIn (
    EdgeID BIGINT PRIMARY KEY,  -- Optional: Use IDENTITY if desired.
    FromNode NODE,
    ToNode NODE
) AS EDGE;
GO

-------------------------------------------------
-- Region: 2. Inserting Sample Graph Data
-------------------------------------------------
/*
  2.1 Insert sample nodes into Person.
*/
INSERT INTO dbo.Person (PersonID, Name)
VALUES
    (1, 'Alice'),
    (2, 'Bob'),
    (3, 'Charlie');
GO

/*
  2.2 Insert sample nodes into City.
*/
INSERT INTO dbo.City (CityID, Name)
VALUES
    (1, 'New York'),
    (2, 'Los Angeles'),
    (3, 'Chicago');
GO

/*
  2.3 Insert sample edges into LivesIn using $node_id.
*/
INSERT INTO dbo.LivesIn (FromNode, ToNode)
VALUES
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 1),
     (SELECT $node_id FROM dbo.City WHERE CityID = 1)),
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 2),
     (SELECT $node_id FROM dbo.City WHERE CityID = 2)),
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 3),
     (SELECT $node_id FROM dbo.City WHERE CityID = 3));
GO

-------------------------------------------------
-- Region: 3. Basic MATCH Queries
-------------------------------------------------
/*
  3.1 Basic MATCH query to retrieve all persons and their cities.
*/
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO

/*
  3.2 MATCH query with a filter condition on City Name.
*/
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
  AND c.Name = 'New York';
GO

-------------------------------------------------
-- Region: 4. Advanced MATCH Queries
-------------------------------------------------
/*
  4.1 MATCH query with multiple patterns to retrieve multiple relationships.
     This example shows two relationships from the same person to different cities.
*/
SELECT p.Name AS PersonName, c1.Name AS CityName1, c2.Name AS CityName2
FROM dbo.Person p, dbo.City c1, dbo.City c2, dbo.LivesIn l1, dbo.LivesIn l2
WHERE MATCH(p-(l1)->c1, p-(l2)->c2);
GO

/*
  4.2 MATCH query using a variable for filtering.
*/
DECLARE @CityName NVARCHAR(100) = 'Los Angeles';
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
  AND c.Name = @CityName;
GO

/*
  4.3 MATCH query with a path pattern.
  Note: l.$path returns the name of the edge type.
*/
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
  AND l.$path = 'LivesIn';
GO

-------------------------------------------------
-- Region: 5. Recursive MATCH Query
-------------------------------------------------
/*
  5.1 Recursive MATCH query to traverse relationships.
  This example uses a CTE to recursively retrieve person-city relationships.
*/
WITH RECURSIVE PersonCityPath AS (
    -- Base case: initial person-city connection
    SELECT p.Name AS PersonName, c.Name AS CityName, 1 AS Level
    FROM dbo.Person p, dbo.City c, dbo.LivesIn l
    WHERE MATCH(p-(l)->c)
    UNION ALL
    -- Recursive case: additional matching (customize as needed)
    SELECT p.Name AS PersonName, c.Name AS CityName, Level + 1
    FROM PersonCityPath pcp, dbo.Person p, dbo.City c, dbo.LivesIn l
    WHERE MATCH(p-(l)->c)
)
SELECT * FROM PersonCityPath;
GO

-------------------------------------------------
-- Region: 6. MATCH Queries with JSON Output
-------------------------------------------------
/*
  6.1 MATCH query with JSON output using JSON_QUERY.
*/
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_QUERY(
           (SELECT p.Name AS PersonName, c.Name AS CityName 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
       ) AS PersonCityJSON
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO

/*
  6.2 MATCH query with SQL Server 2022 JSON_OBJECT function.
*/
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_OBJECT('PersonName' VALUE p.Name, 'CityName' VALUE c.Name) AS PersonCityJSON
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
