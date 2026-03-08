USE StackOverflow_CDC
GO


CREATE SCHEMA demosetup;
GO


CREATE TABLE demosetup.NewPostMapping 
(
	NewPostMappingID INT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_NewPostMapping PRIMARY KEY CLUSTERED,
	OldPostID	INT NOT NULL,
	OldAcceptedAnswer INT NULL,
	NewPostID	INT NULL,
	NewAcceptedAnswer INT NULL
);


CREATE TABLE demosetup.[Posts](
	[OldPostId] [int] NOT NULL,
	[AcceptedAnswerId] [int] NULL,
	[AnswerCount] [int] NULL,
	[Body] [nvarchar](max) NOT NULL,
	[ClosedDate] [datetime] NULL,
	[CommentCount] [int] NULL,
	[CommunityOwnedDate] [datetime] NULL,
	[CreationDate] [datetime] NOT NULL,
	[FavoriteCount] [int] NULL,
	[LastActivityDate] [datetime] NOT NULL,
	[LastEditDate] [datetime] NULL,
	[LastEditorDisplayName] [nvarchar](40) NULL,
	[LastEditorUserId] [int] NULL,
	[OwnerUserId] [int] NULL,
	[ParentId] [int] NULL,
	[PostTypeId] [INT] NOT NULL,
	[Score] [INT] NOT NULL,
	[Tags] [NVARCHAR](150) NULL,
	[Title] [NVARCHAR](250) NULL,
	[ViewCount] [INT] NOT NULL,
	CONSTRAINT [PK_demosetupPosts_Id] PRIMARY KEY CLUSTERED ([OldPostId])
	)  
GO




-- just use January 2010 to recreate the posts.
WITH posts_cte AS
(
	SELECT p.ParentId, ID, CreationDate, p.LastActivityDate, LastEditDate, OwnerUserID, PostTypeID, p.AcceptedAnswerId, -- AS ParentAcceptedAnswer, 
		1 AS PostOrder,
		CONVERT(VARCHAR(MAX), p.ParentId) + '|' + CONVERT(VARCHAR(10),p.Id) AS SortOrder
	FROM StackOverflow2013.dbo.Posts AS p
	WHERE p.ParentId = 0
	AND DATEPART(YEAR, CreationDate) = 2010 --695,144
	AND DATEPART(MONTH, CreationDate) = 1 --302,185

	UNION ALL
	
	SELECT p.ParentId, p.ID, p.CreationDate, p.LastActivityDate, p.LastEditDate, p.OwnerUserID, p.PostTypeID, p.AcceptedAnswerId ,--pc.ParentAcceptedAnswer, 
		pc.PostOrder + 1 AS PostOrder,
		pc.SortOrder + '|' + CONVERT(VARCHAR(10),p.Id) AS SortOrder
	FROM StackOverflow2013.dbo.Posts AS p
		JOIN posts_cte AS pc ON p.ParentId = pc.Id
)
INSERT INTO demosetup.NewPostMapping (OldPostID, OldAcceptedAnswer)
SELECT cte.ID, AcceptedAnswerID
FROM posts_cte AS cte
ORDER BY cte.CreationDate
;



INSERT INTO demosetup.Posts
(	OldPostID,
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
    ViewCount)
SELECT p.ID,
	p.AcceptedAnswerId,
    p.AnswerCount,
    p.Body,
    p.ClosedDate,
    p.CommentCount,
    p.CommunityOwnedDate,
    p.CreationDate,
    p.FavoriteCount,
    p.LastActivityDate,
    p.LastEditDate,
    p.LastEditorDisplayName,
    p.LastEditorUserId,
    p.OwnerUserId,
    p.ParentId,
    p.PostTypeId,
    p.Score,
    p.Tags,
    p.Title,
    p.ViewCount
FROM StackOverflow2013.dbo.Posts AS p
	JOIN demosetup.NewPostMapping AS npm ON npm.OldPostID = p.id;
GO


/* Create the initial backup */
BACKUP DATABASE StackOverflow_CDC to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\StackOverflow_CDC_Initial.bak'
WITH COMPRESSION (ALGORITHM = ZSTD) , stats, init
GO
