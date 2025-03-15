/**************************************************************
 * SQL Server 2022 CLR Integration Tutorial
 * Description: This script demonstrates how to work with CLR
 *              (Common Language Runtime) integration in SQL Server 2022.
 *              It covers:
 *              - Enabling CLR integration in SQL Server
 *              - Creating and registering .NET assemblies
 *              - Creating CLR functions, stored procedures, and triggers
 *              - Working with CLR user-defined types
 *              - Security considerations for CLR objects
 *              - Performance considerations and best practices
 **************************************************************/

-------------------------------------------------
-- Region: 1. Introduction and Setup
-------------------------------------------------
USE master;
GO

/*
  Enable CLR integration in SQL Server.
  This is required to run CLR code in SQL Server.
*/
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

/*
  Create a test database for our CLR examples.
*/
IF DB_ID('CLRDemo') IS NOT NULL
BEGIN
    ALTER DATABASE CLRDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CLRDemo;
END
GO

CREATE DATABASE CLRDemo;
GO

USE CLRDemo;
GO

/*
  Set the database to TRUSTWORTHY to simplify the examples.
  Note: In production, carefully consider security implications of TRUSTWORTHY.
*/
ALTER DATABASE CLRDemo SET TRUSTWORTHY ON;
GO

-------------------------------------------------
-- Region: 2. Creating a Simple CLR Function
-------------------------------------------------
/*
  This region demonstrates creating a simple CLR scalar function.
  
  Note: Before executing this code, you need to compile a C# assembly.
  The C# code for this assembly would be:

  using System;
  using System.Data.SqlTypes;
  using Microsoft.SqlServer.Server;
  
  public class StringFunctions
  {
      [SqlFunction(IsDeterministic = true, IsPrecise = true)]
      public static SqlString ReverseString(SqlString input)
      {
          if (input.IsNull)
              return SqlString.Null;
              
          char[] charArray = input.Value.ToCharArray();
          Array.Reverse(charArray);
          return new SqlString(new string(charArray));
      }
      
      [SqlFunction(IsDeterministic = true, IsPrecise = true)]
      public static SqlInt32 CountVowels(SqlString input)
      {
          if (input.IsNull)
              return SqlInt32.Null;
              
          int count = 0;
          string vowels = "AEIOUaeiou";
          
          foreach (char c in input.Value)
          {
              if (vowels.IndexOf(c) >= 0)
                  count++;
          }
          
          return new SqlInt32(count);
      }
  }
*/

-- Create assembly from the compiled DLL
-- Assuming the DLL is saved at 'C:\Temp\StringFunctions.dll'
CREATE ASSEMBLY StringFunctions
FROM 'C:\Temp\StringFunctions.dll'
WITH PERMISSION_SET = SAFE;
GO

-- Create SQL Server function mapped to the CLR method
CREATE FUNCTION dbo.ReverseString(@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME StringFunctions.StringFunctions.ReverseString;
GO

-- Create another SQL Server function mapped to the CLR method
CREATE FUNCTION dbo.CountVowels(@input NVARCHAR(MAX))
RETURNS INT
AS EXTERNAL NAME StringFunctions.StringFunctions.CountVowels;
GO

-- Test the CLR functions
SELECT dbo.ReverseString('Hello World!') AS ReversedText;
GO

SELECT dbo.CountVowels('SQL Server CLR Integration') AS VowelCount;
GO

-------------------------------------------------
-- Region: 3. Creating a CLR Stored Procedure
-------------------------------------------------
/*
  This region demonstrates creating a CLR stored procedure.
  
  The C# code for this would be:
  
  using System;
  using System.Data;
  using System.Data.SqlClient;
  using System.Data.SqlTypes;
  using Microsoft.SqlServer.Server;
  using System.IO;
  
  public class FileSystemProcedures
  {
      [SqlProcedure]
      public static void ListFiles(SqlString directoryPath)
      {
          if (directoryPath.IsNull)
              return;
              
          try
          {
              DirectoryInfo dir = new DirectoryInfo(directoryPath.Value);
              FileInfo[] files = dir.GetFiles();
              
              // Create a result set with the file information
              SqlMetaData[] columns = {
                  new SqlMetaData("FileName", SqlDbType.NVarChar, 255),
                  new SqlMetaData("FileSizeBytes", SqlDbType.BigInt),
                  new SqlMetaData("LastModified", SqlDbType.DateTime)
              };
              
              // Send results back to SQL Server
              SqlDataRecord record = new SqlDataRecord(columns);
              SqlContext.Pipe.SendResultsStart(record);
              
              foreach (FileInfo file in files)
              {
                  record.SetString(0, file.Name);
                  record.SetInt64(1, file.Length);
                  record.SetDateTime(2, file.LastWriteTime);
                  SqlContext.Pipe.SendResultsRow(record);
              }
              
              SqlContext.Pipe.SendResultsEnd();
          }
          catch (Exception ex)
          {
              SqlContext.Pipe.Send("Error: " + ex.Message);
          }
      }
  }
*/

-- Create assembly from the compiled DLL
-- Assuming the DLL is saved at 'C:\Temp\FileSystemProcedures.dll'
CREATE ASSEMBLY FileSystemProcedures
FROM 'C:\Temp\FileSystemProcedures.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS; -- Note the elevated permission
GO

-- Create SQL Server stored procedure mapped to the CLR method
CREATE PROCEDURE dbo.ListFiles
    @directoryPath NVARCHAR(260)
AS EXTERNAL NAME FileSystemProcedures.FileSystemProcedures.ListFiles;
GO

-- Test the CLR stored procedure (adjust path as needed)
EXEC dbo.ListFiles 'C:\Windows\System32';
GO

-------------------------------------------------
-- Region: 4. Creating a CLR Aggregate Function
-------------------------------------------------
/*
  This region demonstrates creating a custom aggregate function using CLR.
  
  The C# code for a string concatenation aggregate might be:
  
  using System;
  using System.Data.SqlTypes;
  using System.IO;
  using System.Text;
  using Microsoft.SqlServer.Server;
  
  [Serializable]
  [SqlUserDefinedAggregate(Format.UserDefined, 
      IsInvariantToNulls = true,
      IsInvariantToOrder = false,
      IsInvariantToDistinct = false,
      MaxByteSize = 8000)]
  public class StringConcat : IBinarySerialize
  {
      private StringBuilder result;
      private string separator;
      
      public void Init()
      {
          result = new StringBuilder();
          separator = ",";
      }
      
      public void Accumulate(SqlString value, SqlString sep)
      {
          if (!sep.IsNull)
              separator = sep.Value;
              
          if (!value.IsNull)
          {
              if (result.Length > 0)
                  result.Append(separator);
                  
              result.Append(value.Value);
          }
      }
      
      public void Merge(StringConcat other)
      {
          if (other != null && other.result != null && other.result.Length > 0)
          {
              if (result.Length > 0)
                  result.Append(separator);
                  
              result.Append(other.result);
          }
      }
      
      public SqlString Terminate()
      {
          return new SqlString(result.ToString());
      }
      
      public void Read(BinaryReader r)
      {
          separator = r.ReadString();
          result = new StringBuilder(r.ReadString());
      }
      
      public void Write(BinaryWriter w)
      {
          w.Write(separator);
          w.Write(result.ToString());
      }
  }
*/

-- Create assembly from the compiled DLL
-- Assuming the DLL is saved at 'C:\Temp\StringAggregates.dll'
CREATE ASSEMBLY StringAggregates
FROM 'C:\Temp\StringAggregates.dll'
WITH PERMISSION_SET = SAFE;
GO

-- Create SQL Server aggregate function mapped to the CLR class
CREATE AGGREGATE dbo.StringConcat(@value NVARCHAR(MAX), @separator NVARCHAR(10))
RETURNS NVARCHAR(MAX)
EXTERNAL NAME StringAggregates.[StringConcat];
GO

-- Test the CLR aggregate function
CREATE TABLE dbo.Products
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100)
);
GO

INSERT INTO dbo.Products (ProductID, ProductName)
VALUES 
    (1, 'Laptop'),
    (2, 'Smartphone'),
    (3, 'Tablet'),
    (4, 'Monitor'),
    (5, 'Keyboard');
GO

-- Use the CLR aggregate to concatenate product names
SELECT dbo.StringConcat(ProductName, N', ') AS ProductList
FROM dbo.Products;
GO

-------------------------------------------------
-- Region: 5. Creating a CLR User-Defined Type
-------------------------------------------------
/*
  This region demonstrates creating a CLR user-defined type.
  
  The C# code for a Point type might be:
  
  using System;
  using System.Data.SqlTypes;
  using Microsoft.SqlServer.Server;
  using System.Data;
  using System.Text;
  using System.IO;
  
  [Serializable]
  [SqlUserDefinedType(Format.UserDefined, 
      IsByteOrdered = true, 
      MaxByteSize = 16)]
  public struct Point : INullable, IBinarySerialize
  {
      private bool _isNull;
      private double _x;
      private double _y;
      
      public bool IsNull
      {
          get { return _isNull; }
      }
      
      public static Point Null
      {
          get
          {
              Point pt = new Point();
              pt._isNull = true;
              return pt;
          }
      }
      
      public Point(double x, double y)
      {
          _x = x;
          _y = y;
          _isNull = false;
      }
      
      public double X
      {
          get
          {
              if (IsNull)
                  throw new SqlNullValueException();
              return _x;
          }
      }
      
      public double Y
      {
          get
          {
              if (IsNull)
                  throw new SqlNullValueException();
              return _y;
          }
      }
      
      public double Distance()
      {
          if (IsNull)
              return 0.0;
              
          return Math.Sqrt(_x * _x + _y * _y);
      }
      
      public static Point Parse(SqlString s)
      {
          if (s.IsNull)
              return Null;
              
          string[] coords = s.Value.Trim('(', ')').Split(',');
          if (coords.Length != 2)
              throw new ArgumentException("Point must be in format (x,y)");
              
          double x = double.Parse(coords[0]);
          double y = double.Parse(coords[1]);
          return new Point(x, y);
      }
      
      public override string ToString()
      {
          if (IsNull)
              return "NULL";
          return string.Format("({0},{1})", _x, _y);
      }
      
      public void Read(BinaryReader r)
      {
          _isNull = r.ReadBoolean();
          if (!_isNull)
          {
              _x = r.ReadDouble();
              _y = r.ReadDouble();
          }
      }
      
      public void Write(BinaryWriter w)
      {
          w.Write(_isNull);
          if (!_isNull)
          {
              w.Write(_x);
              w.Write(_y);
          }
      }
      
      [SqlMethod]
      public double DistanceTo(Point other)
      {
          if (IsNull || other.IsNull)
              return 0.0;
              
          double dx = _x - other._x;
          double dy = _y - other._y;
          return Math.Sqrt(dx * dx + dy * dy);
      }
  }
*/

-- Create assembly from the compiled DLL
-- Assuming the DLL is saved at 'C:\Temp\GeometryTypes.dll'
CREATE ASSEMBLY GeometryTypes
FROM 'C:\Temp\GeometryTypes.dll'
WITH PERMISSION_SET = SAFE;
GO

-- Create SQL Server user-defined type mapped to the CLR type
CREATE TYPE dbo.Point
EXTERNAL NAME GeometryTypes.[Point];
GO

-- Test the CLR user-defined type
DECLARE @point1 dbo.Point;
DECLARE @point2 dbo.Point;

SELECT @point1 = dbo.Point::Parse('(3,4)');
SELECT @point2 = dbo.Point::Parse('(6,8)');

SELECT 
    @point1.ToString() AS Point1,
    @point2.ToString() AS Point2,
    @point1.Distance() AS DistanceFromOrigin,
    @point1.DistanceTo(@point2) AS DistanceBetweenPoints;
GO

-- Create a table that uses the CLR type
CREATE TABLE dbo.Locations
(
    LocationID INT PRIMARY KEY,
    LocationName NVARCHAR(100),
    Coordinates dbo.Point
);
GO

-- Insert data using the CLR type
INSERT INTO dbo.Locations (LocationID, LocationName, Coordinates)
VALUES 
    (1, 'Store A', dbo.Point::Parse('(10.5,20.3)')),
    (2, 'Store B', dbo.Point::Parse('(30.2,15.8)')),
    (3, 'Store C', dbo.Point::Parse('(25.1,35.9)'));
GO

-- Query data using CLR type methods
SELECT 
    LocationID,
    LocationName,
    Coordinates.ToString() AS Coordinates,
    Coordinates.Distance() AS DistanceFromOrigin
FROM dbo.Locations
ORDER BY Coordinates.Distance();
GO

-------------------------------------------------
-- Region: 6. Creating a CLR Trigger
-------------------------------------------------
/*
  This region demonstrates creating a CLR trigger.
  
  The C# code for an audit trigger might be:
  
  using System;
  using System.Data;
  using System.Data.SqlClient;
  using Microsoft.SqlServer.Server;
  
  public class AuditTriggers
  {
      [SqlTrigger]
      public static void AuditDataChanges()
      {
          // Get the trigger context
          SqlTriggerContext triggerContext = SqlContext.TriggerContext;
          
          // Only execute for DML operations
          if (triggerContext.TriggerAction != TriggerAction.Delete && 
              triggerContext.TriggerAction != TriggerAction.Insert && 
              triggerContext.TriggerAction != TriggerAction.Update)
              return;
          
          using (SqlConnection conn = new SqlConnection("context connection=true"))
          {
              conn.Open();
              
              // Get the event type
              string eventType = triggerContext.TriggerAction.ToString();
              
              // Get the table name
              string tableName = triggerContext.TriggerContext.ToString();
              
              // Create and execute command to insert into audit table
              SqlCommand cmd = new SqlCommand(
                  "INSERT INTO dbo.AuditLog (EventType, TableName, EventDate, Username) " +
                  "VALUES (@EventType, @TableName, GETDATE(), SUSER_SNAME())", conn);
              
              cmd.Parameters.AddWithValue("@EventType", eventType);
              cmd.Parameters.AddWithValue("@TableName", tableName);
              
              cmd.ExecuteNonQuery();
          }
      }
  }
*/

-- Create an audit table for the CLR trigger
CREATE TABLE dbo.AuditLog
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(10) NOT NULL,
    TableName NVARCHAR(128) NOT NULL,
    EventDate DATETIME2 NOT NULL,
    Username NVARCHAR(128) NOT NULL
);
GO

-- Create assembly from the compiled DLL
-- Assuming the DLL is saved at 'C:\Temp\TriggerFunctions.dll'
CREATE ASSEMBLY TriggerFunctions
FROM 'C:\Temp\TriggerFunctions.dll'
WITH PERMISSION_SET = SAFE;
GO

-- Create a test table to apply the CLR trigger
CREATE TABLE dbo.Employees
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL
);
GO

-- Create CLR trigger on the Employees table
CREATE TRIGGER dbo.trAuditEmployeeChanges
ON dbo.Employees
AFTER INSERT, UPDATE, DELETE
AS EXTERNAL NAME TriggerFunctions.AuditTriggers.AuditDataChanges;
GO

-- Test the CLR trigger
INSERT INTO dbo.Employees (FirstName, LastName, Department, HireDate)
VALUES ('John', 'Doe', 'IT', '2023-01-15');
GO

UPDATE dbo.Employees
SET Department = 'Development'
WHERE EmployeeID = 1;
GO

DELETE FROM dbo.Employees
WHERE EmployeeID = 1;
GO

-- Check the audit log
SELECT * FROM dbo.AuditLog;
GO

-------------------------------------------------
-- Region: 7. Security Considerations
-------------------------------------------------
/*
  This region discusses security implications of CLR integration.
*/

-- SQL Server 2017 and later require CLR strict security by default
-- This prevents assembly creation without explicit authorization
EXEC sp_configure 'clr strict security', 1;
RECONFIGURE;
GO

/*
  PERMISSION_SET levels available for CLR assemblies:
  
  1. SAFE - Cannot access external system resources; can only compute and access data
  2. EXTERNAL_ACCESS - Can access certain external resources (files, network)
  3. UNSAFE - Unrestricted access; can call unmanaged code
  
  To use EXTERNAL_ACCESS or UNSAFE, additional permissions are required:
*/

-- Example of signing an assembly (conceptual, would be done when building the DLL)
/*
  1. Create a strong name key:
     sn -k MyStrongNameKey.snk
     
  2. Sign the assembly with the key:
     In Assembly declaration: [assembly: AssemblyKeyFile("MyStrongNameKey.snk")]
     
  3. Create certificate in SQL Server:
*/
USE master;
GO

CREATE CERTIFICATE CLRCodeSigningCert
FROM FILE = 'C:\Temp\MyCertificate.cer'
WITH PRIVATE KEY (FILE = 'C:\Temp\MyPrivateKey.pvk',
                  DECRYPTION BY PASSWORD = 'StrongPassword123');
GO

-- Create a login from the certificate
CREATE LOGIN CLRLogin FROM CERTIFICATE CLRCodeSigningCert;
GO

-- Grant the login EXTERNAL ACCESS ASSEMBLY permission
GRANT EXTERNAL ACCESS ASSEMBLY TO CLRLogin;
GO

USE CLRDemo;
GO

-- Create a user from the login
CREATE USER CLRUser FROM LOGIN CLRLogin;
GO

-- Add the certificate to the assembly
ADD SIGNATURE TO StringAggregates
BY CERTIFICATE CLRCodeSigningCert;
GO

-------------------------------------------------
-- Region: 8. Performance Considerations
-------------------------------------------------
/*
  This region discusses performance considerations for CLR integration.
*/

/*
  When to use CLR over T-SQL:
  
  - String manipulation and regular expressions
  - Complex calculations and algorithms
  - Custom aggregations
  - Accessing external resources
  - Working with hierarchical or XML data
  
  When to avoid CLR:
  
  - Simple CRUD operations
  - Set-based operations (where T-SQL excels)
  - When data access patterns would cause excessive context switching
*/

-- Example: Comparing T-SQL vs. CLR for string reversal
-- First, a T-SQL solution
CREATE FUNCTION dbo.ReverseTSQL(@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX) = N'';
    DECLARE @i INT = LEN(@input);
    
    WHILE @i > 0
    BEGIN
        SET @result = @result + SUBSTRING(@input, @i, 1);
        SET @i = @i - 1;
    END
    
    RETURN @result;
END;
GO

-- Test both functions with a simple benchmark
DECLARE @start DATETIME2;
DECLARE @input NVARCHAR(1000) = REPLICATE('SQL Server CLR Integration Performance Test. ', 20);
DECLARE @result NVARCHAR(1000);

-- Test T-SQL function
SET @start = SYSUTCDATETIME();
SET @result = dbo.ReverseTSQL(@input);
SELECT DATEDIFF(MICROSECOND, @start, SYSUTCDATETIME()) AS TSQL_Microseconds;

-- Test CLR function
SET @start = SYSUTCDATETIME();
SET @result = dbo.ReverseString(@input);
SELECT DATEDIFF(MICROSECOND, @start, SYSUTCDATETIME()) AS CLR_Microseconds;
GO

-------------------------------------------------
-- Region: 9. Debugging CLR Code
-------------------------------------------------
/*
  This region discusses debugging techniques for CLR code.
*/

/*
  Steps for debugging CLR code:
  
  1. Configure Visual Studio for SQL CLR debugging
     - Project Properties > Debug > Enable SQL Server debugging
     
  2. Deploy the assembly to SQL Server with debugging symbols
     - Ensure assembly is built with debug symbols (PDB files)
     
  3. Connect Visual Studio to SQL Server and set breakpoints
     
  4. Execute the CLR code from SQL Server
*/

-- Example: Enable debugging on an assembly
-- Note: This is conceptual and requires proper Visual Studio setup
/*
ALTER ASSEMBLY StringFunctions 
WITH PERMISSION_SET = SAFE, 
     DEBUG = ON;
GO
*/

-------------------------------------------------
-- Region: 10. Cleanup
-------------------------------------------------
/*
  Clean up the resources created in this tutorial.
  Be very careful with this in production environments!
*/

USE CLRDemo;
GO

-- Drop CLR objects
DROP TRIGGER dbo.trAuditEmployeeChanges;
DROP TABLE dbo.Employees;
DROP TABLE dbo.AuditLog;

DROP TABLE dbo.Locations;
DROP TYPE dbo.Point;

DROP AGGREGATE dbo.StringConcat;
DROP TABLE dbo.Products;

DROP PROCEDURE dbo.ListFiles;

DROP FUNCTION dbo.CountVowels;
DROP FUNCTION dbo.ReverseString;
DROP FUNCTION dbo.ReverseTSQL;

DROP ASSEMBLY TriggerFunctions;
DROP ASSEMBLY GeometryTypes;
DROP ASSEMBLY StringAggregates;
DROP ASSEMBLY FileSystemProcedures;
DROP ASSEMBLY StringFunctions;

-- Remove security objects
USE master;
GO

-- In a real environment, you'd remove these security objects
-- DROP USER CLRUser;
-- DROP LOGIN CLRLogin;
-- DROP CERTIFICATE CLRCodeSigningCert;

-- Disable CLR integration if no longer needed
EXEC sp_configure 'clr enabled', 0;
RECONFIGURE;
GO

-- Drop the database
USE master;
GO

ALTER DATABASE CLRDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE CLRDemo;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------