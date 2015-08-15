USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[EDI_SupplierCrossReference_byCorp]    Script Date: 08/15/2015 16:55:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[EDI_SupplierCrossReference_byCorp](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ChainIdentifier] [varchar](50) NOT NULL,
	[SupplierIdentifier] [varchar](50) NOT NULL,
	[SupplierName] [varchar](240) NOT NULL,
	[SupplierDuns] [varchar](50) NULL,
	[CorporateName] [varchar](100) NOT NULL,
	[CorporateIdentifier] [varchar](50) NULL,
	[CorporateID] [varchar](50) NULL,
	[VendorName] [varchar](150) NULL,
	[VendorIdentifier] [varchar](150) NULL,
	[VendorDUNs] [varchar](150) NULL,
	[Banner] [varchar](50) NULL,
	[EdiName] [varchar](50) NULL,
	[DataTrueSupplierID] [int] NULL,
	[SupplierBannerID] [nvarchar](50) NULL,
	[ChainID] [int] NULL,
	[SupplierDuns1] [nvarchar](15) NULL,
	[Custom1] [nvarchar](50) NULL,
	[IsRegulated] [smallint] NULL,
	[UseAggregatornumber] [smallint] NULL,
	[isGSX] [smallint] NULL,
	[RAS] [varchar](50) NULL,
	[RASVersion] [varchar](50) NULL,
	[TransmissionMethod] [varchar](50) NULL,
	[FileMaskForDeliveries] [varchar](50) NULL,
	[GroupNumber] [varchar](10) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

