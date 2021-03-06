USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[MaintenanceRequestExceptions]    Script Date: 06/25/2015 18:26:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaintenanceRequestExceptions](
	[MaintenanceRequestID] [int] NOT NULL,
	[productid] [int] NOT NULL,
	[brandid] [int] NOT NULL,
	[UnitValue] [money] NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[EndDateTime] [datetime] NOT NULL,
	[TradingPartnerPromotionIdentifier] [nvarchar](50) NULL,
	[datetimecreated] [datetime] NOT NULL,
	[BatchID] [int] NULL,
	[datedealadded] [date] NULL,
	[recordstatus] [smallint] NOT NULL,
	[correctedproductid] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MaintenanceRequestExceptions] ADD  CONSTRAINT [DF_MaintenanceRequestExceptions_datetimecreated]  DEFAULT (getdate()) FOR [datetimecreated]
GO
ALTER TABLE [dbo].[MaintenanceRequestExceptions] ADD  CONSTRAINT [DF_MaintenanceRequestExceptions_recordstatus]  DEFAULT ((0)) FOR [recordstatus]
GO
INSERT [dbo].[MaintenanceRequestExceptions] ([MaintenanceRequestID], [productid], [brandid], [UnitValue], [StartDateTime], [EndDateTime], [TradingPartnerPromotionIdentifier], [datetimecreated], [BatchID], [datedealadded], [recordstatus], [correctedproductid]) VALUES (2377, 5960, 0, 1.0900, CAST(0x00009FE800000000 AS DateTime), CAST(0x00009FF500000000 AS DateTime), N'4027685030321                 ', CAST(0x0000A00B00E5E76B AS DateTime), 2668, CAST(0x41350B00 AS Date), 0, NULL);