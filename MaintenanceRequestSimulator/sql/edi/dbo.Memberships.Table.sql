USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[Memberships]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Memberships](
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
	[DateTimeLastUpdate] [datetime] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
INSERT [dbo].[Memberships] ([MembershipTypeID], [OrganizationEntityID], [MemberEntityID], [ChainID], [HierarchyID], [MembershipName], [MembershipNumeric], [MembershipDescription], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (1, 0, 51110, 44267, NULL, NULL, NULL, NULL, CAST(0x0000A19E00C8D303 AS DateTime), 7605, CAST(0x0000A19E00C8D303 AS DateTime));