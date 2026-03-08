
USE StackOverflow_CES
GO


/* 
While this is still in Preview, confirm Database Preview features are configured
Skip this in Azure SQL DB
*/

SELECT * FROM sys.database_scoped_configurations WHERE [name] = 'PREVIEW_FEATURES'
GO

ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO

SELECT * FROM sys.database_scoped_configurations WHERE [name] = 'PREVIEW_FEATURES'
GO


/* Following these directions to connect to Event Hubs :
https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/change-event-streaming/configure?view=sql-server-ver17&tabs=sas-access%2Csas-token-auth#enable-and-configure-change-event-streaming
*/

/* Create Master Key & Database Scoped Principal*/

/* Master Key */
IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'';
END
GO


-- Create the backup of key needed for restores here. Trust me you will want these.


/* Database Scoped Credential 
*/

IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'SQLCON2026')
-- You can use ALTER DATABASE SCOPED CREDENTIALS if it does exist.
CREATE DATABASE SCOPED CREDENTIAL SQLCON2026
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
    -- for AMQP Protocol, use the <Generated SAS Token>. Be sure to copy the entire token. 
    -- for Kafka Protocol, use <Event Hubs Namespace – Primary or Secondary connection string>
    SECRET = ''



/* Is CES enabled? */
EXEC sp_help_change_feed
GO

/* Enable the Event Stream */
EXEC sys.sp_enable_event_stream
GO

/* Create the Event Stream Group 
Destination Type:
-- AMQP protocol:  AzureEventHubsAmqp
-- Kafka protocol: AzureEventHubsApacheKafka

Destination Location:
-- AMQP Protocol:  <AzureEventHubsHostName>/<EventHubsInstance>
-- Kafka protocol: <myEventHubsNamespace.servicebus.windows.net:9093/myEventHubsInstance>
*/
EXEC sys.sp_create_event_stream_group
    @stream_group_name =      N'SQLCON',
    @destination_type =       N'AzureEventHubsApacheKafka',
    @destination_location =   N'', 
    @destination_credential = 'SQLCON2026',
    @max_message_size_kb =    128
GO



/* Add Objects for Streaming */
EXEC sys.sp_add_object_to_event_stream_group
    N'SQLCON',
    N'dbo.Users'
GO

EXEC sys.sp_add_object_to_event_stream_group
    N'SQLCON',
    N'dbo.Posts'
GO


/* Look at what's set up for the table
-- not all of the values apply to CES
*/
EXEC sp_help_change_feed_table @source_schema = 'dbo', @source_name = 'Users'
GO
EXEC sp_help_change_feed_table @source_schema = 'dbo', @source_name = 'Posts'
GO