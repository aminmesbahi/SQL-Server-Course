/**************************************************************
 * SQL Server 2022 Replication Tutorial
 * Description: This script demonstrates how to implement and manage
 *              replication in SQL Server 2022. It covers:
 *              - Setting up the distributor
 *              - Configuring publishers and subscribers
 *              - Creating publications with different article types
 *              - Setting up different replication types:
 *                 * Snapshot replication
 *                 * Transactional replication
 *                 * Peer-to-peer replication
 *                 * Merge replication
 *              - Monitoring and troubleshooting replication
 *              - Using conflict resolution in merge replication
 **************************************************************/

-------------------------------------------------
-- Region: 1. Preparing for Replication
-------------------------------------------------
USE master;
GO

/*
  Enable the SQL Server Agent, which is required for replication.
  This must be running for replication to work properly.
*/
-- Check if SQL Server Agent is running
EXEC master.dbo.xp_servicecontrol 'querystate', 'sqlserveragent';
GO

-- If not running, start it (requires admin privileges)
-- EXEC master.dbo.xp_servicecontrol 'start', 'sqlserveragent';
-- GO

/*
  Create a test database to be replicated.
*/
IF DB_ID('ReplicationDemo') IS NOT NULL
BEGIN
    ALTER DATABASE ReplicationDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ReplicationDemo;
END
GO

CREATE DATABASE ReplicationDemo;
GO

USE ReplicationDemo;
GO

/*
  Create sample tables that will be replicated.
*/
CREATE TABLE dbo.Customers
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    Created DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.Products
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    InStock BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE dbo.Orders
(
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    TotalAmount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID)
);
GO

CREATE TABLE dbo.OrderDetails
(
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID)
);
GO

/*
  Insert sample data into the tables.
*/
INSERT INTO dbo.Customers (FirstName, LastName, Email, Phone)
VALUES
    ('John', 'Smith', 'john.smith@example.com', '555-123-4567'),
    ('Jane', 'Doe', 'jane.doe@example.com', '555-987-6543'),
    ('Robert', 'Johnson', 'robert.johnson@example.com', '555-456-7890'),
    ('Lisa', 'Davis', 'lisa.davis@example.com', '555-789-0123'),
    ('Michael', 'Wilson', 'michael.wilson@example.com', '555-321-6540');
GO

INSERT INTO dbo.Products (ProductName, Category, Price)
VALUES
    ('Laptop', 'Electronics', 1200.00),
    ('Smartphone', 'Electronics', 800.00),
    ('Coffee Maker', 'Appliances', 120.00),
    ('Desk Chair', 'Furniture', 250.00),
    ('Headphones', 'Electronics', 150.00);
GO

-------------------------------------------------
-- Region: 2. Configuring the Distributor
-------------------------------------------------
/*
  Configure the current server as its own distributor.
  In a production environment, you might use a separate server.
*/
-- This script uses T-SQL to configure the distributor, but in production
-- environments, this is typically done through SQL Server Management Studio.

DECLARE @DistributionDB NVARCHAR(128) = 'distribution';

-- Create the distribution database
-- Note: In a real environment, you would specify storage locations
EXEC sp_adddistributiondb @database = @DistributionDB,
                         @data_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA',
                         @log_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA',
                         @log_file_size = 2,
                         @min_distretention = 0,
                         @max_distretention = 72,
                         @history_retention = 48,
                         @security_mode = 1; -- Uses Windows Authentication
GO

-- Configure distribution publisher properties
-- Replace 'YourServerName' with your actual server name
EXEC sp_adddistpublisher @publisher = 'YourServerName',
                        @distribution_db = 'distribution',
                        @security_mode = 1, -- Windows Authentication
                        @working_directory = 'C:\Replication\Working',
                        @publisher_type = 'MSSQLSERVER';
GO

-------------------------------------------------
-- Region: 3. Creating a Snapshot Publication
-------------------------------------------------
/*
  Create a snapshot publication that will replicate the Customers table.
  Snapshot replication takes a full copy of data at a point in time.
*/
USE ReplicationDemo;
GO

-- Enable the database for replication
EXEC sp_replicationdboption @dbname = 'ReplicationDemo',
                           @optname = 'publish',
                           @value = 'true';
GO

-- Create the publication
EXEC sp_addpublication @publication = 'SnapshotCustomersPublication',
                      @description = 'Snapshot publication of the Customers table',
                      @sync_method = 'native',
                      @retention = 0,
                      @allow_push = N'true',
                      @allow_pull = N'true',
                      @allow_anonymous = N'true',
                      @enabled_for_internet = N'false',
                      @snapshot_in_defaultfolder = N'true',
                      @compress_snapshot = N'false',
                      @ftp_port = 21,
                      @ftp_login = N'anonymous',
                      @allow_subscription_copy = N'false',
                      @add_to_active_directory = N'false',
                      @repl_freq = N'snapshot',
                      @status = N'active',
                      @independent_agent = N'true',
                      @immediate_sync = N'true',
                      @allow_sync_tran = N'false',
                      @autogen_sync_procs = N'false',
                      @allow_queued_tran = N'false',
                      @allow_dts = N'false',
                      @replicate_ddl = 1;
GO

-- Add the Customers table as an article to the publication
EXEC sp_addarticle @publication = 'SnapshotCustomersPublication',
                  @article = 'Customers',
                  @source_owner = 'dbo',
                  @source_object = 'Customers',
                  @type = 'logbased',
                  @description = N'',
                  @creation_script = N'',
                  @pre_creation_cmd = N'drop',
                  @schema_option = 0x000000000803509D,
                  @identityrangemanagementoption = N'none',
                  @destination_table = 'Customers',
                  @destination_owner = 'dbo',
                  @vertical_partition = N'false';
GO

-- Add a snapshot agent
-- Replace 'YourDomain\YourUser' with your actual domain and user
EXEC sp_addpublication_snapshot @publication = 'SnapshotCustomersPublication',
                               @frequency_type = 1,
                               @frequency_interval = 1,
                               @frequency_relative_interval = 1,
                               @frequency_recurrence_factor = 0,
                               @frequency_subday = 8,
                               @frequency_subday_interval = 1,
                               @active_start_time_of_day = 0,
                               @active_end_time_of_day = 235959,
                               @active_start_date = 0,
                               @active_end_date = 0,
                               @job_login = NULL,
                               @job_password = NULL,
                               @publisher_security_mode = 1;
GO

-------------------------------------------------
-- Region: 4. Creating a Transactional Publication
-------------------------------------------------
/*
  Create a transactional publication for the Orders and OrderDetails tables.
  Transactional replication captures and replicates data changes.
*/
EXEC sp_addpublication @publication = 'TransactionalOrdersPublication',
                      @description = 'Transactional publication of the Orders system',
                      @sync_method = 'concurrent',
                      @retention = 0,
                      @allow_push = N'true',
                      @allow_pull = N'true',
                      @allow_anonymous = N'false',
                      @enabled_for_internet = N'false',
                      @snapshot_in_defaultfolder = N'true',
                      @compress_snapshot = N'false',
                      @ftp_port = 21,
                      @allow_subscription_copy = N'false',
                      @add_to_active_directory = N'false',
                      @repl_freq = N'continuous',
                      @status = N'active',
                      @independent_agent = N'true',
                      @immediate_sync = N'true',
                      @allow_sync_tran = N'false',
                      @allow_queued_tran = N'false',
                      @allow_dts = N'false',
                      @replicate_ddl = 1;
GO

-- Add the Orders table as an article
EXEC sp_addarticle @publication = 'TransactionalOrdersPublication',
                  @article = 'Orders',
                  @source_owner = 'dbo',
                  @source_object = 'Orders',
                  @type = 'logbased',
                  @description = N'',
                  @creation_script = N'',
                  @pre_creation_cmd = N'drop',
                  @schema_option = 0x000000000803509D,
                  @identityrangemanagementoption = N'none',
                  @destination_table = 'Orders',
                  @destination_owner = 'dbo',
                  @vertical_partition = N'false';
GO

-- Add the OrderDetails table as an article
EXEC sp_addarticle @publication = 'TransactionalOrdersPublication',
                  @article = 'OrderDetails',
                  @source_owner = 'dbo',
                  @source_object = 'OrderDetails',
                  @type = 'logbased',
                  @description = N'',
                  @creation_script = N'',
                  @pre_creation_cmd = N'drop',
                  @schema_option = 0x000000000803509D,
                  @identityrangemanagementoption = N'none',
                  @destination_table = 'OrderDetails',
                  @destination_owner = 'dbo',
                  @vertical_partition = N'false';
GO

-- Add the Products table as an article for reference data
EXEC sp_addarticle @publication = 'TransactionalOrdersPublication',
                  @article = 'Products',
                  @source_owner = 'dbo',
                  @source_object = 'Products',
                  @type = 'logbased',
                  @description = N'',
                  @creation_script = N'',
                  @pre_creation_cmd = N'drop',
                  @schema_option = 0x000000000803509D,
                  @identityrangemanagementoption = N'none',
                  @destination_table = 'Products',
                  @destination_owner = 'dbo',
                  @vertical_partition = N'false';
GO

-- Add a snapshot agent for initial synchronization
EXEC sp_addpublication_snapshot @publication = 'TransactionalOrdersPublication',
                               @frequency_type = 1,
                               @frequency_interval = 1,
                               @frequency_relative_interval = 1,
                               @frequency_recurrence_factor = 0,
                               @frequency_subday = 8,
                               @frequency_subday_interval = 1,
                               @active_start_time_of_day = 0,
                               @active_end_time_of_day = 235959,
                               @active_start_date = 0,
                               @active_end_date = 0,
                               @job_login = NULL,
                               @job_password = NULL,
                               @publisher_security_mode = 1;
GO

-------------------------------------------------
-- Region: 5. Creating a Merge Publication
-------------------------------------------------
/*
  Create a merge publication for the Customers table.
  Merge replication allows changes at both publisher and subscriber.
*/
EXEC sp_replicationdboption @dbname = 'ReplicationDemo',
                           @optname = 'merge publish',
                           @value = 'true';
GO

EXEC sp_addmergepublication @publication = 'MergeCustomersPublication',
                           @description = 'Merge publication of the Customers table',
                           @retention = 14,
                           @sync_mode = 'native',
                           @allow_push = N'true',
                           @allow_pull = N'true',
                           @allow_anonymous = N'true',
                           @enabled_for_internet = N'false',
                           @snapshot_in_defaultfolder = N'true',
                           @compress_snapshot = N'false',
                           @ftp_port = 21,
                           @ftp_login = N'anonymous',
                           @ftp_password = null,
                           @conflict_retention = 14,
                           @keep_partition_changes = N'false',
                           @allow_subscription_copy = N'false',
                           @add_to_active_directory = N'false',
                           @dynamic_filters = N'false',
                           @conflict_logging = N'both',
                           @centralized_conflicts = N'true',
                           @validate_subscriber_info = N'false';
GO

-- Add the Customers article to the merge publication
EXEC sp_addmergearticle @publication = 'MergeCustomersPublication',
                       @article = 'Customers',
                       @source_owner = 'dbo',
                       @source_object = 'Customers',
                       @type = 'table',
                       @description = null,
                       @column_tracking = N'true',
                       @status = N'active',
                       @pre_creation_cmd = N'drop',
                       @identity_support = N'true',
                       @verify_resolver_signature = 0,
                       @allow_interactive_resolver = N'false';
GO

-- Add a snapshot agent for initial synchronization
EXEC sp_addpublication_snapshot @publication = 'MergeCustomersPublication',
                               @frequency_type = 1,
                               @frequency_interval = 1,
                               @frequency_relative_interval = 1,
                               @frequency_recurrence_factor = 0,
                               @frequency_subday = 8,
                               @frequency_subday_interval = 1,
                               @active_start_time_of_day = 0,
                               @active_end_time_of_day = 235959,
                               @active_start_date = 0,
                               @active_end_date = 0,
                               @job_login = NULL,
                               @job_password = NULL,
                               @publisher_security_mode = 1;
GO

-------------------------------------------------
-- Region: 6. Setting Up Subscribers
-------------------------------------------------
/*
  Set up a push subscription to the transactional publication.
  This script assumes a subscriber server named 'SubscriberServer'.
*/
-- Replace 'SubscriberServer' with your actual subscriber server name
DECLARE @subscriber_server NVARCHAR(128) = 'SubscriberServer';
DECLARE @subscriber_db NVARCHAR(128) = 'ReplicationDemo_Subscriber';

-- Create a push subscription to the transactional publication
EXEC sp_addsubscription @publication = 'TransactionalOrdersPublication',
                       @subscriber = @subscriber_server,
                       @destination_db = @subscriber_db,
                       @subscription_type = N'Push',
                       @sync_type = N'automatic',
                       @article = N'all',
                       @update_mode = N'read only',
                       @subscriber_type = 0;
GO

-- Add the distribution agent for the push subscription
EXEC sp_addpushsubscription_agent @publication = 'TransactionalOrdersPublication',
                                 @subscriber = 'SubscriberServer',
                                 @subscriber_db = 'ReplicationDemo_Subscriber',
                                 @job_login = NULL,
                                 @job_password = NULL,
                                 @subscriber_security_mode = 1,
                                 @frequency_type = 4,
                                 @frequency_interval = 1,
                                 @frequency_relative_interval = 1,
                                 @frequency_recurrence_factor = 0,
                                 @frequency_subday = 4,
                                 @frequency_subday_interval = 5,
                                 @active_start_time_of_day = 0,
                                 @active_end_time_of_day = 235959,
                                 @active_start_date = 0,
                                 @active_end_date = 0;
GO

/*
  Set up a push subscription to the merge publication.
*/
EXEC sp_addmergesubscription @publication = 'MergeCustomersPublication',
                            @subscriber = 'SubscriberServer',
                            @subscriber_db = 'ReplicationDemo_Subscriber',
                            @subscription_type = N'Push',
                            @sync_type = N'automatic',
                            @subscriber_type = N'local',
                            @subscription_priority = 75,
                            @status = N'active',
                            @subscription_host_server = NULL;
GO

-- Add the merge agent for the push subscription
EXEC sp_addmergepushsubscription_agent @publication = 'MergeCustomersPublication',
                                      @subscriber = 'SubscriberServer',
                                      @subscriber_db = 'ReplicationDemo_Subscriber',
                                      @job_login = NULL,
                                      @job_password = NULL,
                                      @subscriber_security_mode = 1,
                                      @frequency_type = 4,
                                      @frequency_interval = 1,
                                      @frequency_relative_interval = 1,
                                      @frequency_recurrence_factor = 0,
                                      @frequency_subday = 4,
                                      @frequency_subday_interval = 5,
                                      @active_start_time_of_day = 0,
                                      @active_end_time_of_day = 235959,
                                      @active_start_date = 0,
                                      @active_end_date = 0;
GO

-------------------------------------------------
-- Region: 7. Monitoring Replication
-------------------------------------------------
/*
  Monitor replication status and performance.
*/
-- Check the status of publications
SELECT 
    p.name AS PublicationName,
    p.publisher_db AS PublisherDB,
    p.publication_type AS PublicationType,
    CASE p.publication_type
        WHEN 0 THEN 'Transactional'
        WHEN 1 THEN 'Snapshot'
        WHEN 2 THEN 'Merge'
    END AS PublicationTypeDesc,
    p.immediate_sync AS ImmediateSync,
    p.allow_pull AS AllowPull,
    p.allow_push AS AllowPush,
    p.allow_anonymous AS AllowAnonymous,
    p.enabled_for_internet AS EnabledForInternet,
    p.status AS Status
FROM distribution.dbo.MSpublications p
ORDER BY p.name;
GO

-- Check the status of subscriptions
SELECT 
    p.publication AS PublicationName,
    s.subscriber_db AS SubscriberDB,
    s.subscription_type AS SubscriptionType,
    s.status AS Status,
    s.sync_type AS SyncType,
    s.nosync_type AS NoSyncType
FROM distribution.dbo.MSsubscriptions s
JOIN distribution.dbo.MSpublications p ON s.publication_id = p.publication_id
ORDER BY p.publication, s.subscriber_db;
GO

-- Check replication agents status
SELECT 
    ja.name AS AgentName,
    ja.enabled AS Enabled,
    ja.description AS Description,
    CASE jh.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In progress'
    END AS LastRunStatus,
    jh.run_date AS LastRunDate,
    jh.run_time AS LastRunTime,
    jh.run_duration AS RunDuration,
    jh.message AS LastMessage
FROM msdb.dbo.sysjobs ja
LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_id = jh.job_id
    AND jh.step_id = 0
    AND jh.instance_id = (
        SELECT MAX(instance_id)
        FROM msdb.dbo.sysjobhistory
        WHERE job_id = ja.job_id
        AND step_id = 0
    )
WHERE ja.category_id IN (1, 2) -- Replication agent categories
ORDER BY ja.name;
GO

-------------------------------------------------
-- Region: 8. Replication Maintenance
-------------------------------------------------
/*
  Perform maintenance tasks on replication.
*/
-- Start a snapshot agent manually
EXEC msdb.dbo.sp_start_job @job_name = 'YourServerName-ReplicationDemo-SnapshotCustomersPublication-1';
GO

-- Reinitialize a subscription
EXEC sp_reinitsubscription @publication = 'TransactionalOrdersPublication',
                          @subscriber = 'SubscriberServer',
                          @destination_db = 'ReplicationDemo_Subscriber',
                          @article = 'all';
GO

-- Validate a subscription
EXEC sp_publication_validation @publication = 'TransactionalOrdersPublication';
GO

-- Check for unresolved conflicts in merge replication
SELECT * FROM MSmerge_conflicts_info;
GO

-- Resolve conflicts (example of using the conflict resolver)
-- Note: This is typically done through SSMS in real environments
DECLARE @publication_name nvarchar(128) = 'MergeCustomersPublication';
DECLARE @article_name nvarchar(128) = 'Customers';
DECLARE @conflict_id uniqueidentifier; -- You would need to get this from MSmerge_conflicts_info

SELECT TOP 1 @conflict_id = conflict_id FROM MSmerge_conflicts_info
WHERE publication_name = @publication_name AND article_name = @article_name;

IF @conflict_id IS NOT NULL
BEGIN
    -- This example resolves in favor of the publisher
    EXEC sys.sp_resolve_conflict @publication = @publication_name, 
                                @conflict_id = @conflict_id,
                                @winner = 'publisher';
END;
GO

-------------------------------------------------
-- Region: 9. Cleanup
-------------------------------------------------
/*
  Script to clean up replication configuration.
  Be very careful with this in production environments!
*/
-- Comment these out in production. Only uncomment if you're sure you want to drop everything.
/*
-- Remove subscription
USE ReplicationDemo
EXEC sp_dropsubscription @publication = 'TransactionalOrdersPublication',
                        @subscriber = 'SubscriberServer',
                        @destination_db = 'ReplicationDemo_Subscriber',
                        @article = 'all';
GO

-- Remove the merge subscription
EXEC sp_dropmergesubscription @publication = 'MergeCustomersPublication',
                             @subscriber = 'SubscriberServer',
                             @subscriber_db = 'ReplicationDemo_Subscriber';
GO

-- Remove publications
EXEC sp_droppublication @publication = 'SnapshotCustomersPublication';
GO

EXEC sp_droppublication @publication = 'TransactionalOrdersPublication';
GO

EXEC sp_dropmergepublication @publication = 'MergeCustomersPublication';
GO

-- Disable replication on the database
EXEC sp_replicationdboption @dbname = 'ReplicationDemo',
                           @optname = 'publish',
                           @value = 'false';
GO

EXEC sp_replicationdboption @dbname = 'ReplicationDemo',
                           @optname = 'merge publish',
                           @value = 'false';
GO

-- Remove distributor configuration
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
GO

-- Drop the database
USE master;
GO

IF DB_ID('ReplicationDemo') IS NOT NULL
BEGIN
    ALTER DATABASE ReplicationDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ReplicationDemo;
END
GO
*/

-------------------------------------------------
-- End of Script
-------------------------------------------------