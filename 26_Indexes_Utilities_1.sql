/**************************************************************
 * SQL Server 2022: Index, Columnstore, and Memory Usage Analysis
 * Description: This script demonstrates various queries to
 *              analyze columnstore indexes, memory-optimized
 *              objects, index usage and fragmentation, missing
 *              and unused indexes, and more. It uses new SQL Server
 *              2022 features and DMVs to provide deep insights.
 **************************************************************/

-------------------------------------------------
-- Region: 0. Initialization
-------------------------------------------------
/*
  Ensure you are using the correct database.
  Replace 'YourDatabaseName' with your actual database name.
*/
USE YourDatabaseName;
GO

-------------------------------------------------
-- Region: 1. Columnstore Dictionary Information
-------------------------------------------------
/*
  Query the dictionary for a specific columnstore index.
  Replace 'YourTableName' with the target table name.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    column_id,
    dictionary_id,
    type_desc AS DictionaryType,
    entry_count AS EntryCount,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_dictionaries
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 2. Columnstore Row Group Details
-------------------------------------------------
/*
  Query row group details for a columnstore index.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    row_group_id,
    state_desc AS RowGroupState,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 3. Columnstore Segment Details
-------------------------------------------------
/*
  Query segment details for a columnstore index.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    segment_id,
    column_id,
    data_compression_desc AS CompressionType,
    row_count AS RowCount,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_segments
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 4. Memory Usage for Columnstore Objects
-------------------------------------------------
/*
  Check memory usage for columnstore objects.
  Replace 'YourDatabaseName' with your database.
*/
SELECT
    object_id,
    index_id,
    allocated_bytes AS AllocatedBytes,
    used_bytes AS UsedBytes
FROM sys.dm_column_store_object_pool
WHERE database_id = DB_ID('YourDatabaseName');
GO

-------------------------------------------------
-- Region: 5. Operational Stats for Columnstore Row Groups
-------------------------------------------------
/*
  Monitor operational stats for columnstore row groups.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    row_group_id,
    delta_rowgroup_rows AS DeltaRows,
    total_rowgroup_rows AS TotalRows,
    trim_reason_desc AS TrimReason,
    flush_count AS FlushCount
FROM sys.dm_db_column_store_row_group_operational_stats
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 6. Physical Stats of Columnstore Row Groups
-------------------------------------------------
/*
  Query physical stats of columnstore row groups.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    row_group_id,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    trimmed_rows AS TrimmedRows,
    size_in_bytes AS SizeInBytes
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 7. Operational Stats for All Indexes in the Database
-------------------------------------------------
/*
  Check operational stats for all indexes in the database.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    leaf_insert_count AS LeafInserts,
    leaf_delete_count AS LeafDeletes,
    leaf_update_count AS LeafUpdates,
    range_scan_count AS RangeScans
FROM sys.dm_db_index_operational_stats(DB_ID('YourDatabaseName'), NULL, NULL, NULL);
GO

-------------------------------------------------
-- Region: 8. Index Fragmentation and Physical Stats
-------------------------------------------------
/*
  Check index fragmentation and page counts.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent AS Fragmentation,
    page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID('YourDatabaseName'), NULL, NULL, NULL, 'LIMITED');
GO

-------------------------------------------------
-- Region: 9. Hash Index Stats for Memory-Optimized Tables
-------------------------------------------------
/*
  Query hash index stats for memory-optimized tables.
*/
SELECT
    object_id,
    index_id,
    bucket_count AS BucketCount,
    empty_bucket_count AS EmptyBucketCount,
    avg_chain_length AS AvgChainLength
FROM sys.dm_db_xtp_hash_index_stats;
GO

-------------------------------------------------
-- Region: 10. Index Stats for Memory-Optimized Tables
-------------------------------------------------
/*
  Query index stats for memory-optimized tables.
*/
SELECT
    object_id,
    index_id,
    row_count AS RowCount,
    range_scan_count AS RangeScans,
    singleton_lookup_count AS Lookups
FROM sys.dm_db_xtp_index_stats;
GO

-------------------------------------------------
-- Region: 11. Nonclustered Index Stats for Memory-Optimized Tables
-------------------------------------------------
/*
  Query nonclustered index stats for memory-optimized tables.
*/
SELECT
    object_id,
    index_id,
    row_count AS RowCount,
    range_scan_count AS RangeScans
FROM sys.dm_db_xtp_nonclustered_index_stats;
GO

-------------------------------------------------
-- Region: 12. Memory Usage of Memory-Optimized Tables and Indexes
-------------------------------------------------
/*
  Query memory usage of memory-optimized tables and indexes.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    memory_allocated_for_table_kb AS AllocatedMemoryKB,
    memory_used_by_table_kb AS UsedMemoryKB
FROM sys.dm_db_xtp_object_stats;
GO

-------------------------------------------------
-- Region: 13. Memory Stats for Memory-Optimized Tables
-------------------------------------------------
/*
  Query memory stats for memory-optimized tables.
*/
SELECT
    object_id,
    memory_allocated_for_table_kb AS AllocatedMemoryKB,
    memory_used_by_table_kb AS UsedMemoryKB
FROM sys.dm_db_xtp_table_memory_stats;
GO

-------------------------------------------------
-- Region: 14. Details of Hash Indexes
-------------------------------------------------
/*
  Get details of hash indexes.
*/
SELECT
    object_id,
    index_id,
    type_desc AS IndexType,
    is_unique
FROM sys.hash_indexes;
GO

-------------------------------------------------
-- Region: 15. List Columns Used in Indexes
-------------------------------------------------
/*
  List columns used in indexes for a specific table.
  Replace 'YourTableName' with the target table name.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    column_id,
    key_ordinal,
    is_included_column
FROM sys.index_columns
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 16. Query All Indexes in a Table
-------------------------------------------------
/*
  Query all indexes defined on a specific table.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    type_desc AS IndexType,
    is_unique,
    is_primary_key
FROM sys.indexes
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 17. Internal Partitions for a Table
-------------------------------------------------
/*
  Query internal partitions for a specific table.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    partition_id,
    rows AS RowCount,
    data_compression_desc AS Compression
FROM sys.internal_partitions
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 18. Internal Attributes for Memory-Optimized Tables
-------------------------------------------------
/*
  Query internal attributes for memory-optimized tables.
*/
SELECT
    object_id,
    type_desc AS AttributeType,
    state_desc AS State
FROM sys.memory_optimized_tables_internal_attributes;
GO

-------------------------------------------------
-- Region: 19. Query Partitions of a Table
-------------------------------------------------
/*
  Query partitions of a specific table.
*/
SELECT
    OBJECT_NAME(object_id) AS TableName,
    partition_number,
    rows AS RowCount
FROM sys.partitions
WHERE object_id = OBJECT_ID('YourTableName');
GO

-------------------------------------------------
-- Region: 20. Finding Missing Indexes in a Database
-------------------------------------------------
/*
  Identify missing indexes that could improve query performance.
  This query suggests nonclustered index creation statements.
*/
SELECT TOP 50
    DB_NAME(dm_mid.database_id) AS DatabaseName,
    SCHEMA_NAME(obj.schema_id) AS SchemaName,
    OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) AS TableName,
    dm_migs.unique_compiles AS CompileCount,
    dm_migs.user_seeks + dm_migs.user_scans + dm_migs.system_seeks + dm_migs.system_scans AS TotalOperations,
    dm_migs.avg_total_user_cost * dm_migs.avg_user_impact AS ImprovementMeasure,
    dm_migs.avg_total_user_cost AS AvgQueryCost,
    dm_migs.avg_user_impact AS AvgPctGain,
    FORMAT(dm_migs.last_user_seek, 'yyyy-MM-dd HH:mm:ss') AS LastUserSeek,
    FORMAT(dm_migs.last_user_scan, 'yyyy-MM-dd HH:mm:ss') AS LastUserScan,
    dm_mid.equality_columns AS EqualityColumns,
    dm_mid.inequality_columns AS InequalityColumns,
    dm_mid.included_columns AS IncludedColumns,
    CONCAT(
        'CREATE NONCLUSTERED INDEX [IX_', 
        OBJECT_NAME(dm_mid.object_id, dm_mid.database_id), 
        '_', FORMAT(GETDATE(), 'yyyyMMdd'),
        CASE WHEN dm_mid.equality_columns IS NOT NULL 
            THEN REPLACE(REPLACE(LEFT(dm_mid.equality_columns, 50), '[', ''), ', ', '_') 
            ELSE '' END,
        CASE WHEN dm_mid.inequality_columns IS NOT NULL 
            THEN '_' + REPLACE(REPLACE(LEFT(dm_mid.inequality_columns, 50), '[', ''), ', ', '_') 
            ELSE '' END,
        '] ON ', 
        dm_mid.statement,
        ' (', 
        COALESCE(dm_mid.equality_columns + ', ', ''),
        COALESCE(dm_mid.inequality_columns, ''),
        ')',
        CASE WHEN dm_mid.included_columns IS NOT NULL 
            THEN ' INCLUDE (' + dm_mid.included_columns + ')' 
            ELSE '' END,
        ' WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 90);'
    ) AS CreateStatement,
    CONCAT(
        'Estimated Size: ~', 
        (COUNT(DISTINCT c.column_id) * 8) + 
        (SUM(CASE WHEN typ.name IN ('nvarchar', 'nchar') THEN 2 ELSE 1 END * c.max_length)),
        ' bytes'
    ) AS SizeEstimate
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
    ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
    ON dm_mig.index_handle = dm_mid.index_handle
LEFT JOIN sys.objects obj
    ON dm_mid.object_id = obj.object_id
LEFT JOIN sys.columns c
    ON dm_mid.object_id = c.object_id
LEFT JOIN sys.types typ
    ON c.system_type_id = typ.system_type_id
WHERE dm_mid.database_id = DB_ID()
    AND dm_migs.avg_total_user_cost * dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) > 10
    AND dm_migs.last_user_seek > DATEADD(DAY, -30, GETDATE())
GROUP BY
    dm_mid.database_id,
    obj.schema_id,
    dm_mid.object_id,
    dm_migs.unique_compiles,
    dm_migs.user_seeks,
    dm_migs.user_scans,
    dm_migs.system_seeks,
    dm_migs.system_scans,
    dm_migs.avg_total_user_cost,
    dm_migs.avg_user_impact,
    dm_migs.last_user_seek,
    dm_migs.last_user_scan,
    dm_mid.equality_columns,
    dm_mid.inequality_columns,
    dm_mid.included_columns,
    dm_mid.statement
ORDER BY ImprovementMeasure DESC;
GO

-------------------------------------------------
-- Region: 21. Unused Indexes in the Database
-------------------------------------------------
/*
  Identify indexes that are rarely used (low read counts) and could be candidates for removal.
*/
SELECT TOP 50
    QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name) AS QualifiedTableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ps.row_count AS TableRows,
    (ps.reserved_page_count * 8) / 1024.0 AS IndexSizeMB,
    COALESCE(dm_ius.user_seeks, 0) + COALESCE(dm_ius.user_scans, 0) + COALESCE(dm_ius.user_lookups, 0) AS TotalReads,
    COALESCE(dm_ius.user_updates, 0) AS TotalWrites,
    FORMAT(GREATEST(dm_ius.last_user_seek, dm_ius.last_user_scan, dm_ius.last_user_lookup), 'yyyy-MM-dd HH:mm:ss') AS LastUsedDate,
    FORMAT(i.create_date, 'yyyy-MM-dd HH:mm:ss') AS IndexCreatedDate,
    FORMAT(i.modify_date, 'yyyy-MM-dd HH:mm:ss') AS IndexModifiedDate,
    CONCAT_WS(', ',
        CASE WHEN i.is_unique = 1 THEN 'UNIQUE' END,
        CASE WHEN i.has_filter = 1 THEN 'FILTERED' END,
        CASE WHEN i.is_hypothetical = 1 THEN 'HYPOTHETICAL' END
    ) AS IndexProperties,
    CONCAT(
        'DROP INDEX ', QUOTENAME(i.name), 
        ' ON ', QUOTENAME(SCHEMA_NAME(o.schema_id)), '.', QUOTENAME(o.name),
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.data_spaces ds 
            WHERE ds.data_space_id = i.data_space_id AND ds.type = 'FX'
        )
            THEN ' WITH (ONLINE = ON)' ELSE '' END,
        ';'
    ) AS DropStatement,
    (ps.reserved_page_count * 8 * 1024) AS EstimatedSpaceBytes,
    p.data_compression_desc AS CompressionType,
    stat.rowmodctr AS RowModifications,
    (COALESCE(dm_ius.user_seeks, 0) * 1.0) / NULLIF(COALESCE(dm_ius.user_updates, 0), 0) AS ReadWriteRatio
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats dm_ius 
    ON i.object_id = dm_ius.object_id 
    AND i.index_id = dm_ius.index_id 
    AND dm_ius.database_id = DB_ID()
INNER JOIN sys.objects o 
    ON i.object_id = o.object_id
INNER JOIN sys.dm_db_partition_stats ps 
    ON i.object_id = ps.object_id 
    AND i.index_id = ps.index_id
LEFT JOIN sys.partitions p 
    ON i.object_id = p.object_id 
    AND i.index_id = p.index_id
LEFT JOIN sys.sysindexes stat 
    ON i.object_id = stat.id 
    AND i.index_id = stat.indid
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.type_desc = 'NONCLUSTERED'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND i.is_hypothetical = 0
    AND (COALESCE(dm_ius.user_seeks, 0) + COALESCE(dm_ius.user_scans, 0) + COALESCE(dm_ius.user_lookups, 0)) < 100
    AND (DATEDIFF(DAY, GREATEST(dm_ius.last_user_seek, dm_ius.last_user_scan, dm_ius.last_user_lookup), GETDATE()) > 30 
         OR GREATEST(dm_ius.last_user_seek, dm_ius.last_user_scan, dm_ius.last_user_lookup) IS NULL)
ORDER BY 
    EstimatedSpaceBytes DESC,
    TotalReads ASC,
    TotalWrites DESC;
GO

-------------------------------------------------
-- End of Script
-------------------------------------------------
