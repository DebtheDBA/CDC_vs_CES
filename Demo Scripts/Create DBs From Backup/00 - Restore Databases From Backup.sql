/* 
This will create the test databases based on the backup file provided. 
This can be used to create a StackOverflow_CDC or StackOverflow_CES.

You can find the file here: https://demodatabasebackup.blob.core.windows.net/stackoverflow-cdc-ces-backup/StackOverflow_CDC_CES_Initial.bak

NOTE: The backup is created from SQL Server 2025 instance.

Use Ctrl+Shift+M to replace the template value for the database name:
    <DatabaseToCreate, sysname, StackOverflow_CDC>

*/

-- Make sure that if the databases exist, that CDC or CES aren't enabled
IF EXISTS (
    SELECT * FROM sys.databases
    WHERE name = '<DatabaseToCreate, sysname, StackOverflow_CDC>'
    AND is_change_feed_enabled = 1
    )
EXEC [<DatabaseToCreate, sysname, StackOverflow_CDC>].sys.sp_disable_event_stream

IF EXISTS (
    SELECT * FROM sys.databases
    WHERE name = '<DatabaseToCreate, sysname, StackOverflow_CDC>'
    AND is_cdc_enabled = 1
    )
EXEC [<DatabaseToCreate, sysname, StackOverflow_CDC>].sys.sp_cdc_disable_db


USE [master];

DECLARE @backuplocation NVARCHAR(MAX),
    @mdflocation NVARCHAR(MAX),
    @ldflocation NVARCHAR(MAX)

SELECT @backuplocation = 
    -- replace this first part with the location of the backup file
    'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\'
    + 'StackOverflow_CDC_CES_Initial.bak',
    @mdflocation =
    -- replace this first part with the location of the mdf file
    'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\'
    + '<DatabaseToCreate, sysname, StackOverflow_CDC>.mdf',
    @ldflocation =
    -- replace this first part with the location of the mdf file
    'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\'
    + '<DatabaseToCreate, sysname, StackOverflow_CDC>.ldf'

-- set single use
ALTER DATABASE [<DatabaseToCreate, sysname, StackOverflow_CDC>]
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE


RESTORE DATABASE [<DatabaseToCreate, sysname, StackOverflow_CDC>]
FROM DISK = @backuplocation
WITH FILE = 1,
     MOVE N'StackOverflow_CES' TO @mdflocation,
     MOVE N'StackOverflow_CES_log' TO @ldflocation,
     NOUNLOAD,
     REPLACE,
     STATS = 5;
     
ALTER DATABASE [<DatabaseToCreate, sysname, StackOverflow_CDC>]
SET MULTI_USER

GO

USE [<DatabaseToCreate, sysname, StackOverflow_CDC>]
GO

IF NOT EXISTS (SELECT * FROM sys.database_files WHERE name = N'<DatabaseToCreate, sysname, StackOverflow_CDC>' AND type_desc = 'ROWS')
ALTER DATABASE [<DatabaseToCreate, sysname, StackOverflow_CDC>] MODIFY FILE (NAME=N'StackOverflow_CES', NEWNAME=N'<DatabaseToCreate, sysname, StackOverflow_CDC>')

IF NOT EXISTS (SELECT * FROM sys.database_files WHERE name = N'<DatabaseToCreate, sysname, StackOverflow_CDC>_log' AND type_desc = 'LOG')
ALTER DATABASE [<DatabaseToCreate, sysname, StackOverflow_CDC>] MODIFY FILE (NAME=N'StackOverflow_CES_log', NEWNAME=N'<DatabaseToCreate, sysname, StackOverflow_CDC>_log')

IF EXISTS (
    SELECT * FROM msdb.dbo.sysjobs AS jobs
    WHERE name LIKE 'cdc.<DatabaseToCreate, sysname, StackOverflow_CDC>%')
EXEC sys.sp_cdc_disable_db;
GO

USE master
GO
