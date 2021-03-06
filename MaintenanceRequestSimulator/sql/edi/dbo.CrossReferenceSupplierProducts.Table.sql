USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[CrossReferenceSupplierProducts]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CrossReferenceSupplierProducts](
	[SupplierIdentifier] [nchar](10) NOT NULL,
	[SupplierTitle] [nchar](100) NOT NULL,
	[SupplierBipad] [nchar](10) NULL,
	[IcontrolBipad] [nchar](10) NULL,
	[IcontrolTitle] [nchar](100) NULL,
	[ProductIdentifier] [nchar](50) NULL,
 CONSTRAINT [PK_CrossReferenceSupplierProducts] PRIMARY KEY CLUSTERED 
(
	[SupplierIdentifier] ASC,
	[SupplierTitle] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'BANGOR DAILY NEWS                                                                                   ', NULL, N'BNGD      ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'BANGOR DAILY SAT                                                                                    ', NULL, N'BNGSA     ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'BARRONS                                                                                             ', NULL, N'BAR       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'DAILY NEWS (NY)                                                                                     ', NULL, N'NYDN      ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'GLOBE (BOSTON)                                                                                      ', NULL, N'BG        ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'HERALD (BOSTON)                                                                                     ', NULL, N'BHD       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'INV DLY-SPECIAL                                                                                     ', NULL, N'IBD       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'INVESTORS BUSINESS                                                                                  ', NULL, N'IBDM      ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'JOURNAL TRIBUNE                                                                                     ', NULL, N'X2140     ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'LEWISTON JOURNAL                                                                                    ', NULL, N'LSJO      ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'MAINEBIZ                                                                                            ', NULL, N'MANBZ     ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'NHL PREVIEW                                                                                         ', NULL, N'X3456     ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'NY   POST                                                                                           ', NULL, N'NYP       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'PORTLAND PRESS                                                                                      ', NULL, N'PPH       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'PORTLAND PRESS HER                                                                                  ', NULL, N'PPH       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'SERVICE CHARGE                                                                                      ', NULL, NULL, NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'TIMES NY                                                                                            ', NULL, N'NYT       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'USA  AUGUSTA                                                                                        ', NULL, N'USA       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'USA  PORTLAND                                                                                       ', NULL, N'USA       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'USA SW-PORT                                                                                         ', NULL, N'USA       ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'WALL ST JOURNAL                                                                                     ', NULL, N'WALL      ', NULL, NULL)
INSERT [dbo].[CrossReferenceSupplierProducts] ([SupplierIdentifier], [SupplierTitle], [SupplierBipad], [IcontrolBipad], [IcontrolTitle], [ProductIdentifier]) VALUES (N'Wr723     ', N'WSJ WEEKEND                                                                                         ', NULL, N'WALL      ', NULL, NULL)
