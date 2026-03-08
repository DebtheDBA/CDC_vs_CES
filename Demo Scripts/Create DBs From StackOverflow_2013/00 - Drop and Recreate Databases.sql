
USE StackOverflow_CDC
GO

EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Users',
    @capture_instance = N'all';
GO

WAITFOR DELAY '00:00:01.000'

EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Posts',
    @capture_instance = N'all';
GO

WAITFOR DELAY '00:00:01.000'
GO
    
EXEC sys.sp_cdc_disable_db;
GO

-- check what happens when these are run
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    object_id,
    is_tracked_by_cdc
FROM sys.tables
ORDER BY SchemaName, name


SELECT * FROM msdb.dbo.sysjobs AS jobs
WHERE name LIKE 'cdc.%'
                                                                                                                                                           -- bit
/************************/

USE StackOverflow_CES
GO

-- remove specific object
EXEC sys.sp_remove_object_from_event_stream_group @stream_group_name = 'SQLCON', -- sysname
                                                  @object_name = N'dbo.Users'    -- nvarchar(512)


-- disable the stream group
EXEC sys.sp_drop_event_stream_group @stream_group_name = 'SQLCON' -- sysname


-- disable event stream completely
EXEC sys.sp_disable_event_stream


                                                                                                                                                           -- bit
/************************/

USE master
GO

-- there may be remaining threads open from change event streaming. 
ALTER DATABASE [StackOverflow_CDC] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE StackOverflow_CDC
GO

-- there may be remaining threads open from change event streaming. 
ALTER DATABASE [StackOverflow_CES] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

DROP DATABASE StackOverflow_CES
GO
                                                                                                                                                           -- bit
/************************/