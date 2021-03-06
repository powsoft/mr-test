USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[chains]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[chains](
	[ChainID] [int] NOT NULL,
	[ChainName] [nvarchar](50) NOT NULL,
	[ChainIdentifier] [nvarchar](50) NULL,
	[ActiveStartDate] [datetime] NOT NULL,
	[ActiveEndDate] [datetime] NOT NULL,
	[Comments] [nvarchar](500) NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL,
	[UseStoresCustom1ForStoreLookup] [bit] NULL,
	[LeadTimetoCostChanges] [int] NULL,
	[LeadTimetoPromoChanges] [int] NULL,
	[AllowProductAddFromPOS] [bit] NOT NULL,
	[PDITradingPartner] [bit] NOT NULL,
	[UseReportedCostForBilling] [bit] NOT NULL,
	[TaxIDMask] [varchar](50) NULL,
	[DefaultBanner] [varchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[chains] ADD  CONSTRAINT [DF_Chains_AllowProductAddFromPOS]  DEFAULT ((0)) FOR [AllowProductAddFromPOS]
GO
ALTER TABLE [dbo].[chains] ADD  CONSTRAINT [DF_Chains_PDITradingPartner]  DEFAULT ((0)) FOR [PDITradingPartner]
GO
ALTER TABLE [dbo].[chains] ADD  CONSTRAINT [DF_Chains_UseReportedCostForBilling]  DEFAULT ((0)) FOR [UseReportedCostForBilling]
GO
INSERT [dbo].[chains] ([ChainID], [ChainName], [ChainIdentifier], [ActiveStartDate], [ActiveEndDate], [Comments], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [UseStoresCustom1ForStoreLookup], [LeadTimetoCostChanges], [LeadTimetoPromoChanges], [AllowProductAddFromPOS], [PDITradingPartner], [UseReportedCostForBilling], [TaxIDMask], [DefaultBanner]) VALUES (0, N'DEFAULT', N'DEFAULT', CAST(0x00009E5E00000000 AS DateTime), CAST(0x0000B25800000000 AS DateTime), N'DEFAULT Chain', CAST(0x00009E5E00000000 AS DateTime), N'2', CAST(0x00009E5E00000000 AS DateTime), NULL, NULL, NULL, 0, 0, 0, NULL, NULL);