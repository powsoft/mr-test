USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[Chain_Supplier_CrossReference]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Chain_Supplier_CrossReference](
	[ChainID] [int] NULL,
	[ChainIdentifier] [varchar](50) NULL,
	[SBTSupplierID] [int] NULL,
	[SBTSupplierIdentifier] [varchar](50) NULL,
	[SBTSupplierEdiName] [varchar](50) NULL,
	[RegSupplierID] [int] NULL,
	[RegSupplierIdentifier] [varchar](50) NULL,
	[SBTReceiveFormatFromChain] [varchar](50) NULL,
	[SBTReceiveWayFromChain] [varchar](50) NULL,
	[SBTVendorUsedByChain] [varchar](50) NULL,
	[SBTReceiveFormatFromSupplier] [varchar](50) NULL,
	[SBTReceiveWayFromSupplier] [varchar](50) NULL,
	[SBTVendorUsedBySupplier] [varchar](50) NULL,
	[SBTSendFormatToChain] [varchar](50) NULL,
	[SBTSendWayToChain] [varchar](50) NULL,
	[RegRecieveFormat] [varchar](50) NULL,
	[RegRecieveWay] [varchar](50) NULL,
	[RegVendorUsed] [varchar](50) NULL,
	[SBTsendFormatToSupplier] [varchar](50) NULL,
	[SBTSendWayToSupplier] [varchar](50) NULL,
	[SBTSendVendorUsed] [nchar](10) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
