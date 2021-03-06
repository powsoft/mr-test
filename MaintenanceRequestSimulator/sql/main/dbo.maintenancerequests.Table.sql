USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[maintenancerequests]    Script Date: 06/25/2015 19:04:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[maintenancerequests](
	[MaintenanceRequestID] [int] IDENTITY(5455439,1) NOT NULL,
	[SubmitDateTime] [datetime] NULL,
	[RequestTypeID] [smallint] NOT NULL,
	[ChainID] [int] NOT NULL,
	[SupplierID] [int] NOT NULL,
	[Banner] [nvarchar](50) NULL,
	[AllStores] [tinyint] NOT NULL,
	[UPC] [nvarchar](50) NOT NULL,
	[BrandIdentifier] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](255) NOT NULL,
	[CurrentSetupCost] [money] NULL,
	[Cost] [money] NOT NULL,
	[SuggestedRetail] [money] NULL,
	[PromoTypeID] [tinyint] NOT NULL,
	[PromoAllowance] [money] NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[EndDateTime] [datetime] NOT NULL,
	[SupplierLoginID] [int] NOT NULL,
	[ChainLoginID] [int] NULL,
	[Approved] [bit] NULL,
	[ApprovalDateTime] [datetime] NULL,
	[DenialReason] [nvarchar](500) NULL,
	[EmailGeneratedToSupplier] [nvarchar](300) NULL,
	[EmailGeneratedToSupplierDateTime] [datetime] NULL,
	[RequestStatus] [smallint] NOT NULL,
	[CostZoneID] [int] NULL,
	[productid] [int] NULL,
	[brandid] [int] NULL,
	[upc12] [nvarchar](50) NULL,
	[datatrue_edi_costs_recordid] [int] NULL,
	[datatrue_edi_promotions_recordid] [int] NULL,
	[dtstorecontexttypeid] [smallint] NULL,
	[TradingPartnerPromotionIdentifier] [nvarchar](50) NULL,
	[MarkDeleted] [tinyint] NULL,
	[DeleteLoginId] [int] NULL,
	[DeleteReason] [nvarchar](500) NULL,
	[DeleteDateTime] [datetime] NULL,
	[datetimecreated] [datetime] NOT NULL,
	[SkipPopulating879_889Records] [bit] NULL,
	[Skip_879_889_Conversion_ProcessCompleted] [int] NULL,
	[dtproductdescription] [nvarchar](255) NULL,
	[DealNumber] [varchar](50) NULL,
	[CorrectedProductID] [int] NULL,
	[FromWebInterface] [bit] NULL,
	[SlottingFees] [numeric](10, 2) NULL,
	[AdFees] [numeric](10, 2) NULL,
	[Bipad] [nvarchar](50) NULL,
	[RequestSource] [nvarchar](10) NULL,
	[RawProductIdentifier] [nvarchar](50) NULL,
	[PDIParticipant] [bit] NOT NULL,
	[OldUPC] [nvarchar](20) NULL,
	[OldUPCDescription] [nvarchar](20) NULL,
	[PrimaryGroupLevel] [int] NULL,
	[AlternateGroupLevel] [int] NULL,
	[ItemGroup] [nvarchar](50) NULL,
	[AlternateItemGroup] [nvarchar](50) NULL,
	[Size] [nvarchar](50) NULL,
	[ManufacturerIdentifier] [nvarchar](50) NULL,
	[SellPkgVINAllowReorder] [nvarchar](50) NULL,
	[SellPkgVINAllowReClaim] [nvarchar](50) NULL,
	[PrimarySellablePkgIdentifier] [nvarchar](50) NULL,
	[PrimarySellablePkgQty] [int] NULL,
	[VIN] [nvarchar](50) NULL,
	[VINDescription] [nvarchar](255) NULL,
	[PurchPackDescription] [nvarchar](255) NULL,
	[PurchPackQty] [int] NULL,
	[AltSellPackage1] [nvarchar](50) NULL,
	[AltSellPackage1Qty] [int] NULL,
	[AltSellPackage1UPC] [nvarchar](50) NULL,
	[AltSellPackage1Retail] [money] NULL,
	[ProductCategoryId] [int] NULL,
	[OldVIN] [nvarchar](50) NULL,
	[OldVINDescription] [nvarchar](50) NULL,
	[InCompliance] [bit] NULL,
	[ReplaceUPC] [bit] NOT NULL,
	[QtyOne] [int] NULL,
	[QtyTwo] [int] NULL,
	[QtyThree] [int] NULL,
	[QtyFour] [int] NULL,
	[QtyFive] [int] NULL,
	[QtySix] [int] NULL,
	[QtySeven] [int] NULL,
	[SupplierIdentifier] [nvarchar](50) NULL,
	[StoreIdentifier] [nvarchar](50) NULL,
	[ChainIdentifier] [nvarchar](50) NULL,
	[ProductIdentifierType] [nvarchar](50) NULL,
	[SupplierPackageID] [int] NULL,
	[OwnerMarketID] [nvarchar](50) NULL,
	[AltSellPackage2UPC] [nvarchar](50) NULL,
	[AltSellPackage3UPC] [nvarchar](50) NULL,
	[AltSellPackage2] [nvarchar](50) NULL,
	[AltSellPackage3] [nvarchar](50) NULL,
	[AltSellPackage2Qty] [int] NULL,
	[AltSellPackage3Qty] [int] NULL,
	[AltSellPackage2Retail] [money] NULL,
	[AltSellPackage3Retail] [money] NULL,
	[Filetype] [nchar](20) NULL,
	[SyncToRetailer] [bit] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_CurrentSetupCost]  DEFAULT ((0)) FOR [CurrentSetupCost]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_PromoTypeID]  DEFAULT ((0)) FOR [PromoTypeID]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_PromoAllowance]  DEFAULT ((0)) FOR [PromoAllowance]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_SupplierLoginID]  DEFAULT ((41708)) FOR [SupplierLoginID]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_RequestStatus]  DEFAULT ((0)) FOR [RequestStatus]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_datetimecreated]  DEFAULT (getdate()) FOR [datetimecreated]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_GopherFlag]  DEFAULT (NULL) FOR [SkipPopulating879_889Records]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_Skip_879_889_Conversion_ProcessCompleted]  DEFAULT (NULL) FOR [Skip_879_889_Conversion_ProcessCompleted]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_PDIParticipant]  DEFAULT ((0)) FOR [PDIParticipant]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_InCompliance]  DEFAULT ((1)) FOR [InCompliance]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF_MaintenanceRequests_ReplaceUPC]  DEFAULT ((0)) FOR [ReplaceUPC]
GO
ALTER TABLE [dbo].[maintenancerequests] ADD  CONSTRAINT [DF__Maintenan__SyncT__66FCF9D2]  DEFAULT ((0)) FOR [SyncToRetailer]
GO
