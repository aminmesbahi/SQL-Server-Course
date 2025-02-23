/**************************************************************
 * SQL Server 2022 Cursor Tutorial
 * Description: This script demonstrates various techniques for 
 *              using cursors in SQL Server, including:
 *              - Basic forward-only cursors.
 *              - Scrollable cursors.
 *              - Updating through cursors.
 *              - Static and keyset cursors.
 *              - Parameterized cursors.
 *              - Cursors with error handling.
 *              - Nested cursors.
 *              - Dynamic cursors.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization and Sample Data Setup
-------------------------------------------------
/*
  Create a temporary table for cursor demonstration.
*/
IF OBJECT_ID('tempdb..#Employees') IS NOT NULL
    DROP TABLE #Employees;
GO

CREATE TABLE #Employees
(
    EmployeeID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);
GO

INSERT INTO #Employees (EmployeeID, FirstName, LastName)
VALUES 
    (1, 'John', 'Doe'),
    (2, 'Jane', 'Smith'),
    (3, 'Bob', 'Johnson');
GO

-------------------------------------------------
-- Region: 1. Basic Cursor Example
-------------------------------------------------
/*
  Example: Declaring and using a basic forward-only cursor.
  This cursor iterates over the #Employees table and prints each row.
*/
DECLARE @EmployeeID INT, 
        @FirstName NVARCHAR(50), 
        @LastName NVARCHAR(50);

DECLARE EmployeeCursor CURSOR LOCAL FAST_FORWARD
FOR
    SELECT EmployeeID, FirstName, LastName FROM #Employees;

OPEN EmployeeCursor;

FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @FirstName, @LastName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT CONCAT('EmployeeID: ', @EmployeeID, '; Name: ', @FirstName, ' ', @LastName);
    FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @FirstName, @LastName;
END

CLOSE EmployeeCursor;
DEALLOCATE EmployeeCursor;
GO

-------------------------------------------------
-- Region: 2. Basic Forward-Only Cursor (Example 1)
-------------------------------------------------
/*
  Example 1: Basic forward-only cursor for iterating over a product list.
  (Assumes a Production.Product table exists.)
*/
DECLARE @ProductID INT, @ProductName NVARCHAR(50);

DECLARE product_cursor CURSOR LOCAL FAST_FORWARD
FOR 
    SELECT ProductID, ProductName FROM Production.Product;

OPEN product_cursor;
FETCH NEXT FROM product_cursor INTO @ProductID, @ProductName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing Product ID: ' + CAST(@ProductID AS VARCHAR) + ' - ' + @ProductName;
    FETCH NEXT FROM product_cursor INTO @ProductID, @ProductName;
END

CLOSE product_cursor;
DEALLOCATE product_cursor;
GO

-------------------------------------------------
-- Region: 3. Scrollable Cursor (Example 2)
-------------------------------------------------
/*
  Example 2: A scrollable cursor that allows navigation to the first, last, 
  absolute, relative, and prior rows.
  (Assumes HumanResources.Employee table exists.)
*/
DECLARE employee_scroll CURSOR SCROLL
FOR
    SELECT EmployeeID, FirstName, LastName FROM HumanResources.Employee;

OPEN employee_scroll;

-- Navigate through records (demonstration purposes; results not printed)
FETCH FIRST FROM employee_scroll;
FETCH LAST FROM employee_scroll;
FETCH ABSOLUTE 5 FROM employee_scroll;
FETCH RELATIVE -2 FROM employee_scroll;
FETCH PRIOR FROM employee_scroll;

CLOSE employee_scroll;
DEALLOCATE employee_scroll;
GO

-------------------------------------------------
-- Region: 4. Updating Through Cursor (Example 3)
-------------------------------------------------
/*
  Example 3: Using a cursor to update rows.
  Updates the ListPrice of products from Production.Product if the price is below 100.
*/
DECLARE update_cursor CURSOR
FOR 
    SELECT ProductID, ListPrice FROM Production.Product
    FOR UPDATE OF ListPrice;

DECLARE @ProdID INT, @Price MONEY;

OPEN update_cursor;
FETCH NEXT FROM update_cursor INTO @ProdID, @Price;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Price < 100
    BEGIN
        UPDATE Production.Product
        SET ListPrice = @Price * 1.1
        WHERE CURRENT OF update_cursor;
    END
    FETCH NEXT FROM update_cursor INTO @ProdID, @Price;
END

CLOSE update_cursor;
DEALLOCATE update_cursor;
GO

-------------------------------------------------
-- Region: 5. Static Cursor (Example 4)
-------------------------------------------------
/*
  Example 4: A static cursor that remains unaffected by changes in the source table 
  after it is opened.
  (Assumes Sales.SalesOrderHeader exists.)
*/
DECLARE static_cursor CURSOR STATIC
FOR
    SELECT * FROM Sales.SalesOrderHeader;
-- Cursor operations would go here...
CLOSE static_cursor;
DEALLOCATE static_cursor;
GO

-------------------------------------------------
-- Region: 6. Keyset Cursor (Example 5)
-------------------------------------------------
/*
  Example 5: A keyset cursor which maintains membership of rows (keys) even if non-key 
  columns are updated.
  (Assumes Sales.Customer exists.)
*/
DECLARE keyset_cursor CURSOR KEYSET
FOR
    SELECT CustomerID, AccountNumber FROM Sales.Customer;
-- Cursor operations would go here...
CLOSE keyset_cursor;
DEALLOCATE keyset_cursor;
GO

-------------------------------------------------
-- Region: 7. Parameterized Cursor (Example 6)
-------------------------------------------------
/*
  Example 6: A parameterized cursor filtering by a specific department.
  (Assumes HumanResources.Employee exists with a DepartmentID column.)
*/
DECLARE @DepartmentID INT = 1;

DECLARE dept_cursor CURSOR LOCAL FAST_FORWARD
FOR 
    SELECT BusinessEntityID, JobTitle FROM HumanResources.Employee
    WHERE DepartmentID = @DepartmentID;
-- Cursor operations would go here...
CLOSE dept_cursor;
DEALLOCATE dept_cursor;
GO

-------------------------------------------------
-- Region: 8. Cursor with Error Handling (Example 7)
-------------------------------------------------
/*
  Example 7: A cursor with TRY/CATCH for error handling.
  Forces an error (division by zero) to demonstrate error capture.
*/
BEGIN TRY
    DECLARE error_cursor CURSOR FOR
        SELECT ProductID FROM Production.Product;

    OPEN error_cursor;
    FETCH NEXT FROM error_cursor; -- Not fetching into variables for brevity

    -- Force an error (division by zero)
    SELECT 1/0;
    
    CLOSE error_cursor;
    DEALLOCATE error_cursor;
END TRY
BEGIN CATCH
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
    
    IF CURSOR_STATUS('local','error_cursor') >= -1
    BEGIN
        CLOSE error_cursor;
        DEALLOCATE error_cursor;
    END
END CATCH;
GO

-------------------------------------------------
-- Region: 9. Nested Cursors (Example 8)
-------------------------------------------------
/*
  Example 8: Using nested cursors.
  The outer cursor iterates through departments and the inner cursor iterates 
  through employees within each department.
  (Assumes HumanResources.Department and HumanResources.Employee exist, and that 
  Employee has a DepartmentID column.)
*/
DECLARE @DeptID INT, @DeptName NVARCHAR(50);
DECLARE @EmpID INT, @EmpName NVARCHAR(100);

DECLARE dept_cursor CURSOR FOR
    SELECT DepartmentID, Name FROM HumanResources.Department;

OPEN dept_cursor;
FETCH NEXT FROM dept_cursor INTO @DeptID, @DeptName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Department: ' + @DeptName;
    
    DECLARE emp_cursor CURSOR FOR
        SELECT BusinessEntityID, FirstName + ' ' + LastName 
        FROM HumanResources.Employee
        WHERE DepartmentID = @DeptID;
    
    OPEN emp_cursor;
    FETCH NEXT FROM emp_cursor INTO @EmpID, @EmpName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '   Employee: ' + @EmpName;
        FETCH NEXT FROM emp_cursor INTO @EmpID, @EmpName;
    END
    
    CLOSE emp_cursor;
    DEALLOCATE emp_cursor;
    
    FETCH NEXT FROM dept_cursor INTO @DeptID, @DeptName;
END

CLOSE dept_cursor;
DEALLOCATE dept_cursor;
GO

-------------------------------------------------
-- Region: 10. Dynamic Cursor (Example 9)
-------------------------------------------------
/*
  Example 9: A dynamic cursor that reflects all changes made to the data after it is opened.
  (Assumes Production.Product exists.)
*/
DECLARE dynamic_cursor CURSOR DYNAMIC
FOR
    SELECT ProductID, Name FROM Production.Product;
    
-- Operations using the dynamic cursor would go here.
-- For demonstration, we'll simply open and close the cursor.
OPEN dynamic_cursor;
FETCH NEXT FROM dynamic_cursor;
CLOSE dynamic_cursor;
DEALLOCATE dynamic_cursor;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------