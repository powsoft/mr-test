USE [DataTrue_Main]
GO
/****** Object:  Table [dbo].[Memberships]    Script Date: 06/25/2015 18:26:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Memberships](
	[MembershipID] [int] IDENTITY(21828,1) NOT NULL,
	[MembershipTypeID] [int] NOT NULL,
	[OrganizationEntityID] [int] NULL,
	[MemberEntityID] [int] NOT NULL,
	[ChainID] [int] NULL,
	[HierarchyID] [hierarchyid] NULL,
	[MembershipName] [nvarchar](50) NULL,
	[MembershipNumeric] [int] NULL,
	[MembershipDescription] [varchar](500) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [int] NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
	[OwnerEntityID] [nvarchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Memberships] ADD  CONSTRAINT [DF_Memberships_MembershipTypeID]  DEFAULT ((1)) FOR [MembershipTypeID]
GO
ALTER TABLE [dbo].[Memberships] ADD  CONSTRAINT [DF__Membershi__DateT__5FB337D6]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO
ALTER TABLE [dbo].[Memberships] ADD  CONSTRAINT [DF__Membershi__DateT__60A75C0F]  DEFAULT (getdate()) FOR [DateTimeLastUpdate]
GO
SET IDENTITY_INSERT [dbo].[Memberships] ON
INSERT [dbo].[Memberships] ([MembershipID], [MembershipTypeID], [OrganizationEntityID], [MemberEntityID], [ChainID], [HierarchyID], [MembershipName], [MembershipNumeric], [MembershipDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [OwnerEntityID]) VALUES (1, 12, 63454, 41244, 40393, NULL, NULL, NULL, N'Store2Banner', CAST(0x0000A21E00000000 AS DateTime), 40384, CAST(0x0000A21E00000000 AS DateTime), N'40393’);