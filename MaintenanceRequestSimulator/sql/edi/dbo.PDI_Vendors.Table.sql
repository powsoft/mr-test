USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[PDI_Vendors]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PDI_Vendors](
	[PDI_VendorIdentifier] [nvarchar](50) NOT NULL,
	[PDI_VendorName] [nvarchar](max) NULL,
 CONSTRAINT [PK_PDI_Vendors] PRIMARY KEY CLUSTERED 
(
	[PDI_VendorIdentifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
