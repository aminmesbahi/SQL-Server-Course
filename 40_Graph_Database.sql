-- Create a database for the graph example
CREATE DATABASE GraphDB;
GO

USE GraphDB;
GO

-- Create node tables
CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Age INT
) AS NODE;

CREATE TABLE City (
    CityID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;

-- Create edge table
CREATE TABLE LivesIn (
    PersonID INT,
    CityID INT,
    CONSTRAINT FK_Person FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    CONSTRAINT FK_City FOREIGN KEY (CityID) REFERENCES City(CityID)
) AS EDGE;
GO

-- Insert data into node tables
INSERT INTO Person (PersonID, Name, Age) VALUES (1, 'Alice', 30);
INSERT INTO Person (PersonID, Name, Age) VALUES (2, 'Bob', 25);
INSERT INTO Person (PersonID, Name, Age) VALUES (3, 'Charlie', 35);

INSERT INTO City (CityID, Name) VALUES (1, 'New York');
INSERT INTO City (CityID, Name) VALUES (2, 'Los Angeles');
INSERT INTO City (CityID, Name) VALUES (3, 'Chicago');

-- Insert data into edge table
INSERT INTO LivesIn (PersonID, CityID) VALUES (1, 1); -- Alice lives in New York
INSERT INTO LivesIn (PersonID, CityID) VALUES (2, 2); -- Bob lives in Los Angeles
INSERT INTO LivesIn (PersonID, CityID) VALUES (3, 3); -- Charlie lives in Chicago
GO

-- Find all people and the cities they live in
SELECT p.Name AS PersonName, c.Name AS CityName
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c);
GO

-- Find all people who live in 'New York'
SELECT p.Name AS PersonName
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c) AND c.Name = 'New York';
GO

-- Find all people who live in the same city as 'Alice'
SELECT p2.Name AS PersonName
FROM Person p1, LivesIn l1, City c, LivesIn l2, Person p2
WHERE MATCH(p1-(l1)->c<-(l2)-p2) AND p1.Name = 'Alice' AND p1.PersonID <> p2.PersonID;
GO

-- Find all cities with more than one person living in them
SELECT c.Name AS CityName, COUNT(p.PersonID) AS NumberOfResidents
FROM Person p, LivesIn l, City c
WHERE MATCH(p-(l)->c)
GROUP BY c.Name
HAVING COUNT(p.PersonID) > 1;
GO

-- Update a person's age
UPDATE Person
SET Age = 31
WHERE PersonID = 1;
GO

-- Delete a relationship
DELETE FROM LivesIn
WHERE PersonID = 1 AND CityID = 1;
GO

-- Delete a person
DELETE FROM Person
WHERE PersonID = 1;
GO


-- Drop edge table
DROP TABLE LivesIn;
GO

-- Drop node tables
DROP TABLE Person;
DROP TABLE City;
GO

-- Drop the database
DROP DATABASE GraphDB;
GO