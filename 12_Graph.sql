/**************************************************************
 * SQL Server 2022 Graph Data Tutorial
 * Description: This script demonstrates working with graph data 
 *              in SQL Server using node and edge tables. It covers 
 *              creating node and edge tables, inserting sample data, 
 *              querying the graph, and using advanced graph functions 
 *              and JSON representations.
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
-- Region: 1. Creating Node and Edge Tables
-------------------------------------------------
/*
  1.1 Create node table for Person. Drops table if it exists.
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
  1.2 Create node table for City. Drops table if it exists.
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
  1.3 Create edge table for LivesIn. Drops table if it exists.
*/
IF OBJECT_ID(N'dbo.LivesIn', N'U') IS NOT NULL
    DROP TABLE dbo.LivesIn;
GO

CREATE TABLE dbo.LivesIn (
    EdgeID BIGINT PRIMARY KEY,  -- Can also be identity if needed
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
  2.3 Insert sample edges into LivesIn.
  Note: $node_id is used to reference the internal node identifier.
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
-- Region: 3. Basic Graph Queries
-------------------------------------------------
/*
  3.1 Retrieve all persons and their associated cities.
*/
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO

-------------------------------------------------
-- Region: 4. Using Graph Functions
-------------------------------------------------
/*
  4.1 Construct an edge_id from object_id and graph_id.
*/
DECLARE @EdgeID BIGINT = EDGE_ID_FROM_PARTS(OBJECT_ID('dbo.LivesIn'), 1);
SELECT @EdgeID AS EdgeID;
GO

/*
  4.2 Extract the graph_id from an edge_id.
*/
DECLARE @GraphID INT = GRAPH_ID_FROM_EDGE_ID(@EdgeID);
SELECT @GraphID AS GraphID;
GO

/*
  4.3 Extract the graph_id from a node_id.
*/
DECLARE @NodeID BIGINT = (SELECT $node_id FROM dbo.Person WHERE PersonID = 1);
DECLARE @GraphIDFromNode INT = GRAPH_ID_FROM_NODE_ID(@NodeID);
SELECT @GraphIDFromNode AS GraphIDFromNode;
GO

/*
  4.4 Construct a node_id from an object_id and a graph_id.
*/
DECLARE @NewNodeID BIGINT = NODE_ID_FROM_PARTS(OBJECT_ID('dbo.Person'), 1);
SELECT @NewNodeID AS NewNodeID;
GO

/*
  4.5 Extract the object_id from an edge_id.
*/
DECLARE @ObjectIDFromEdge INT = OBJECT_ID_FROM_EDGE_ID(@EdgeID);
SELECT @ObjectIDFromEdge AS ObjectIDFromEdge;
GO

/*
  4.6 Extract the object_id from a node_id.
*/
DECLARE @ObjectIDFromNode INT = OBJECT_ID_FROM_NODE_ID(@NodeID);
SELECT @ObjectIDFromNode AS ObjectIDFromNode;
GO

-------------------------------------------------
-- Region: 5. Advanced Graph Queries with JSON
-------------------------------------------------
/*
  5.1 Advanced query: Return person and city names along with a JSON 
      representation of the relationship using JSON_QUERY.
*/
SELECT 
    p.Name AS PersonName, 
    c.Name AS CityName,
    JSON_QUERY(
        (SELECT p.Name AS PersonName, c.Name AS CityName 
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    ) AS PersonCityJSON
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO

/*
  5.2 Advanced query using SQL Server 2022 JSON_OBJECT feature to output 
      graph data as a JSON object.
*/
SELECT 
    p.Name AS PersonName, 
    c.Name AS CityName,
    JSON_OBJECT('PersonName' VALUE p.Name, 'CityName' VALUE c.Name) AS PersonCityJSON
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------
