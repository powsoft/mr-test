USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[CostZone_CorporateID_Supplier_Relations]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CostZone_CorporateID_Supplier_Relations](
	[CostZoneID] [int] NULL,
	[StoreDuns] [varchar](20) NULL,
	[SupplierIdentifier] [varchar](20) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[CostZone_CorporateID_Supplier_Relations] ([CostZoneID], [StoreDuns], [SupplierIdentifier]) VALUES (1767, N'0032326880002', N'NST')
