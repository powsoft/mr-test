USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[MRException]    Script Date: 8/13/2015 4:46:24 PM ******/
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

SET ANSI_PADDING OFF
GO

