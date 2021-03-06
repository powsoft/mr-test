USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[MaintananceRequestsTypes]    Script Date: 06/25/2015 18:26:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaintananceRequestsTypes](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RequestType] [int] NOT NULL,
	[RequestTypeDescription] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_MaintananceRequestsTypes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[MaintananceRequestsTypes] ON
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (3, 1, N'Add New Item')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (4, 2, N'Update Existing Item Base Cost')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (5, 3, N'Add New Promotion')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (6, 4, N'Delete Promotion')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (7, 9, N'Delete (Deauthorize) Item')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (8, 14, N'Discontinue Item')
INSERT [dbo].[MaintananceRequestsTypes] ([ID], [RequestType], [RequestTypeDescription]) VALUES (9, 15, N'Replacement Item')
SET IDENTITY_INSERT [dbo].[MaintananceRequestsTypes] OFF
