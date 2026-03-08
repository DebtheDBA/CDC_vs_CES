USE StackOverflow_CDC
GO

/* Check Database Log Usage 

Run against the database to check as sys.dm_db_log_space_usage is DB specific

https://learn.microsoft.com/en-us/sql/relational-databases/logs/the-transaction-log-sql-server?view=sql-server-ver17#factors-that-can-delay-log-truncation
+---------------------------+--------------------------------------------------+
| log_reuse_wait_desc       | Meaning                                          |
+---------------------------+--------------------------------------------------+
| NOTHING                   | No wait; log can be reused                       |
| CHECKPOINT                | Waiting for a checkpoint to complete             |
| LOG_BACKUP                | Waiting for a log backup                         |
| ACTIVE_BACKUP_OR_RESTORE  | Backup or restore activity in progress           |
| ACTIVE_TRANSACTION        | Active transaction prevents log truncation       |
| DATABASE_MIRRORING        | Waiting for database mirroring to advance        |
| REPLICATION               | Waiting for replication/log reader to catch up   |
| DATABASE_SNAPSHOT_CREATION| A database snapshot is being created             |
| LOG_SCAN                  | Log scanning required (e.g., restore / recovery) |
| AVAILABILITY_REPLICA      | Waiting for Always On availability replica       |
| OLDEST_PAGE               | Oldest page older than the checkpoint (LSN)      |
| OTHER_TRANSIENT           | Other transient condition preventing reuse       |
| XTP_CHECKPOINT            | In-Memory OLTP checkpoint needs to be performed  |
+---------------------------+--------------------------------------------------+
*/ 

SELECT db.NAME, 
    db.is_cdc_enabled, 
    db.is_change_feed_enabled, 
    db.log_reuse_wait_desc,
    USAGE.total_log_size_in_bytes/1024 AS TotalSizeInKB,
    USAGE.used_log_space_in_bytes/1024 AS TotalSpaceInKB,
    USAGE.used_log_space_in_percent,
    usage.log_space_in_bytes_since_last_backup/1024 AS SpaceUsedSinceLastBackupInKB
FROM sys.databases AS db
	JOIN sys.dm_db_log_space_usage AS usage ON usage.database_id = db.database_id


/* Look at the various other CDC schema tables */

--cdc.change_tables
--Returns one row for each change table in the database.
SELECT * FROM cdc.change_tables

--cdc.captured_columns
--Returns one row for each column tracked in a capture instance.
SELECT * FROM cdc.captured_columns

--cdc.ddl_history
--Returns one row for each data definition language (DDL) change made to tables that are enabled for change data capture.
SELECT * FROM cdc.ddl_history

--cdc.index_columns
--Returns one row for each index column associated with a change table.
SELECT * FROM cdc.index_columns
GO

/*******************************/
/* CDC Job information in msdb */
--msdb.dbo.cdc_jobs (Transact-SQL)
--Returns the configuration parameters for change data capture agent jobs.
SELECT * FROM msdb.dbo.cdc_jobs


/* https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/change-data-capture-stored-procedures-transact-sql?view=sql-server-ver17 */

/* Example - change the Cleanup Job for the current database */
EXEC sys.sp_cdc_change_job @job_type =  N'Cleanup', -- Options: Capture vs Cleanup
    @retention = 30 ,
    @threshold = 50000;




/* Check for latency - returned in seconds */
SELECT latency FROM sys.dm_cdc_log_scan_sessions 
WHERE session_id = 0

SELECT CASE WHEN duration = 0 
        THEN 0 
        ELSE command_count/duration 
    END AS [Throughput] 
FROM sys.dm_cdc_log_scan_sessions 
WHERE session_id = 0



/* CES Monitoring*/
USE StackOverflow_CES
GO

/**
NOTE: These are used by more than just CES
**/

SELECT * FROM sys.dm_change_feed_errors

SELECT * FROM sys.dm_change_feed_log_scan_sessions