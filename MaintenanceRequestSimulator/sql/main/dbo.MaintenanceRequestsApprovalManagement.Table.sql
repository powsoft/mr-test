USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[MaintenanceRequestsApprovalManagement]    Script Date: 06/25/2015 18:26:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaintenanceRequestsApprovalManagement](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ChainID] [int] NULL,
	[SupplierID] [int] NULL,
	[IsAutoApproval] [int] NULL
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[MaintenanceRequestsApprovalManagement] ON
INSERT [dbo].[MaintenanceRequestsApprovalManagement] ([ID], [ChainID], [SupplierID], [IsAutoApproval]) VALUES (1, 62348, 50721, 1)
SET IDENTITY_INSERT [dbo].[MaintenanceRequestsApprovalManagement] OFF
