-------------------------------------
-- 9: Hierarchy Data
-------------------------------------

USE TestDB;
GO

-- Create a table with hierarchyid data type
CREATE TABLE dbo.Organization
(
    OrgNode hierarchyid PRIMARY KEY,
    OrgLevel AS OrgNode.GetLevel() PERSISTED,
    OrgName NVARCHAR(100),
    Manager NVARCHAR(100)
);
GO

-- Insert sample records
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

-- Query the hierarchy data
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager
FROM dbo.Organization
ORDER BY OrgNode;
GO

-- Create an index on the hierarchyid column
CREATE UNIQUE CLUSTERED INDEX IX_Organization_OrgNode ON dbo.Organization(OrgNode);
GO

-- Modify a record in the hierarchy
UPDATE dbo.Organization
SET OrgName = 'Division A Updated'
WHERE OrgNode = hierarchyid::GetRoot().GetDescendant(NULL, NULL);
GO

-- Delete a record from the hierarchy
DELETE FROM dbo.Organization
WHERE OrgNode = hierarchyid::GetRoot().GetDescendant(NULL, hierarchyid::GetRoot().GetDescendant(NULL, NULL));
GO

-- Query to get all descendants of a specific node
DECLARE @OrgNode hierarchyid = hierarchyid::GetRoot().GetDescendant(NULL, NULL);
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager
FROM dbo.Organization
WHERE OrgNode.IsDescendantOf(@OrgNode) = 1
ORDER BY OrgNode;
GO

-- Query to get the parent of a specific node
DECLARE @ChildNode hierarchyid = hierarchyid::GetRoot().GetDescendant(NULL, NULL).GetDescendant(NULL, NULL);
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager
FROM dbo.Organization
WHERE OrgNode = @ChildNode.GetAncestor(1);
GO

-- Query to get the root node
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager
FROM dbo.Organization
WHERE OrgNode = hierarchyid::GetRoot();
GO

-- Advanced query using JSON to represent the hierarchy
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager,
       JSON_QUERY((SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS OrgJSON
FROM dbo.Organization
ORDER BY OrgNode;
GO

-- Advanced query using SQL Server 2022 features to get hierarchy as JSON object
SELECT OrgNode.ToString() AS OrgNode, OrgLevel, OrgName, Manager,
       JSON_OBJECT('OrgNode' VALUE OrgNode.ToString(), 'OrgLevel' VALUE OrgLevel, 'OrgName' VALUE OrgName, 'Manager' VALUE Manager) AS OrgJSON
FROM dbo.Organization
ORDER BY OrgNode;
GO