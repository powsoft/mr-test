USE [DataTrue_EDI]
GO

/****** Object:  Table [dbo].[Temp_PDI_VendorIDs]    Script Date: 08/09/2015 23:40:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Temp_PDI_VendorIDs](
	[DataTrueChainID] [int] NOT NULL,
	[DataTrueSupplierID] [int] NOT NULL,
	[PDIVendorID] [varchar](50) NOT NULL,
	[Filename] [varchar](200) NOT NULL,
	[Timestamp] [datetime] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[Temp_PDI_VendorIDs] ADD  CONSTRAINT [DF_Temp_PDI_VendorIDs_Timestamp]  DEFAULT (getdate()) FOR [Timestamp]
GO

