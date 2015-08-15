USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[MRExceptionDetail]    Script Date: 8/13/2015 4:45:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[MRExceptionDetail](
	[id] [bigint] NULL,
	[source] [char](1) NULL,
	[exceptionType] [int] NULL,
	[date] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

