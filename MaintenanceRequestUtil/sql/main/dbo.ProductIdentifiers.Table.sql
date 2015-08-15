USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[ProductIdentifiers]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductIdentifiers](
        [ProductID] [int] NOT NULL,
        [ProductIdentifierTypeID] [int] NOT NULL,
        [OwnerEntityId] [int] NOT NULL,
        [IdentifierValue] [nvarchar](50) NOT NULL,
        [Bipad] [nvarchar](50) NULL,
        [Priority] [smallint] NULL,
        [Comments] [nvarchar](500) NULL,
        [DateTimeCreated] [datetime] NOT NULL,
        [LastUpdateUserID] [nvarchar](50) NOT NULL,
        [DateTimeLastUpdate] [datetime] NOT NULL,
        [ContextProductDescription] [nvarchar](255) NULL,
        [SupplierPackageID] [int] NULL
) ON [PRIMARY]
GO

INSERT [dbo].[ProductIdentifiers] ([ProductID], [ProductIdentifierTypeID], [OwnerEntityId], [IdentifierValue], [Bipad], [Priority], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [ContextProductDescription], [SupplierPackageID]) VALUES (179, 2, 0, N'026832100053', NULL, NULL, NULL, CAST(0x00009EBA00E4A968 AS DateTime), N'7417', CAST(0x00009EBA00E4A968 AS DateTime), NULL, NULL);