USE [DataTrue_Main]
GO

/****** Object:  Table [dbo].[NOT_updated_Promotions]    Script Date: 08/15/2015 15:51:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[NOT_updated_Promotions](
	[RecordID] [int] NOT NULL,
	[SupplierIdentifier] [nchar](20) NULL,
	[DateStartPromotion] [datetime] NULL,
	[DateEndPromotion] [datetime] NULL,
	[PromotionStatus] [nchar](10) NULL,
	[PromotionNumber] [nchar](30) NULL,
	[MarketAreaCodeIdentifier] [nchar](10) NULL,
	[MarketAreaCode] [nchar](10) NULL,
	[UnitSize] [nchar](15) NULL,
	[VendorName] [nchar](80) NULL,
	[VendorDuns] [nchar](15) NULL,
	[Note] [nchar](50) NULL,
	[StoreName] [nchar](80) NULL,
	[StoreDuns] [nchar](15) NULL,
	[StoreNumber] [nchar](10) NULL,
	[ProductName] [nchar](200) NULL,
	[Allowance_ChargeCode] [nchar](10) NULL,
	[Allowance_ChargeMethod] [nchar](10) NULL,
	[Allowance_ChargeRate] [nchar](10) NULL,
	[Allowance_ChargeMeasureCode] [nchar](10) NULL,
	[RawProductIdentifier] [nchar](20) NULL,
	[ProductIdentifier] [nchar](20) NULL,
	[ExceptionNumber] [int] NULL,
	[GroupNumber] [nchar](15) NULL,
	[FileName] [varchar](1000) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[Loadstatus] [smallint] NOT NULL,
	[chainid] [int] NULL,
	[productid] [int] NULL,
	[brandid] [int] NULL,
	[supplierid] [int] NULL,
	[storeid] [int] NULL,
	[banner] [nvarchar](50) NULL,
	[CorpIdentifier] [nchar](30) NULL,
	[CorporateName] [nchar](80) NULL,
	[SupplierName] [nchar](100) NULL,
	[StoreIdentifier] [nchar](30) NULL,
	[StoreSBTNumber] [nvarchar](50) NULL,
	[dtstorecontexttypeid] [smallint] NULL,
	[dtcostzoneid] [int] NULL,
	[dtmaintenancerequestid] [int] NULL,
	[Recordsource] [nvarchar](50) NULL,
	[dtbanner] [nvarchar](50) NULL,
	[SentToRetailer] [smallint] NOT NULL,
	[DateSentToRetailer] [datetime] NULL,
	[ControlNumber] [nvarchar](20) NULL,
	[TempNeedToSend] [bit] NOT NULL,
	[Restored] [smallint] NULL,
	[ProductNameReceived] [nvarchar](100) NULL,
	[Approved] [tinyint] NULL,
	[ApprovalDateTime] [datetime] NULL,
	[AllStores] [tinyint] NULL,
	[BrandIdentifier] [nvarchar](50) NULL,
	[ChainLoginID] [int] NULL,
	[Cost] [money] NULL,
	[CurrentSetupCost] [money] NULL,
	[DealNumber] [nvarchar](50) NULL,
	[DeleteDateTime] [datetime] NULL,
	[DeleteLoginId] [int] NULL,
	[DeleteReason] [nvarchar](800) NULL,
	[DenialReason] [nvarchar](150) NULL,
	[EmailGeneratedToSupplier] [nvarchar](50) NULL,
	[EmailGeneratedToSupplierDateTime] [datetime] NULL,
	[MarkDeleted] [tinyint] NULL,
	[RequestStatus] [smallint] NULL,
	[RequestTypeID] [smallint] NULL,
	[Skip_879_889_Conversion_ProcessCompleted] [int] NULL,
	[SkipPopulating879_889Records] [bit] NULL,
	[SubmitDateTime] [datetime] NULL,
	[SuggestedRetail] [money] NULL,
	[SupplierLoginID] [int] NULL,
	[PrimaryGroupLevel] [int] NULL,
	[AlternateGroupLevel] [int] NULL,
	[ItemGroup] [nvarchar](50) NULL,
	[AlternateItemGroup] [nvarchar](50) NULL,
	[Size] [nvarchar](50) NULL,
	[ManufacturerIdentifier] [nvarchar](50) NULL,
	[SellPkgVINAllowReorder] [nvarchar](50) NULL,
	[SellPkgVINAllowReClaim] [nvarchar](50) NULL,
	[PrimarySellablePkgIdentifier] [nvarchar](50) NULL,
	[VIN] [nvarchar](50) NULL,
	[VINDescription] [nvarchar](255) NULL,
	[PurchPackDescription] [nvarchar](255) NULL,
	[PurchPackQty] [int] NULL,
	[AltSellPackage1] [nvarchar](50) NULL,
	[AltSellPackage1Qty] [int] NULL,
	[AltSellPackage1UPC] [nvarchar](50) NULL,
	[AltSellPackage1Retail] [money] NULL,
	[PDIParticipant] [bit] NULL,
	[OwnerMarketID] [nvarchar](50) NULL,
	[insertTimefromCOST] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

