USE master
GO

IF NOT EXISTS (
	SELECT *  FROM sys.databases 
	WHERE name =  'StackOverflow_CES'
	)
CREATE DATABASE StackOverflow_CES
GO

USE StackOverflow_CES
GO


CREATE TABLE [dbo].[PostTypes](
	[Id] [INT] IDENTITY(1,1) NOT NULL,
	[Type] [NVARCHAR](50) NOT NULL,
	CONSTRAINT [PK_PostTypes_Id] PRIMARY KEY CLUSTERED ([Id]),
	CONSTRAINT UQ_PostTypes_Type UNIQUE ([Type])
	) 
GO

SET IDENTITY_INSERT dbo.PostTypes ON

INSERT INTO dbo.PostTypes ([Id], [Type])
VALUES
( 2, N'Answer' ),
( 6, N'ModeratorNomination' ),
( 8, N'PrivilegeWiki' ),
( 1, N'Question' ),
( 5, N'TagWiki' ),
( 4, N'TagWikiExerpt' ),
( 3, N'Wiki' ),
( 7, N'WikiPlaceholder' )


SET IDENTITY_INSERT dbo.PostTypes OFF
GO

CREATE TABLE [dbo].[Users](
	[Id] [INT] IDENTITY(1,1) NOT NULL,
	[AboutMe] [NVARCHAR](MAX) NULL,
	[Age] [INT] NULL,
	[CreationDate] [DATETIME] NOT NULL,
	[DisplayName] [NVARCHAR](40) NOT NULL,
	[DownVotes] [INT] NOT NULL,
	[EmailHash] [NVARCHAR](40) NULL,
	[LastAccessDate] [DATETIME] NOT NULL,
	[Location] [NVARCHAR](100) NULL,
	[Reputation] [INT] NOT NULL,
	[UpVotes] [INT] NOT NULL,
	[Views] [INT] NOT NULL,
	[WebsiteUrl] [NVARCHAR](200) NULL,
	[AccountId] [INT] NULL,
	CONSTRAINT [PK_Users_Id] PRIMARY KEY CLUSTERED ([Id]),
	INDEX IDX_Users_DisplayName (DisplayName)
	)  
GO


CREATE TABLE [dbo].[Posts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AcceptedAnswerId] [int] NULL
		CONSTRAINT FK_Posts_AcceptedAnswerPosts FOREIGN KEY REFERENCES dbo.Posts (Id),
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
	[LastEditorUserId] [int] NULL
		CONSTRAINT FK_Posts_LastEditorUsers FOREIGN KEY REFERENCES dbo.Users (Id),
	[OwnerUserId] [int] NULL
		CONSTRAINT FK_Posts_OwnerUsers FOREIGN KEY REFERENCES dbo.Users (Id),
	[ParentId] [int] NULL
		CONSTRAINT FK_Posts_ParentPosts FOREIGN KEY REFERENCES dbo.Posts (Id),
	[PostTypeId] [INT] NOT NULL
		CONSTRAINT FK_Posts_PostTypes FOREIGN KEY REFERENCES dbo.PostTypes (Id),
	[Score] [INT] NOT NULL,
	[Tags] [NVARCHAR](150) NULL,
	[Title] [NVARCHAR](250) NULL,
	[ViewCount] [INT] NOT NULL,
	CONSTRAINT [PK_Posts_Id] PRIMARY KEY CLUSTERED ([Id]),
	INDEX IDX_Posts_AcceptedAnswerId (AcceptedAnswerId),
	INDEX IDX_Posts_LastEditorUserId (LastEditorUserId),
	INDEX IDX_Posts_OwnerUserId (OwnerUserId),
	INDEX IDX_Posts_ParentId (ParentId),
	INDEX IDX_Posts_PostTypeId (PostTypeId),
	INDEX IDX_Posts_CreationDate (CreationDate)
	)  
GO


