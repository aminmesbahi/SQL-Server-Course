/**************************************************************
 * SQL Server 2022 Graph Database Example Tutorial
 * Description: This script demonstrates a basic graph database 
 *              implementation using SQL Server 2022 graph features.
 *              It covers:
 *              - Creating a database for the graph example.
 *              - Creating node tables (Person, City) and an edge table (LivesIn).
 *              - Inserting data into node and edge tables.
 *              - Querying the graph using the MATCH clause.
 *              - Updating and deleting nodes and edges.
 *              - Cleaning up by dropping tables and the database.
 **************************************************************/

-------------------------------------------------
-- Region: 1. Database and Table Setup
-------------------------------------------------
/*
  1.1 Create a database for the graph example.
*/
CREATE DATABASE GraphDB;
GO

USE GraphDB;
GO

/*
  1.2 Create node tables for Person and City using the AS NODE clause.
*/
CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT
) AS NODE;
GO

CREATE TABLE City (
    CityID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;
GO

/*
  1.3 Create an edge table (LivesIn) with foreign key constraints.
  Note: Although the edge table is defined using AS EDGE, foreign keys
  are added here for clarity and referential integrity.
*/
CREATE TABLE LivesIn (
    PersonID INT,
    CityID INT,
    CONSTRAINT FK_Person FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    CONSTRAINT FK_City FOREIGN KEY (CityID) REFERENCES City(CityID)
) AS EDGE;
GO

-------------------------------------------------
-- Region: 2. Inserting Data into Node and Edge Tables
-------------------------------------------------
/*
  2.1 Insert data into the Person node table.
*/
INSERT INTO Person (PersonID, Name, Age) VALUES (1, 'Alice', 30);
INSERT INTO Person (PersonID, Name, Age) VALUES (2, 'Bob', 25);
INSERT INTO Person (PersonID, Name, Age) VALUES (3, 'Charlie', 35);
GO

/*
  2.2 Insert data into the City node table.
*/
INSERT INTO City (CityID, Name) VALUES (1, 'New York');
INSERT INTO City (CityID, Name) VALUES (2, 'Los Angeles');
INSERT INTO City (CityID, Name) VALUES (3, 'Chicago');
GO

/*
  2.3 Insert data into the LivesIn edge table.
  This defines relationships between Person and City nodes.
*/
INSERT INTO LivesIn (PersonID, CityID) VALUES (1, 1); -- Alice lives in New York
INSERT INTO LivesIn (PersonID, CityID) VALUES (2, 2); -- Bob lives in Los Angeles
INSERT INTO LivesIn (PersonID, CityID) VALUES (3, 3); -- Charlie lives in Chicago
GO

-------------------------------------------------
-- Region: 3. Graph Queries Using the MATCH Clause
-------------------------------------------------
/*
  3.1 Query: Find all people and the cities they live in.
  Uses the MATCH clause to traverse the graph.
*/
SELECT p.Name AS PersonName, c.Name AS CityName
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c);
GO

/*
  3.2 Query: Find all people who live in 'New York'.
*/
SELECT p.Name AS PersonName
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c)
  AND c.Name = 'New York';
GO

/*
  3.3 Query: Find all people who live in the same city as 'Alice'.
  This example uses a pattern where two different paths start from 'Alice'.
*/
SELECT p2.Name AS PersonName
FROM Person p1, LivesIn l1, City c, LivesIn l2, Person p2
WHERE MATCH(p1-(l1)->c<-(l2)-p2)
  AND p1.Name = 'Alice'
  AND p1.PersonID <> p2.PersonID;
GO

/*
  3.4 Query: Find all cities with more than one resident.
*/
SELECT c.Name AS CityName, COUNT(p.PersonID) AS NumberOfResidents
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c)
GROUP BY c.Name
HAVING COUNT(p.PersonID) > 1;
GO

-------------------------------------------------
-- Region: 4. Data Modification Operations
-------------------------------------------------
/*
  4.1 Update a person's age.
*/
UPDATE Person
SET Age = 31
WHERE PersonID = 1;
GO

/*
  4.2 Delete a relationship from the LivesIn edge table.
*/
DELETE FROM LivesIn
WHERE PersonID = 1 AND CityID = 1;
GO

/*
  4.3 Delete a person node.
*/
DELETE FROM Person
WHERE PersonID = 1;
GO

-------------------------------------------------
-- Region: 5. Cleanup
-------------------------------------------------
/*
  5.1 Drop the edge table.
*/
DROP TABLE LivesIn;
GO

/*
  5.2 Drop the node tables.
*/
DROP TABLE Person;
DROP TABLE City;
GO

/*
  5.3 Drop the graph database.
*/
DROP DATABASE GraphDB;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
