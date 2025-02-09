-- Example: Declaring and using a cursor in SQL Server 2022

-- Create a sample table
IF OBJECT_ID('tempdb..#Employees') IS NOT NULL
    DROP TABLE #Employees;
CREATE TABLE #Employees
(
    EmployeeID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

-- Insert sample data
INSERT INTO #Employees (EmployeeID, FirstName, LastName)
VALUES (1, 'John', 'Doe'),
       (2, 'Jane', 'Smith'),
       (3, 'Bob', 'Johnson');

-- Declare variables to hold the data
DECLARE @EmployeeID INT, 
        @FirstName NVARCHAR(50), 
        @LastName NVARCHAR(50);

-- Declare the cursor
DECLARE EmployeeCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT EmployeeID, FirstName, LastName FROM #Employees;

-- Open the cursor
OPEN EmployeeCursor;

-- Fetch the first row
FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @FirstName, @LastName;

-- Loop through the rows
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT CONCAT('EmployeeID: ', @EmployeeID, '; Name: ', @FirstName, ' ', @LastName);

    -- Fetch the next row
    FETCH NEXT FROM EmployeeCursor INTO @EmployeeID, @FirstName, @LastName;
END

-- Close and deallocate the cursor
CLOSE EmployeeCursor;
DEALLOCATE EmployeeCursor;



-- Example 1: Basic Forward-Only Cursor
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


-- Example 2: Scrollable Cursor
DECLARE employee_scroll CURSOR SCROLL
FOR
SELECT EmployeeID, FirstName, LastName FROM HumanResources.Employee;

OPEN employee_scroll;

-- Navigate through records
FETCH FIRST FROM employee_scroll;
FETCH LAST FROM employee_scroll;
FETCH ABSOLUTE 5 FROM employee_scroll;
FETCH RELATIVE -2 FROM employee_scroll;
FETCH PRIOR FROM employee_scroll;

CLOSE employee_scroll;
DEALLOCATE employee_scroll;

-- Example 3: Updating Through Cursor
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

-- Example 4: Static Cursor
DECLARE static_cursor CURSOR STATIC
FOR
SELECT * FROM Sales.SalesOrderHeader;

-- Changes to source table won't affect cursor after opening

-- Example 5: Keyset Cursor
DECLARE keyset_cursor CURSOR KEYSET
FOR
SELECT CustomerID, AccountNumber FROM Sales.Customer;

-- Maintains membership but allows updates to non-key columns




-- Example 6: Parameterized Cursor
DECLARE @DepartmentID INT = 1;

DECLARE dept_cursor CURSOR LOCAL FAST_FORWARD
FOR 
SELECT BusinessEntityID, JobTitle FROM HumanResources.Employee
WHERE DepartmentID = @DepartmentID;


-- Example 7: Cursor with Error Handling
BEGIN TRY
    DECLARE error_cursor CURSOR FOR
    SELECT ProductID FROM Production.Product;

    OPEN error_cursor;
    FETCH NEXT FROM error_cursor;

    -- Force error
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
END CATCH

-- Example 8: Nested Cursors
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

-- Example 9: Dynamic Cursor (Reflects all changes)
DECLARE dynamic_cursor CURSOR DYNAMIC
FOR
SELECT ProductID, Name FROM Production.Product;

-- Will see changes made by other users during iteration