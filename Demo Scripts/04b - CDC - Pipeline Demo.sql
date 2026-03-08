-- don't run this in SSMS - you may blow things up...
USE StackOverflow_CDC
GO

/* Putting this together. 

* We need to get the changes since the last time we got the data.
* The process runs every interval.
* In order to make this work, we will store the max LSN to know what that value was.

*/

DECLARE @datetime DATETIME, -- used for simulating time that pipeline is running
	@min_lsn BINARY(10),	-- holds the min LSN to say when we start getting values from
	@max_lsn BINARY(10),	-- holds the max LSN to become the new min_lsn for the next pull
	@postrecordcount INT,	-- number of post records returned
	@userrecordcount INT	-- number of user records returned
;
/* Set the starting date & min_lsn */
SELECT @datetime = MIN(tran_begin_time) 
FROM cdc.lsn_time_mapping
SELECT @min_lsn = start_lsn FROM cdc.lsn_time_mapping WHERE tran_begin_time = @datetime

SELECT TOP 1 @max_lsn = start_lsn
FROM cdc.lsn_time_mapping
WHERE tran_begin_time > DATEADD(SECOND, 15, @datetime)

WHILE ((SELECT MAX(Start_lsn) FROM cdc.lsn_time_mapping) > @max_lsn)
BEGIN

	SELECT @min_lsn AS CheckMinLSN, @max_lsn AS CheckMaxLSN

	IF EXISTS (SELECT * FROM cdc.dbo_Posts_CT WHERE [__$start_lsn] BETWEEN @min_lsn AND @max_lsn)
	BEGIN

		SELECT *
		FROM cdc.fn_cdc_get_all_changes_dbo_Posts(@min_lsn, @max_lsn, N'all');

		SELECT @@rowcount AS PostChanges
	END

	IF EXISTS (SELECT * FROM cdc.dbo_Users_CT WHERE [__$start_lsn] BETWEEN @min_lsn AND @max_lsn)
	BEGIN	
		SELECT *
		FROM cdc.fn_cdc_get_net_changes_dbo_Users(@min_lsn, @max_lsn, N'all');
		
		SELECT @@rowcount AS UserChanges
	END

	-- set the new values
	SELECT @min_lsn = @max_lsn
	
	SELECT @datetime = tran_begin_time
	FROM cdc.lsn_time_mapping
	WHERE start_lsn = @max_lsn
	
	SELECT TOP 1 @max_lsn = start_lsn
	FROM cdc.lsn_time_mapping
	WHERE tran_begin_time > DATEADD(SECOND, 15, @datetime)

END

GO

