USE [DataTrue_Main]
GO
/****** Object:  UserDefinedTableType [dbo].[BillPOSProductIDAndBrandIDTable]    Script Date: 06/25/2015 18:26:41 ******/
CREATE TYPE [dbo].[BillPOSProductIDAndBrandIDTable] AS TABLE(
	[ProductID] [int] NULL,
	[BrandID] [int] NULL
)
GO
