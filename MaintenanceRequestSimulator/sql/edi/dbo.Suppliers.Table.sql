USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[Suppliers]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Suppliers](
	[SupplierID] [int] NOT NULL,
	[SupplierName] [nvarchar](255) NOT NULL,
	[SupplierIdentifier] [nvarchar](50) NULL,
	[SupplierDescription] [nvarchar](500) NOT NULL,
	[ActiveStartDate] [datetime] NOT NULL,
	[ActiveLastDate] [datetime] NOT NULL,
	[RegistrationDate] [datetime] NULL,
	[Comments] [nvarchar](50) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
	[DunsNumber] [nvarchar](50) NULL,
	[EDIName] [varchar](50) NULL,
	[SupplierDeliveryIdentifier] [nvarchar](50) NULL,
	[CreateZeroCountRecordsForMissingProductCounts] [bit] NULL,
	[StoreProductContextMethod] [nvarchar](50) NULL,
	[InventoryIsActive] [bit] NULL,
	[UniqueEDIName] [nvarchar](50) NULL,
	[PromotionOverwriteAllowed] [bit] NULL,
	[PDITradingPartner] [bit] NULL,
	[IsRegulated] [bit] NOT NULL,
	[TaxID] [varchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Suppliers] ADD  CONSTRAINT [DF__Suppliers__IsReg__1687772F]  DEFAULT ((1)) FOR [IsRegulated]
GO
INSERT [dbo].[Suppliers] ([SupplierID], [SupplierName], [SupplierIdentifier], [SupplierDescription], [ActiveStartDate], [ActiveLastDate], [RegistrationDate], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [DunsNumber], [EDIName], [SupplierDeliveryIdentifier], [CreateZeroCountRecordsForMissingProductCounts], [StoreProductContextMethod], [InventoryIsActive], [UniqueEDIName], [PromotionOverwriteAllowed], [PDITradingPartner], [IsRegulated], [TaxID]) VALUES (25236, N'The Gaston Gazette', N'WR2907', N'The Gaston Gazette', CAST(0x00009E5E00000000 AS DateTime), CAST(0x0000B3C400000000 AS DateTime), NULL, NULL, CAST(0x00009F3500FDDD9D AS DateTime), N'7606', CAST(0x00009F3500FDDD9D AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL);