**SQL Server SET Commands Explained**

Below are explanations and examples for commonly used `SET` commands in SQL Server. Each command controls a specific aspect of query execution or session behavior.

### 1. **SET ANSI_DEFAULTS**
Enables a group of ANSI settings.
```sql
SET ANSI_DEFAULTS ON;
-- Automatically enables options like ANSI_NULLS, ANSI_WARNINGS, and ANSI_PADDING.
SELECT * FROM sys.objects;
```

### 2. **SET ANSI_NULL_DFLT_OFF**
Specifies that new columns default to `NOT NULL` unless specified otherwise.
```sql
SET ANSI_NULL_DFLT_OFF ON;
CREATE TABLE Test (Col1 INT);
-- Col1 defaults to NOT NULL.
```

### 3. **SET ANSI_NULL_DFLT_ON**
Specifies that new columns default to `NULL` unless specified otherwise.
```sql
SET ANSI_NULL_DFLT_ON ON;
CREATE TABLE Test (Col1 INT);
-- Col1 defaults to NULL.
```

### 4. **SET ANSI_NULLS**
Determines how SQL Server handles `NULL` comparisons.
```sql
SET ANSI_NULLS ON;
SELECT * FROM Test WHERE Col1 = NULL; -- Returns no rows.

SET ANSI_NULLS OFF;
SELECT * FROM Test WHERE Col1 = NULL; -- Returns rows where Col1 is NULL.
```

### 5. **SET ANSI_PADDING**
Controls padding behavior for `CHAR` and `VARCHAR` data types.
```sql
SET ANSI_PADDING ON;
CREATE TABLE Test (Col1 CHAR(10));
INSERT INTO Test VALUES ('A');
-- Col1 will store 'A        ' (padded).
```

### 6. **SET ANSI_WARNINGS**
Controls whether certain warnings are issued.
```sql
SET ANSI_WARNINGS ON;
-- Raises warnings for divide-by-zero or null-in-aggregate operations.
SELECT 1 / 0; -- Error: Divide by zero.
```

### 7. **SET ARITHABORT**
Specifies whether a query is terminated on arithmetic errors.
```sql
SET ARITHABORT ON;
SELECT 1 / 0; -- Query is terminated.
```

### 8. **SET ARITHIGNORE**
Determines whether arithmetic errors produce a warning or are ignored.
```sql
SET ARITHIGNORE ON;
SELECT 1 / 0; -- No error, result is NULL.
```

### 9. **SET CONCAT_NULL_YIELDS_NULL**
Specifies whether concatenating a `NULL` value results in `NULL`.
```sql
SET CONCAT_NULL_YIELDS_NULL ON;
SELECT 'Hello' + NULL; -- Returns NULL.

SET CONCAT_NULL_YIELDS_NULL OFF;
SELECT 'Hello' + NULL; -- Returns 'Hello'.
```

### 10. **SET CONTEXT_INFO**
Sets a binary value for the session.
```sql
DECLARE @Info VARBINARY(128) = CAST('SessionData' AS VARBINARY(128));
SET CONTEXT_INFO @Info;
SELECT CONTEXT_INFO();
```

### 11. **SET CURSOR_CLOSE_ON_COMMIT**
Determines whether cursors close after a transaction is committed.
```sql
SET CURSOR_CLOSE_ON_COMMIT ON;
DECLARE CursorTest CURSOR FOR SELECT * FROM sys.objects;
OPEN CursorTest;
COMMIT; -- Cursor is closed.
```

### 12. **SET DATEFIRST**
Sets the first day of the week.
```sql
SET DATEFIRST 1; -- 1 = Monday.
SELECT DATEPART(WEEKDAY, GETDATE());
```

### 13. **SET DATEFORMAT**
Defines the format for date inputs.
```sql
SET DATEFORMAT DMY;
SELECT CAST('31-12-2025' AS DATETIME); -- Valid.
```

### 14. **SET DEADLOCK_PRIORITY**
Specifies the priority for resolving deadlocks.
```sql
SET DEADLOCK_PRIORITY LOW;
-- Session is chosen as the victim in case of a deadlock.
```

### 15. **SET FIPS_FLAGGER**
Warns about non-standard SQL usage.
```sql
SET FIPS_FLAGGER ENTRY;
-- Raises warnings for non-standard SQL.
```

### 16. **SET FMTONLY**
Returns metadata only without data rows.
```sql
SET FMTONLY ON;
SELECT * FROM sys.objects;
-- Returns column metadata only.
```

### 17. **SET FORCEPLAN**
Forces the query optimizer to process joins in the specified order.
```sql
SET FORCEPLAN ON;
SELECT * FROM TableA, TableB WHERE TableA.ID = TableB.ID;
```

### 18. **SET IDENTITY_INSERT**
Allows explicit values to be inserted into an identity column.
```sql
SET IDENTITY_INSERT Test ON;
INSERT INTO Test (ID, Name) VALUES (1, 'Manual');
SET IDENTITY_INSERT Test OFF;
```

### 19. **SET IMPLICIT_TRANSACTIONS**
Automatically starts a transaction for certain commands.
```sql
SET IMPLICIT_TRANSACTIONS ON;
DELETE FROM Test;
-- Transaction is started but not committed.
COMMIT;
```

### 20. **SET LANGUAGE**
Sets the language for the session.
```sql
SET LANGUAGE French;
SELECT DATENAME(MONTH, GETDATE());
-- Returns month name in French.
```

---

This file provides quick tutorials and examples for SQL Server `SET` commands, helping users configure and control query execution and session behaviors effectively.

