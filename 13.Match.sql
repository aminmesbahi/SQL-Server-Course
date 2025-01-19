-------------------------------------
-- 13: MATCH
-------------------------------------
/*
The `MATCH` clause in SQL Server 2022 is used to perform pattern matching on graph data. It allows to query node and edge tables to find specific patterns and relationships within the graph. This clause is particularly useful for traversing and analyzing complex networks, such as social networks, organizational hierarchies, and transportation systems.

The `MATCH` clause supports various functionalities, including:
- Basic pattern matching to find relationships between nodes.
- Filtering patterns based on specific conditions.
- Recursive pattern matching to explore hierarchical structures.
- Integration with JSON functions to represent graph data in JSON format.

By leveraging the `MATCH` clause, can efficiently query and analyze graph data, making it a powerful tool for working with graph databases in SQL Server 2022.
*/
USE TestDB;
GO

-- Create node tables
CREATE TABLE dbo.Person (
    PersonID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;
GO

CREATE TABLE dbo.City (
    CityID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;
GO

-- Create edge table
CREATE TABLE dbo.LivesIn (
    EdgeID BIGINT PRIMARY KEY,
    FromNode NODE,
    ToNode NODE
) AS EDGE;
GO

-- Insert sample nodes
INSERT INTO dbo.Person (PersonID, Name)
VALUES
    (1, 'Alice'),
    (2, 'Bob'),
    (3, 'Charlie');
GO

INSERT INTO dbo.City (CityID, Name)
VALUES
    (1, 'New York'),
    (2, 'Los Angeles'),
    (3, 'Chicago');
GO

-- Insert sample edges
INSERT INTO dbo.LivesIn (FromNode, ToNode)
VALUES
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 1), (SELECT $node_id FROM dbo.City WHERE CityID = 1)),
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 2), (SELECT $node_id FROM dbo.City WHERE CityID = 2)),
    ((SELECT $node_id FROM dbo.Person WHERE PersonID = 3), (SELECT $node_id FROM dbo.City WHERE CityID = 3));
GO

-- Basic MATCH query to find all persons and their cities
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO

-- MATCH query with a pattern
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
AND c.Name = 'New York';
GO

-- MATCH query with multiple patterns
SELECT p.Name AS PersonName, c1.Name AS CityName1, c2.Name AS CityName2
FROM dbo.Person p, dbo.City c1, dbo.City c2, dbo.LivesIn l1, dbo.LivesIn l2
WHERE MATCH(p-(l1)->c1, p-(l2)->c2);
GO

-- MATCH query with a variable pattern
DECLARE @CityName NVARCHAR(100) = 'Los Angeles';
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
AND c.Name = @CityName;
GO

-- MATCH query with a path pattern
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c)
AND l.$path = 'LivesIn';
GO

-- MATCH query with a recursive pattern
WITH RECURSIVE PersonCityPath AS (
    SELECT p.Name AS PersonName, c.Name AS CityName, 1 AS Level
    FROM dbo.Person p, dbo.City c, dbo.LivesIn l
    WHERE MATCH(p-(l)->c)
    UNION ALL
    SELECT p.Name AS PersonName, c.Name AS CityName, Level + 1
    FROM PersonCityPath pcp, dbo.Person p, dbo.City c, dbo.LivesIn l
    WHERE MATCH(p-(l)->c)
)
SELECT * FROM PersonCityPath;
GO

-- MATCH query with JSON output
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_QUERY((SELECT p.Name AS PersonName, c.Name AS CityName FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS PersonCityJSON
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO

-- MATCH query with SQL Server 2022 JSON_OBJECT function
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_OBJECT('PersonName' VALUE p.Name, 'CityName' VALUE c.Name) AS PersonCityJSON
FROM dbo.Person p, dbo.City c, dbo.LivesIn l
WHERE MATCH(p-(l)->c);
GO