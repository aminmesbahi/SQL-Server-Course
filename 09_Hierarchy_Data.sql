/**************************************************************
 * SQL Server 2022 Hierarchy Data Tutorial
 * Description: This script demonstrates working with hierarchical 
 *              data using the hierarchyid data type in SQL Server. 
 *              It covers table creation, data insertion, querying,
 *              updating, deleting, and advanced JSON and SQL Server 2022
 *              features for hierarchy representation.
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
-- Region: 1. Creating the Hierarchy Table
-------------------------------------------------
/*
  1.1 Create a table using the hierarchyid data type.
  The computed column OrgLevel is persisted for quick access.
*/
IF OBJECT_ID(N'dbo.Organization', N'U') IS NOT NULL
    DROP TABLE dbo.Organization;
GO

CREATE TABLE dbo.Organization
(
    OrgNode hierarchyid PRIMARY KEY,
    OrgLevel AS OrgNode.GetLevel() PERSISTED,
    OrgName NVARCHAR(100),
    Manager NVARCHAR(100)
);
GO

-------------------------------------------------
-- Region: 2. Inserting Hierarchy Data
-------------------------------------------------
/*
  2.1 Insert sample records into the Organization table.
  Note: The hierarchyid::GetDescendant method is used to generate 
  hierarchical paths.
*/
INSERT INTO dbo.Organization (OrgNode, OrgName, Manager)
VALUES
    (hierarchyid::GetRoot(), 'Company', 'CEO'),
    (hierarchyid::GetRoot().GetDescendant(NULL, NULL), 'Division A', 'Manager A'),
    (hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL), 'Department A1', 'Manager A1'),
    (hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL).GetDescendant(NULL, NULL), 'Team A1-1', 'Manager A1-1'),
    (hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL).GetDescendant(NULL, hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL).GetDescendant(NULL, NULL)), 'Team A1-2', 'Manager A1-2'),
    (hierarchyid::GetRoot().GetDescendant(NULL, hierarchyid::GetRoot().GetDescendant(NULL, NULL)), 'Division B', 'Manager B'),
    (hierarchyid::GetRoot().GetDescendant(NULL, hierarchyid::GetRoot().GetDescendant(NULL, NULL)).GetDescendant(NULL, NULL), 'Department B1', 'Manager B1');
GO

-------------------------------------------------
-- Region: 3. Querying the Hierarchy Data
-------------------------------------------------
/*
  3.1 Retrieve the hierarchy data, ordering by the OrgNode.
*/
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager
FROM dbo.Organization
ORDER BY OrgNode;
GO

-------------------------------------------------
-- Region: 4. Indexing the Hierarchy Table
-------------------------------------------------
/*
  4.1 Create a unique clustered index on the OrgNode column for better performance.
*/
CREATE UNIQUE CLUSTERED INDEX IX_Organization_OrgNode 
ON dbo.Organization(OrgNode);
GO

-------------------------------------------------
-- Region: 5. Modifying and Deleting Hierarchy Data
-------------------------------------------------
/*
  5.1 Update: Modify a record in the hierarchy.
*/
UPDATE dbo.Organization
SET OrgName = 'Division A Updated'
WHERE OrgNode = hierarchyid::GetRoot().GetDescendant(NULL, NULL);
GO

/*
  5.2 Delete: Remove a record from the hierarchy.
*/
DELETE FROM dbo.Organization
WHERE OrgNode = hierarchyid::GetRoot().GetDescendant(NULL, hierarchyid::GetRoot().GetDescendant(NULL, NULL));
GO

-------------------------------------------------
-- Region: 6. Advanced Hierarchy Queries
-------------------------------------------------
/*
  6.1 Get all descendants of a specific node.
*/
DECLARE @OrgNode hierarchyid = hierarchyid::GetRoot().GetDescendant(NULL, NULL);
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager
FROM dbo.Organization
WHERE OrgNode.IsDescendantOf(@OrgNode) = 1
ORDER BY OrgNode;
GO

/*
  6.2 Get the parent of a specific node.
*/
DECLARE @ChildNode hierarchyid = hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL);
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager
FROM dbo.Organization
WHERE OrgNode = @ChildNode.GetAncestor(1);
GO

/*
  6.3 Get the root node.
*/
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager
FROM dbo.Organization
WHERE OrgNode = hierarchyid::GetRoot();
GO

-------------------------------------------------
-- Region: 7. Advanced JSON and SQL Server 2022 Hierarchy Queries
-------------------------------------------------
/*
  7.1 Advanced query: Represent hierarchy data as a JSON snippet.
*/
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager,
    JSON_QUERY(
        (SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager 
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    ) AS OrgJSON
FROM dbo.Organization
ORDER BY OrgNode;
GO

/*
  7.2 Advanced query using SQL Server 2022 JSON_OBJECT feature.
*/
SELECT 
    OrgNode.ToString() AS OrgNode, 
    OrgLevel, 
    OrgName, 
    Manager,
    JSON_OBJECT(
        'OrgNode' VALUE OrgNode.ToString(), 
        'OrgLevel' VALUE OrgLevel, 
        'OrgName' VALUE OrgName, 
        'Manager' VALUE Manager
    ) AS OrgJSON
FROM dbo.Organization
ORDER BY OrgNode;
GO

-------------------------------------------------
-- Region: End of Script
-------------------------------------------------