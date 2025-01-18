-------------------------------------
-- 12: Graph Data
-------------------------------------

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

-- Query to get all persons and their cities
SELECT p.Name AS PersonName, c.Name AS CityName
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO

-- Using graph functions
-- Construct an edge_id from object_id and graph_id
DECLARE @EdgeID BIGINT = EDGE_ID_FROM_PARTS(OBJECT_ID('dbo.LivesIn'), 1);
SELECT @EdgeID AS EdgeID;
GO

-- Extract the graph_id from an edge_id
DECLARE @GraphID INT = GRAPH_ID_FROM_EDGE_ID(@EdgeID);
SELECT @GraphID AS GraphID;
GO

-- Extract the graph_id from a node_id
DECLARE @NodeID BIGINT = (SELECT $node_id FROM dbo.Person WHERE PersonID = 1);
DECLARE @GraphIDFromNode INT = GRAPH_ID_FROM_NODE_ID(@NodeID);
SELECT @GraphIDFromNode AS GraphIDFromNode;
GO

-- Construct a node_id from an object_id and a graph_id
DECLARE @NewNodeID BIGINT = NODE_ID_FROM_PARTS(OBJECT_ID('dbo.Person'), 1);
SELECT @NewNodeID AS NewNodeID;
GO

-- Extract the object_id from an edge_id
DECLARE @ObjectIDFromEdge INT = OBJECT_ID_FROM_EDGE_ID(@EdgeID);
SELECT @ObjectIDFromEdge AS ObjectIDFromEdge;
GO

-- Extract the object_id from a node_id
DECLARE @ObjectIDFromNode INT = OBJECT_ID_FROM_NODE_ID(@NodeID);
SELECT @ObjectIDFromNode AS ObjectIDFromNode;
GO

-- Advanced query using JSON to represent the graph
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_QUERY((SELECT p.Name AS PersonName, c.Name AS CityName FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS PersonCityJSON
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO

-- Advanced query using SQL Server 2022 features to get graph data as JSON object
SELECT p.Name AS PersonName, c.Name AS CityName,
       JSON_OBJECT('PersonName' VALUE p.Name, 'CityName' VALUE c.Name) AS PersonCityJSON
FROM dbo.Person p
JOIN dbo.LivesIn l ON p.$node_id = l.$from_id
JOIN dbo.City c ON c.$node_id = l.$to_id;
GO