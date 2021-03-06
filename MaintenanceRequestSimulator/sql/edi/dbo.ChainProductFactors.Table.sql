USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[ChainProductFactors]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChainProductFactors](
	[ChainID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[BrandID] [int] NOT NULL,
	[BaseUnitsCalculationPerNoOfweeks] [int] NULL,
	[CostFromRetailPercent] [tinyint] NOT NULL,
	[BillingRuleID] [smallint] NOT NULL,
	[IncludeDollarDiffDetails] [tinyint] NOT NULL,
	[ActiveStartDate] [smalldatetime] NULL,
	[ActiveEndDate] [smalldatetime] NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[LastUpdateUserID] [nvarchar](50) NOT NULL,
	[DateTimeLastUpdate] [datetime] NOT NULL
) ON [PRIMARY]
GO
INSERT [dbo].[ChainProductFactors] ([ChainID], [ProductID], [BrandID], [BaseUnitsCalculationPerNoOfweeks], [CostFromRetailPercent], [BillingRuleID], [IncludeDollarDiffDetails], [ActiveStartDate], [ActiveEndDate], [DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate]) VALUES (3, 0, 0, 17, 75, 1, 1, CAST(0x8EAC0000 AS SmallDateTime), CAST(0xB2580000 AS SmallDateTime), CAST(0x00009EE800EAF065 AS DateTime), N'2', CAST(0x00009EE800EAF065 AS DateTime));