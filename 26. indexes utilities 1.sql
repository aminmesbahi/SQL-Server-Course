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





