USE StackOverflow_CDC
GO

/* See if I'm here yet */
SELECT * FROM dbo.users
WHERE DisplayName = 'Deb the DBA';

/* add me */
IF NOT EXISTS 
    (
    SELECT * FROM dbo.users
    WHERE DisplayName = 'Deb the DBA'
    )
INSERT INTO dbo.Users
(
    AboutMe,
    CreationDate,
    DisplayName,
    DownVotes,
    LastAccessDate,
    Location,
    Reputation,
    UpVotes,
    Views
)
VALUES
(   'Hi I''m Deb the DBA',      -- AboutMe - nvarchar(max)
    GETDATE(), -- CreationDate - datetime
    N'Deb the DBA',       -- DisplayName - nvarchar(40)
    0,         -- DownVotes - int
    GETDATE(), -- LastAccessDate - datetime
    'SQLCON',  -- Location - nvarchar(100)
    0,         -- Reputation - int
    0,         -- UpVotes - int
    0         -- Views - int
    );

WAITFOR DELAY '00:00:05.000'
GO

/* 
Check the table that contains all of the CDC changes.
There will be one of these tables created for every table tracked
*/
SELECT * FROM cdc.dbo_Users_CT;


/* Show some updates */
UPDATE dbo.Users
    SET Reputation = 100, -- 100
        AboutMe = 'Update 1: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET UpVotes = 1000, -- 1,000
        AboutMe = 'Update 2: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET Views = 100000, -- 100,000
        AboutMe = 'Update 3: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET LastAccessDate = GETDATE(),
        AboutMe = 'Update 4: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

/* waiting a second for the polling proc to work */
WAITFOR DELAY '00:00:05.000'
GO

-- Look at the changes:
SELECT * FROM cdc.dbo_Users_CT;



BEGIN TRANSACTION MultipleUpdates

UPDATE dbo.Users
    SET LastAccessDate = GETDATE(),
        AboutMe = 'Update 5: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET Reputation = 1000, -- 1,000
        AboutMe = 'Update 6: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET UpVotes = 10000, -- 10,000
        AboutMe = 'Update 7: I''m Deb the DBA' -- 10,000
WHERE DisplayName = 'Deb the DBA';

UPDATE dbo.Users
    SET Views = 1000000,  -- 1,000,000
        AboutMe = 'Update 8: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA';

WAITFOR DELAY '00:00:05.000'
GO
-- Before we complete the transaction
SELECT * FROM cdc.dbo_Users_CT;

-- now commit
COMMIT TRANSACTION MultipleUpdates

WAITFOR DELAY '00:00:05.000'

-- check again
SELECT * FROM cdc.dbo_Users_CT

/**********************************/
-- show differences between all & net with different options with each

DECLARE 
	@min_lsn BINARY(10),	-- holds the min LSN to say when we start getting values from
	@max_lsn BINARY(10)

/* Set the starting date & min_lsn */
SELECT @min_lsn = min([__$start_lsn]),
	@max_lsn = max([__$start_lsn])
FROM cdc.dbo_Users_CT
	
--SELECT @min_lsn, @max_lsn

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Users(@min_lsn, @max_lsn, N'all')
ORDER BY [__$start_lsn];

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Users(@min_lsn, @max_lsn, N'all update old')
ORDER BY [__$start_lsn];

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(@min_lsn, @max_lsn, N'all')
ORDER BY [__$start_lsn];

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(@min_lsn, @max_lsn, N'all with merge')
ORDER BY [__$start_lsn];

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(@min_lsn, @max_lsn, N'all with mask')
ORDER BY [__$start_lsn];





-- get the lsns from one of the changes and manually run a net change function

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(0x000000350000C0580003, 0x000000350000C0A80001, N'all with merge')
ORDER BY [__$start_lsn];

SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(0x000000350000C0580003, 0x000000350000C0A80001, N'all with mask')
ORDER BY [__$start_lsn];

/* Delete me */
DELETE FROM dbo.users
WHERE DisplayName = 'Deb the DBA';

-- check again
SELECT * FROM cdc.dbo_Users_CT;
GO

/** Check using the net changes function **/
DECLARE 
	@min_lsn BINARY(10),	-- holds the min LSN to say when we start getting values from
	@max_lsn BINARY(10)

/* Set the starting date & min_lsn */
SELECT @min_lsn = min([__$start_lsn]),
	@max_lsn = max([__$start_lsn])
FROM cdc.dbo_Users_CT
	
SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_Users(@min_lsn, @max_lsn, N'all')
ORDER BY [__$start_lsn];
GO