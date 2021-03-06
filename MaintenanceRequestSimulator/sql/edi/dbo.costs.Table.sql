USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[costs]    Script Date: 06/25/2015 19:06:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[costs](
	[RecordID] [int] IDENTITY(2333259,1) NOT NULL,
	[PartnerIdentifier] [nchar](20) NULL,
	[PartnerName] [nchar](60) NULL,
	[PartnerDuns] [nchar](30) NULL,
	[PartnerAddress] [nchar](80) NULL,
	[PartnerCity] [nchar](80) NULL,
	[PartnerState] [nchar](10) NULL,
	[PartnerZip] [nchar](15) NULL,
	[PriceChangeCode] [nchar](2) NULL,
	[Banner] [nvarchar](50) NULL,
	[StoreIdentifier] [nchar](50) NULL,
	[StoreName] [nchar](80) NULL,
	[StoreAddress] [nchar](80) NULL,
	[StoreCity] [nchar](80) NULL,
	[StoreState] [nchar](10) NULL,
	[StoreZip] [nchar](15) NULL,
	[PricingMarket] [nchar](10) NULL,
	[AllStores] [nchar](10) NULL,
	[Cost] [float] NULL,
	[SuggRetail] [nchar](10) NULL,
	[RawProductIdentifier] [nchar](15) NULL,
	[ProductIdentifier] [nchar](15) NULL,
	[ProductName] [nchar](200) NULL,
	[ProcessDate] [nchar](15) NULL,
	[ProcessTime] [nchar](15) NULL,
	[EffectiveDate] [datetime] NULL,
	[EndDate] [nchar](15) NULL,
	[FirstOrderDate] [nchar](15) NULL,
	[FirstShipDate] [nchar](15) NULL,
	[FirstArrivalDate] [nchar](15) NULL,
	[MarketAccount] [nchar](10) NULL,
	[MarketAccountDescription] [nchar](100) NULL,
	[PriceBracket] [nchar](10) NULL,
	[UOM] [nchar](10) NULL,
	[PrePriced] [nchar](10) NULL,
	[Qty] [nchar](10) NULL,
	[StoreNumber] [nchar](10) NULL,
	[unitweight] [nchar](10) NULL,
	[weightqualifier] [nchar](10) NULL,
	[weightunitcode] [nchar](10) NULL,
	[FileName] [varchar](1000) NULL,
	[DateCreated] [nchar](30) NOT NULL,
	[PriceListNumber] [nchar](20) NULL,
	[RecordStatus] [smallint] NOT NULL,
	[dtchainid] [int] NULL,
	[dtstoreid] [int] NULL,
	[dtproductid] [int] NULL,
	[dtbrandid] [int] NULL,
	[dtsupplierid] [int] NULL,
	[dtbanner] [nvarchar](50) NULL,
	[dtstorecontexttypeid] [smallint] NULL,
	[dtmaintenancerequestid] [int] NULL,
	[Recordsource] [nvarchar](50) NULL,
	[SentToRetailer] [smallint] NULL,
	[DateSentToRetailer] [datetime] NULL,
	[dtcostzoneid] [int] NULL,
	[TempNeedToSend] [bit] NOT NULL,
	[dtpromoallowance] [money] NULL,
	[ProductNameReceived] [nvarchar](100) NULL,
	[Deleted] [bit] NULL,
	[ApprovalDateTime] [datetime] NULL,
	[Approved] [bit] NULL,
	[BrandIdentifier] [nvarchar](50) NULL,
	[ChainLoginID] [int] NULL,
	[CurrentSetupCost] [money] NULL,
	[datetimecreated] [datetime] NULL,
	[DealNumber] [nvarchar](50) NULL,
	[DeleteDateTime] [datetime] NULL,
	[DeleteLoginId] [int] NULL,
	[DeleteReason] [nvarchar](150) NULL,
	[DenialReason] [nvarchar](150) NULL,
	[EmailGeneratedToSupplier] [nvarchar](50) NULL,
	[EmailGeneratedToSupplierDateTime] [datetime] NULL,
	[RequestStatus] [smallint] NULL,
	[RequestTypeID] [smallint] NULL,
	[Skip_879_889_Conversion_ProcessCompleted] [int] NULL,
	[SkipPopulating879_889Records] [bit] NULL,
	[SubmitDateTime] [datetime] NULL,
	[SupplierLoginID] [int] NULL,
	[ProductCategory] [nvarchar](50) NULL,
	[ActualEffectiveDateSent] [datetime] NULL,
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
	[SellablePackageQty] [int] NULL,
	[AltSellPackage1] [nvarchar](50) NULL,
	[AltSellPackage1Qty] [int] NULL,
	[AltSellPackage1UPC] [nvarchar](50) NULL,
	[AltSellPackage1Retail] [money] NULL,
	[AltSellPackage2] [varchar](50) NULL,
	[AltSellPackage2Qty] [int] NULL,
	[AltSellPackage2UPC] [varchar](50) NULL,
	[AltSellPackage2Retail] [money] NULL,
	[AltSellPackage3] [varchar](50) NULL,
	[AltSellPackage3Qty] [int] NULL,
	[AltSellPackage3UPC] [varchar](50) NULL,
	[AltSellPackage3Retail] [money] NULL,
	[PDIParticipant] [bit] NULL,
	[OldUPC] [nvarchar](50) NULL,
	[InvoiceNo] [nvarchar](50) NULL,
	[StoreDuns] [nvarchar](50) NULL,
	[OldVIN] [nvarchar](50) NULL,
	[OldVINDescription] [nvarchar](255) NULL,
	[ReplaceUPC] [bit] NULL,
	[StoreGLN] [nvarchar](50) NULL,
	[SupplierIdentifier] [nvarchar](50) NULL,
	[ChainIdentifier] [nvarchar](50) NULL,
	[ProductIdentifierType] [nvarchar](50) NULL,
	[Bipad] [nvarchar](50) NULL,
	[OwnerMarketID] [nvarchar](50) NULL,
	[SupplierPackageID] [int] NULL,
	[FileType] [nchar](20) NULL,
	[GTIN] [varchar](50) NULL,
	[SyncToRetailer] [bit] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_RecordStatus]  DEFAULT ((0)) FOR [RecordStatus]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_SentToRetailer]  DEFAULT ((0)) FOR [SentToRetailer]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_TempNeedToSend]  DEFAULT ((0)) FOR [TempNeedToSend]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF__Costs__datetimec__2CC95C04]  DEFAULT (getdate()) FOR [datetimecreated]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_PDIParticipant]  DEFAULT ((0)) FOR [PDIParticipant]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF_Costs_ReplaceUPC]  DEFAULT ((0)) FOR [ReplaceUPC]
GO
ALTER TABLE [dbo].[costs] ADD  CONSTRAINT [DF__Costs__SyncToRet__3987FB5E]  DEFAULT ((0)) FOR [SyncToRetailer]
GO
