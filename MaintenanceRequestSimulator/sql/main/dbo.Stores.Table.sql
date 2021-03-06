USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[Stores]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stores](
	[StoreID] [int] NOT NULL,
	[ChainID] [int] NOT NULL,
	[StoreName] [nvarchar](50) NOT NULL,
	[StoreIdentifier] [nvarchar](50) NOT NULL,
	[ActiveFromDate] [datetime] NOT NULL,
	[ActiveLastDate] [datetime] NOT NULL,
	[Comments] [nvarchar](500) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
	[EconomicLevel] [smallint] NOT NULL,
	[StoreSize] [smallint] NOT NULL,
	[Custom1] [nvarchar](50) NOT NULL,
	[Custom2] [nvarchar](50) NULL,
	[Custom3] [nvarchar](50) NULL,
	[DunsNumber] [nvarchar](50) NULL,
	[Custom4] [nvarchar](50) NULL,
	[GopherStoreName] [nvarchar](50) NULL,
	[SBTNumber] [nvarchar](50) NULL,
	[GroupNumber] [nvarchar](50) NULL,
	[ActiveStatus] [nvarchar](10) NOT NULL,
	[ClassOfTrade] [nvarchar](50) NULL,
	[LegacySystemStoreIdentifier] [nvarchar](50) NULL
) ON [PRIMARY]
GO
INSERT [dbo].[Stores] ([StoreID], [ChainID], [StoreName], [StoreIdentifier], [ActiveFromDate], [ActiveLastDate], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [EconomicLevel], [StoreSize], [Custom1], [Custom2], [Custom3], [DunsNumber], [Custom4], [GopherStoreName], [SBTNumber], [GroupNumber], [ActiveStatus], [ClassOfTrade], [LegacySystemStoreIdentifier]) VALUES (272, 3, N'CVS STORE 1267', N'1267', CAST(0x00009E5E00000000 AS DateTime), CAST(0x0000B25800000000 AS DateTime), NULL, CAST(0x00009EAE012E5EA6 AS DateTime), N'2', CAST(0x00009EAE012E5EA6 AS DateTime), 5, 5, N'', NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'Active', NULL, N'Sample 21267');