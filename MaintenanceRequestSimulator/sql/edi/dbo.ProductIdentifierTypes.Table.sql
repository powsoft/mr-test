USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[ProductIdentifierTypes]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductIdentifierTypes](
	[ProductIdentifierTypeID] [int] IDENTITY(1,1) NOT NULL,
	[ProductIdentifierTypeName] [nvarchar](50) NOT NULL,
	[ProductIdentifierDescription] [nvarchar](500) NOT NULL,
	[Comments] [nvarchar](500) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[ProductIdentifierTypes] ON
INSERT [dbo].[ProductIdentifierTypes] ([ProductIdentifierTypeID], [ProductIdentifierTypeName], [ProductIdentifierDescription], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (1, N'SKU', N'Stock Keeping Unit Identifier', NULL, CAST(0x00009E9300D53929 AS DateTime), N'2', CAST(0x00009E9300D53929 AS DateTime))
INSERT [dbo].[ProductIdentifierTypes] ([ProductIdentifierTypeID], [ProductIdentifierTypeName], [ProductIdentifierDescription], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (2, N'UPC', N'UPC', NULL, CAST(0x00009E9300DE8686 AS DateTime), N'2', CAST(0x00009E9300DE8686 AS DateTime))
SET IDENTITY_INSERT [dbo].[ProductIdentifierTypes] OFF
