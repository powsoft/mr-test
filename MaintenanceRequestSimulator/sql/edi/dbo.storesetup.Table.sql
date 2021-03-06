USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[storesetup]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[storesetup](
	[StoreSetupID] [int] IDENTITY(1,1) NOT NULL,
	[ChainID] [int] NOT NULL,
	[StoreID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SupplierID] [int] NOT NULL,
	[BrandID] [int] NOT NULL,
	[InventoryRuleID] [int] NULL,
	[InventoryCostMethod] [nvarchar](50) NULL,
	[SunLimitQty] [int] NULL,
	[SunFrequency] [int] NULL,
	[MonLimitQty] [int] NULL,
	[MonFrequency] [int] NULL,
	[TueLimitQty] [int] NULL,
	[TueFrequency] [int] NULL,
	[WedLimitQty] [int] NULL,
	[WedFrequency] [int] NULL,
	[ThuLimitQty] [int] NULL,
	[ThuFrequency] [int] NULL,
	[FriLimitQty] [int] NULL,
	[FriFrequency] [int] NULL,
	[SatLimitQty] [int] NULL,
	[SatFrequency] [int] NULL,
	[RetailerShrinkPercent] [tinyint] NOT NULL,
	[SupplierShrinkPercent] [tinyint] NOT NULL,
	[ManufacturerShrinkPercent] [tinyint] NOT NULL,
	[ActiveStartDate] [datetime] NOT NULL,
	[ActiveLastDate] [datetime] NOT NULL,
	[SetupReportedToRetailerDate] [smalldatetime] NULL,
	[FileName] [nvarchar](100) NULL,
	[Comments] [nvarchar](50) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
	[IncludeInForwardTransactions] [bit] NOT NULL,
	[PDIParticipant] [bit] NULL
) ON [PRIMARY]
GO
