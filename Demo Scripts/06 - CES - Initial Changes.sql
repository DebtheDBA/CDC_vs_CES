USE StackOverflow_CES
GO


/* See if I'm here  yet */
SELECT * FROM users
WHERE DisplayName = 'Deb the DBA'

IF NOT EXISTS 
    (SELECT * FROM users
    WHERE DisplayName = 'Deb the DBA')
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
    )
GO

/* Look at Event Hubs */

UPDATE dbo.Users
    SET Reputation = 100, -- 100
        AboutMe = 'Update 1: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET UpVotes = 1000, -- 1,000
        AboutMe = 'Update 2: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET Views = 100000, -- 100,000
        AboutMe = 'Update 3: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET LastAccessDate = GETDATE(),
        AboutMe = 'Update 4: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

/* Look at Event Hubs */


BEGIN TRANSACTION MultipleUpdates

UPDATE dbo.Users
    SET LastAccessDate = GETDATE(),
        AboutMe = 'Update 5: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET Reputation = 1000, -- 1,000
        AboutMe = 'Update 6: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET UpVotes = 10000, -- 10,000
        AboutMe = 'Update 7: I''m Deb the DBA' -- 10,000
WHERE DisplayName = 'Deb the DBA'

UPDATE dbo.Users
    SET Views = 1000000,  -- 1,000,000
        AboutMe = 'Update 8: I''m Deb the DBA'
WHERE DisplayName = 'Deb the DBA'

COMMIT TRANSACTION MultipleUpdates

/* Look at Event Hubs */
