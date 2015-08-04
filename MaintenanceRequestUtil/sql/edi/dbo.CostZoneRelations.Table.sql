USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[CostZoneRelations]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CostZoneRelations](
	[CostZoneRelationID] [int] NOT NULL,
	[StoreID] [int] NOT NULL,
	[SupplierID] [int] NOT NULL,
	[CostZoneID] [int] NOT NULL
) ON [PRIMARY]
GO
INSERT [dbo].[CostZoneRelations] ([CostZoneRelationID], [StoreID], [SupplierID], [CostZoneID]) VALUES (1944, 40460, 40570, 1781);