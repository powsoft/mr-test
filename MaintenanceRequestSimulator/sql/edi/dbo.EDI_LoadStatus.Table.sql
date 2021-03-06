USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[EDI_LoadStatus]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EDI_LoadStatus](
	[PartnerID] [nchar](20) NOT NULL,
	[FileName] [nchar](100) NOT NULL,
	[LoadStatus] [int] NOT NULL,
	[ExceptionID] [int] NULL,
	[TotalRecordsLoaded] [int] NULL,
	[DateLoaded] [datetime] NOT NULL,
	[PartnerType] [smallint] NULL,
	[TotalQty] [nchar](30) NULL,
	[ISAControlNumber] [nchar](15) NULL,
	[FileType] [nchar](20) NULL,
	[Chain] [nchar](20) NOT NULL,
	[Map] [nchar](20) NULL,
	[Banner] [nchar](6) NULL,
	[EmailSent] [smallint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EDI_LoadStatus] ADD  CONSTRAINT [DF_EDI_LoadStatus_EmailSent]  DEFAULT ((0)) FOR [EmailSent]
GO
INSERT [dbo].[EDI_LoadStatus] ([PartnerID], [FileName], [LoadStatus], [ExceptionID], [TotalRecordsLoaded], [DateLoaded], [PartnerType], [TotalQty], [ISAControlNumber], [FileType], [Chain], [Map], [Banner], [EmailSent]) VALUES (N'3RIVRDIST           ', N'THREELAKES.PDI.888.09212014233612.3852_20140922_13922AM.X12                                         ', 1, 0, 30, CAST(0x0000A41E00000000 AS DateTime), 2, NULL, N'000000003      ', N'NewItem             ', N'0                   ', N'888_ACH             ', N'      ', 0);