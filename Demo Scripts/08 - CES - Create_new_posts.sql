USE StackOverflow_CES
GO

/*
Posts will be added in one at a time 
because that's closer to how it would be through the app since we wouldn't be doing things one by one.

Creating a proc for this process
*/


CREATE OR ALTER PROCEDURE demosetup.AddPosts
	@DayOfMonth TINYINT = NULL, -- choose a day of the month to use as the base
	@timerInMinutes TINYINT = 5, -- how long to run the proc for
	@debug BIT	= 0
AS 
BEGIN

SET NOCOUNT ON 

/*
Create a temp table for the new id and new CreationDate for the new LastActivityDate
*/
CREATE TABLE #Updates
(
	OldPostID	INT,
	NewPostID	INT,
	ActivityDate	DATETIME
)

/*
steps for adding in posts, done in a loop
- add post with modified values
*/

-- initial insert. we'll update later
DECLARE @mappingid INT,
	@body NVARCHAR(MAX),
	@communityowneddate DATETIME,
	@creationdate DATETIME,
	@lastactivitydate DATETIME,
	@ownerUserID INT,
	@parentid INT,
	@posttypeid INT,
	@score INT,
	@tags NVARCHAR(150),
	@title NVARCHAR(250),
	@NewAAPostID INT, 
	@ParentNewPostID INT

/* turn into a cursor so all the values being inserted into the table are variables, as if from code */
DECLARE post_cursor SCROLL CURSOR FOR 
SELECT np.NewPostMappingID AS MappingId, 
       op.Body,
       DATEADD(YEAR, 4, op.CommunityOwnedDate) AS CommunityOwnedDate, 
       DATEADD(YEAR, 4, op.CreationDate) AS CreationDate,
       DATEADD(YEAR, 4, op.CreationDate) AS LastActivityDate,
       op.OwnerUserId,
       CASE WHEN op.ParentID = 0 
		THEN NULL 
		ELSE op.ParentID
	   END	AS ParentId,
       op.PostTypeId,
       op.Score,
       op.Tags,
       op.Title
FROM demosetup.Posts AS op
	JOIN demosetup.NewPostMapping AS np ON op.OldPostId = np.OldPostID
	LEFT JOIN demosetup.NewPostMapping AS aa ON op.ParentId = aa.OldPostID
WHERE np.NewPostID IS NULL
AND DATEPART(DAY, op.CreationDate) = ISNULL(@DayOfMonth, DATEPART(DAY, op.CreationDate))


OPEN post_cursor

FETCH FIRST FROM post_cursor INTO 
	@mappingid, @body, @communityowneddate, @creationdate, @lastactivitydate, 
	@ownerUserID, @parentid, @posttypeid, @score, @tags, @title

/* Automatically stop based on time set */

DECLARE @timer DATETIME = GETDATE()
SELECT @timer AS TimerStart

WHILE @@FETCH_STATUS = 0
BEGIN 

	IF NOT EXISTS (SELECT * FROM dbo.Users WHERE Id = @ownerUserID) AND (@ownerUserID IS NOT NULL)
	BEGIN

		-- Get the User ID. Add a user if one does not exist.
		
		IF NOT EXISTS (SELECT * FROM dbo.Users WHERE DisplayName = 'Random User ' + CONVERT(VARCHAR(10), @ownerUserID))
		BEGIN 
			INSERT INTO dbo.Users
			(
				CreationDate,
				DisplayName,
				DownVotes,
				LastAccessDate,
				Reputation,
				UpVotes,
				Views
			)
			SELECT GETDATE(),
				'Random User ' + CONVERT(VARCHAR(10), @ownerUserID),
				0,
				GETDATE(),
				50,
				0,
				1

			IF @debug = 1 
				PRINT 'User added: Random User ' + CONVERT(VARCHAR(10), @ownerUserID) 
		END

		SELECT @ownerUserID = id 
		FROM dbo.Users 
		WHERE DisplayName = 'Random User ' + CONVERT(VARCHAR(10), @ownerUserID)
		
	END

	-- get the new post id
	SELECT @ParentNewPostID = np.NewPostID
	FROM demosetup.NewPostMapping AS np
	WHERE np.OldPostID = @parentid

	-- add the post 
	INSERT INTO dbo.Posts
	(
		AcceptedAnswerId,
		AnswerCount,
		Body,
		ClosedDate,
		CommentCount,
		CommunityOwnedDate,
		CreationDate,
		FavoriteCount,
		LastActivityDate,
		LastEditDate,
		LastEditorDisplayName,
		LastEditorUserId,
		OwnerUserId,
		ParentId,
		PostTypeId,
		Score,
		Tags,
		Title,
		ViewCount
	)
	OUTPUT @mappingid, inserted.id, inserted.CreationDate 
	INTO #Updates (OldPostID, NewPostID, ActivityDate)
	SELECT --op.Id,
		   NULL AS AcceptedAnswerId,
		   0 AS AnswerCount,
		   @body AS Body,
		   NULL ClosedDate,
		   0 AS CommentCount,
		   @communityowneddate AS CommunityOwnedDate, 
		   @creationdate AS CreationDate,
		   0 AS FavoriteCount,
		   @lastactivitydate AS LastActivityDate,
		   NULL AS LastEditDate,
		   NULL AS LastEditorDisplayName,
		   NULL AS LastEditorUserId,
		   @ownerUserID AS OwnerUserId,
		   @ParentNewPostID AS ParentId,
		   @posttypeid AS PostTypeId,
		   @score AS Score,
		   @tags AS Tags,
		   @title AS Title,
		   0 AS ViewCount 	

	IF @debug = 1 
		PRINT 'Post added.'

	/* update mapping table */
	UPDATE np SET np.NewPostID = u.NewPostID
	FROM #Updates AS u
		JOIN demosetup.NewPostMapping AS np ON np.NewPostMappingID = u.OldPostID
	WHERE np.NewPostMappingID = @mappingid

	IF @debug = 1 
		PRINT 'Updated mapping table'

	/*
	-- If the post has a parent id, update the parent post 
		* with ViewCount + 1, 
		* LastActivityDate to the new ActivityDate
	*/

	IF EXISTS (
		SELECT *
		FROM demosetup.NewPostMapping AS p
			JOIN demosetup.NewPostMapping AS aa ON aa.OldAcceptedAnswer = p.OldPostID
		WHERE p.NewPostMappingID = @mappingid
		)
	BEGIN

		/* get the new post id for the accepted answer */
		SELECT @NewAAPostID = NewPostID
		FROM demosetup.NewPostMapping AS p
		WHERE p.NewPostMappingID = @mappingid
		

		/* update the mapping table */
		UPDATE p
		SET p.NewAcceptedAnswer = @NewAAPostID
		FROM demosetup.NewPostMapping AS p 
		WHERE NewPostID = @ParentNewPostID

		/* Update the Posts table */
		UPDATE p
		SET AcceptedAnswerID = @NewAAPostID,
			p.ViewCount = p.ViewCount + 1,
			p.LastActivityDate = @LastActivityDate
		FROM dbo.Posts AS p
		WHERE Id = @ParentNewPostID
		
		IF @debug = 1 
			PRINT 'Updated Post table with accepted answer'


	END
	ELSE
	BEGIN

		IF @ParentNewPostID IS NOT NULL
		BEGIN
			UPDATE p
			SET p.ViewCount = p.ViewCount + 1,
				p.LastActivityDate = @LastActivityDate
			FROM dbo.Posts AS p
			WHERE Id = @ParentNewPostID

			IF @debug = 1 
				PRINT 'Updated parent post update view count'
		END

	END

	-- reset for the next round
	TRUNCATE TABLE #updates
	SELECT @NewAAPostID = NULL, @ParentNewPostID = NULL

	IF DATEDIFF(SECOND, @timer, GETDATE()) > (60 * @timerInMinutes) -- 60 seconds per minute * number of minutes 
	BEGIN
		SELECT 'Stopping process after ' + CONVERT(VARCHAR(3), @timerInMinutes) + ' minutes. Time ended: ' + CONVERT(VARCHAR(40), GETDATE(), 121)
		BREAK 

	END
	ELSE 
	BEGIN
		FETCH NEXT FROM post_cursor INTO 
			@mappingid, @body, @communityowneddate, @creationdate, @lastactivitydate, 
			@ownerUserID, @parentid, @posttypeid, @score, @tags, @title
	END
END

CLOSE post_cursor
DEALLOCATE post_cursor


SET NOCOUNT OFF 

END
GO

/* Execute the proc */

EXEC demosetup.AddPosts @timerInMinutes = 1
GO