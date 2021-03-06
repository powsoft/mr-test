USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[MembershipTypes]    Script Date: 06/25/2015 18:26:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MembershipTypes](
	[MembershipTypeID] [int] IDENTITY(0,1) NOT NULL,
	[MembershipTypeName] [nvarchar](50) NOT NULL,
	[MembershipTypeDescription] [nvarchar](500) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [int] NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
 CONSTRAINT [PK_MembershipTypes] PRIMARY KEY CLUSTERED 
(
	[MembershipTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MembershipTypes] ADD  CONSTRAINT [DF_MembershipTypes_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO
ALTER TABLE [dbo].[MembershipTypes] ADD  CONSTRAINT [DF_MembershipTypes_DateTimeLastUpdate]  DEFAULT (getdate()) FOR [DateTimeLastUpdate]
GO
SET IDENTITY_INSERT [dbo].[MembershipTypes] ON
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (0, N'DEFAULT', NULL, CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (1, N'ClusterMembership', NULL, CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (2, N'SharedLoginRole', NULL, CAST(0x00009F0900A3EA44 AS DateTime), 2, CAST(0x00009F0900A3EA44 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (3, N'ReportingRoleMembership', N'ReportingRoleMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (4, N'Chain', N'ChainMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (5, N'Store', N'StoreMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (6, N'Supplier', N'SupplierMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (7, N'Manufacturer', N'ManufacturerMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (8, N'iControl', N'iControlMembership', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (9, N'DataTrueRoleMembership', N'This membership is for use of the DataTrue online systems', CAST(0x00009E5E00000000 AS DateTime), 2, CAST(0x00009E5E00000000 AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (10, N'RegulatedPaymentRemittanceAccountByStoreGroup', N'This membership type supports grouping of stores that will share a payment remittance account for regulated billing ACH requestsq', CAST(0x0000A1E700B88B6C AS DateTime), 0, CAST(0x0000A1E700B88B6C AS DateTime))
INSERT [dbo].[MembershipTypes] ([MembershipTypeID], [MembershipTypeName], [MembershipTypeDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (12, N'Store-BannerMembership', N'This membership defines relationships between Stores and Banners OrganizationEntityID stores ClusterID of Banner MemberShipID stores StoreID', CAST(0x0000A22500000000 AS DateTime), 2, CAST(0x0000A22500000000 AS DateTime))
SET IDENTITY_INSERT [dbo].[MembershipTypes] OFF
