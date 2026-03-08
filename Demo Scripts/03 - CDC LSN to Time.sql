
/* https://learn.microsoft.com/en-us/sql/relational-databases/system-functions/change-data-capture-functions-transact-sql?view=sql-server-ver17 */

-- Enumerate All Changes for Valid Range Template
USE StackOverflow_CDC;
GO

DECLARE @from_lsn AS BINARY (10), @to_lsn AS BINARY (10);
SET @from_lsn = sys.fn_cdc_get_min_lsn('dbo_Users'); -- schema_table
SET @to_lsn = sys.fn_cdc_get_max_lsn();


SELECT @from_lsn AS From_LSN, 
    sys.fn_cdc_map_lsn_to_time(@from_lsn) AS From_LSN_Time,  
    @to_lsn AS To_LSN, 
    sys.fn_cdc_map_lsn_to_time(@to_lsn) AS To_LSN_Time



-- How can I find out the LSN for the ranges?
DECLARE @begin_time DATETIME,
    @end_time DATETIME,
    @begin_lsn BINARY (10),
    @end_lsn BINARY (10);

SET @begin_time = '2026-01-13 12:00:00.000';
SET @end_time = GETDATE();

SELECT @begin_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than', @begin_time);

SELECT @end_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal', @end_time);

SELECT @begin_time AS Begin_Time, 
    @begin_lsn AS Begin_Time_LSN, 
    sys.fn_cdc_map_lsn_to_time(@begin_lsn) AS Actual_Begin_LSN_Time,
    @end_time AS End_Time, 
    @end_lsn AS End_Time_LSN, 
    sys.fn_cdc_map_lsn_to_time(@end_lsn) AS Actual_End_LSN_Time
GO

