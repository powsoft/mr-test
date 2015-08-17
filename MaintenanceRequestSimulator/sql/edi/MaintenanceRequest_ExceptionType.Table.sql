USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[MRException]    Script Date: 8/17/2015 12:31:59 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[MRException](
	[id] [bigint] NULL,
	[description] [varchar](155) NULL,
	[severity] [nchar](10) NULL,
	[notify] [nchar](10) NULL
) ON [PRIMARY]

GO

INSERT INTO [dbo].[MRException]
           ([id]
           ,[description]
           ,[severity]
           ,[notify])
     VALUES
           (1
           ,'Missing Chain ID'
           ,10
           ,0);

INSERT INTO [dbo].[MRException]
           ([id]
           ,[description]
           ,[severity]
           ,[notify])
     VALUES
           (2
           ,'Missing Supplier ID'
           ,10
           ,0);
GO



SET ANSI_PADDING OFF
GO



