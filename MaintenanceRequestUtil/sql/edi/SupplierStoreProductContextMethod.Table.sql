USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[SupplierStoreProductContextMethod]    Script Date: 08/15/2015 17:55:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[SupplierStoreProductContextMethod](
	[recordID] [int] NOT NULL,
	[ChainId] [int] NOT NULL,
	[SupplierId] [int] NOT NULL,
	[StoreProductContextMethod] [varchar](50) NOT NULL,
	[LastUpdateUserID] [int] NOT NULL,
	[DateTimeCreated] [date] NOT NULL,
	[DateTimeLastUpdate] [date] NOT NULL,
	[UniqueEDIName] [nvarchar](50) NULL,
	[BannerName] [varchar](150) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


