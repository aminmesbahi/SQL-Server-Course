-- Query dictionaries for a specific columnstore index
SELECT
    object_name(object_id) AS TableName,
    index_id,
    column_id,
    dictionary_id,
    type_desc AS DictionaryType,
    entry_count AS EntryCount,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_dictionaries
WHERE object_id = OBJECT_ID('YourTableName');



-- Query row group details for a columnstore index
SELECT
    object_name(object_id) AS TableName,
    row_group_id,
    state_desc AS RowGroupState,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_row_groups
WHERE object_id = OBJECT_ID('YourTableName');




-- Query segment details for a columnstore index
SELECT
    object_name(object_id) AS TableName,
    segment_id,
    column_id,
    data_compression_desc AS CompressionType,
    row_count AS RowCount,
    size_in_bytes AS SizeInBytes
FROM sys.column_store_segments
WHERE object_id = OBJECT_ID('YourTableName');




-- Check memory usage for columnstore objects
SELECT
    object_id,
    index_id,
    allocated_bytes AS AllocatedBytes,
    used_bytes AS UsedBytes
FROM sys.dm_column_store_object_pool
WHERE database_id = DB_ID('YourDatabaseName');





-- Monitor operational stats for columnstore row groups
SELECT
    object_name(object_id) AS TableName,
    row_group_id,
    delta_rowgroup_rows AS DeltaRows,
    total_rowgroup_rows AS TotalRows,
    trim_reason_desc AS TrimReason,
    flush_count AS FlushCount
FROM sys.dm_db_column_store_row_group_operational_stats
WHERE object_id = OBJECT_ID('YourTableName');






-- Query physical stats of columnstore row groups
SELECT
    object_name(object_id) AS TableName,
    row_group_id,
    total_rows AS TotalRows,
    deleted_rows AS DeletedRows,
    trimmed_rows AS TrimmedRows,
    size_in_bytes AS SizeInBytes
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = OBJECT_ID('YourTableName');




-- Check operational stats for all indexes in a database
SELECT
    object_name(object_id) AS TableName,
    index_id,
    leaf_insert_count AS LeafInserts,
    leaf_delete_count AS LeafDeletes,
    leaf_update_count AS LeafUpdates,
    range_scan_count AS RangeScans
FROM sys.dm_db_index_operational_stats(DB_ID('YourDatabaseName'), NULL, NULL, NULL);




-- Check index fragmentation and physical stats
SELECT
    object_name(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent AS Fragmentation,
    page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID('YourDatabaseName'), NULL, NULL, NULL, 'LIMITED');





-- Query hash index stats for memory-optimized tables
SELECT
    object_id,
    index_id,
    bucket_count AS BucketCount,
    empty_bucket_count AS EmptyBucketCount,
    avg_chain_length AS AvgChainLength
FROM sys.dm_db_xtp_hash_index_stats;





-- Query index stats for memory-optimized tables
SELECT
    object_id,
    index_id,
    row_count AS RowCount,
    range_scan_count AS RangeScans,
    singleton_lookup_count AS Lookups
FROM sys.dm_db_xtp_index_stats;





-- Query nonclustered index stats for memory-optimized tables
SELECT
    object_id,
    index_id,
    row_count AS RowCount,
    range_scan_count AS RangeScans
FROM sys.dm_db_xtp_nonclustered_index_stats;




-- Memory usage of memory-optimized tables and indexes
SELECT
    object_name(object_id) AS TableName,
    memory_allocated_for_table_kb AS AllocatedMemoryKB,
    memory_used_by_table_kb AS UsedMemoryKB
FROM sys.dm_db_xtp_object_stats;




-- Memory stats for memory-optimized tables
SELECT
    object_id,
    memory_allocated_for_table_kb AS AllocatedMemoryKB,
    memory_used_by_table_kb AS UsedMemoryKB
FROM sys.dm_db_xtp_table_memory_stats;





-- Get details of hash indexes
SELECT
    object_id,
    index_id,
    type_desc AS IndexType,
    is_unique
FROM sys.hash_indexes;






-- List columns used in indexes
SELECT
    object_name(object_id) AS TableName,
    index_id,
    column_id,
    key_ordinal,
    is_included_column
FROM sys.index_columns
WHERE object_id = OBJECT_ID('YourTableName');






-- Query all indexes in a table
SELECT
    object_name(object_id) AS TableName,
    name AS IndexName,
    type_desc AS IndexType,
    is_unique,
    is_primary_key
FROM sys.indexes
WHERE object_id = OBJECT_ID('YourTableName');





-- Internal partitions for a table
SELECT
    object_name(object_id) AS TableName,
    partition_id,
    rows AS RowCount,
    data_compression_desc AS Compression
FROM sys.internal_partitions
WHERE object_id = OBJECT_ID('YourTableName');




-- Internal attributes for memory-optimized tables
SELECT
    object_id,
    type_desc AS AttributeType,
    state_desc AS State
FROM sys.memory_optimized_tables_internal_attributes;




-- Query partitions of a table
SELECT
    object_name(object_id) AS TableName,
    partition_number,
    rows AS RowCount
FROM sys.partitions
WHERE object_id = OBJECT_ID('YourTableName');





-- Finding missing indexes in a database
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
        '_',
        FORMAT(GETDATE(), 'yyyyMMdd'),  -- Date-based suffix for new indexes
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
        (COUNT(DISTINCT c.column_id) * 8) +  -- Basic size estimation heuristic
        (SUM(CASE WHEN typ.name IN ('nvarchar', 'nchar') THEN 2 ELSE 1 END * c.max_length)) 
        , ' bytes') AS SizeEstimate
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
    AND dm_migs.avg_total_user_cost * dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) > 10  -- Filter minor impacts
    AND dm_migs.last_user_seek > DATEADD(DAY, -30, GETDATE())  -- Only recent activity
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