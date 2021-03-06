USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[CrossReference_SupplierChain]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CrossReference_SupplierChain](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Wholesalerid] [nchar](10) NOT NULL,
	[DataTrueSupplierID] [int] NULL,
	[StoreNamePattern] [nchar](200) NULL,
	[ChainName] [nvarchar](50) NOT NULL,
	[SupplierChainName] [nchar](50) NULL
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[CrossReference_SupplierChain] ON
INSERT [dbo].[CrossReference_SupplierChain] ([ID], [Wholesalerid], [DataTrueSupplierID], [StoreNamePattern], [ChainName], [SupplierChainName]) VALUES (2255, N'WR669     ', 26596, N'CVS Pharmacy                                                                                                                                                                                            ', N'CVS', NULL);