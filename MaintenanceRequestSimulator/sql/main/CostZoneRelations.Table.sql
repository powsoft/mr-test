USE [DataTrue_Main]
GO

/****** Object:  Table [dbo].[CostZoneRelations]    Script Date: 08/15/2015 16:58:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CostZoneRelations](
	[CostZoneRelationID] [int] IDENTITY(1,1) NOT NULL,
	[StoreID] [int] NOT NULL,
	[SupplierID] [int] NOT NULL,
	[CostZoneID] [int] NOT NULL,
	[OwnerEntityID] [int] NOT NULL,
 CONSTRAINT [PK_CostZoneRelations] PRIMARY KEY CLUSTERED 
(
	[CostZoneRelationID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[CostZoneRelations]  WITH CHECK ADD  CONSTRAINT [FK_CostZoneRelations_CostZones] FOREIGN KEY([CostZoneID])
REFERENCES [dbo].[CostZones] ([CostZoneID])
GO

ALTER TABLE [dbo].[CostZoneRelations] CHECK CONSTRAINT [FK_CostZoneRelations_CostZones]
GO

ALTER TABLE [dbo].[CostZoneRelations] ADD  CONSTRAINT [DF_CostZoneRelations_OwnerEntityID]  DEFAULT ((0)) FOR [OwnerEntityID]
GO

