USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[ProductIdentifierLookup]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductIdentifierLookup](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[PartnerType] [smallint] NULL,
	[PartnerIdentifier] [nchar](10) NULL,
	[ProductName] [nchar](100) NULL,
	[ProductIdentifierType] [smallint] NULL,
	[ProductIdentifier] [nchar](20) NULL,
	[ProductIdentifier10Digits] [nchar](10) NULL,
	[CommonIdentifier] [nchar](10) NULL,
	[ProductIdentifierRaw] [nchar](20) NULL,
	[ProductCategory] [nchar](10) NULL,
	[SuggRetail] [money] NULL,
	[Frequency] [nchar](50) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[Active] [smallint] NULL
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[ProductIdentifierLookup] ON
INSERT [dbo].[ProductIdentifierLookup] ([ProductID], [PartnerType], [PartnerIdentifier], [ProductName], [ProductIdentifierType], [ProductIdentifier], [ProductIdentifier10Digits], [CommonIdentifier], [ProductIdentifierRaw], [ProductCategory], [SuggRetail], [Frequency], [DateFrom], [DateTo], [Active]) VALUES (1, 2, N'WR723     ', N'GLOBE(BOSTON)                                                                                       ', 2, N'094772000054        ', N'9477200005', N'BG        ', N'094772000054        ', N'Newsp     ', 1.0000, N'Daily                                             ', NULL, NULL, NULL);