USE StackOverflow_CDC
GO

/* Turn CDC on for:
	dbo.Users
	dbo.Posts

*/

/* Optional step 
-- CLR is required to get the __$updatemask values
*/
EXECUTE sp_configure 'clr enabled', 1;
RECONFIGURE;
GO


/* check the system */
SELECT name, is_cdc_enabled, is_change_feed_enabled, log_reuse_wait_desc
FROM sys.databases
WHERE name LIKE 'StackOverflow[_]%'
ORDER BY name;

/* Look at all of the objects first */
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    object_id,
    is_tracked_by_cdc
FROM sys.tables
ORDER BY SchemaName, name


-- enable for the database
EXEC sys.sp_cdc_enable_db
GO

-- enable for the tables
EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Users',
    @role_name = NULL;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Posts',
    @role_name = NULL;
GO


/* confirm the tables that are CDC enabled */
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    object_id,
    is_tracked_by_cdc
FROM sys.tables
ORDER BY SchemaName, name


/**************************************************/
-- Look at the jobs linked to CDC

SELECT * FROM msdb.dbo.sysjobs AS jobs
    JOIN msdb.dbo.cdc_jobs AS cdc ON cdc.job_id = jobs.job_id


/**************************************************/
-- Monitoring

/* 
Reports the internal CDC log‑scan sessions. 
Use it to monitor log‑scan progress, throughput, errors and latency. 
*/
SELECT * FROM sys.dm_cdc_log_scan_sessions


/* Check for errors */
SELECT * FROM sys.dm_cdc_errors




/* 
disable CDC at the end...
*/

EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Users',
    @capture_instance = N'all';
GO
    

EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Posts',
    @capture_instance = N'all';
GO
    
EXEC sys.sp_cdc_disable_db;
GO

-- check what happens when these are run
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    object_id,
    is_tracked_by_cdc
FROM sys.tabless
ORDER BY SchemaName, name


SELECT * FROM msdb.dbo.sysjobs AS jobs
WHERE name LIKE 'cdc.%'


/**************************************** 
Now that you've made your point, 
go back to the top and re-enable things.

Then go show the jobs in Object Explorer
****************************************/

-- enable for the database
EXEC sys.sp_cdc_enable_db
GO

-- enable for the tables
EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Users',
    @role_name = NULL;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Posts',
    @role_name = NULL;
GO

