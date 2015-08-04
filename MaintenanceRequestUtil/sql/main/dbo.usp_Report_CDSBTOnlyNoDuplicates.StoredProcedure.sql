USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CDSBTOnlyNoDuplicates]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_CDSBTOnlyNoDuplicates] as
	begin
	SELECT     distinct  T.ChainName as [Chain Name], T.Banner, T.SupplierName as [Supplier Name], T.ProductName as [Product Name],
T.UPC, Convert(varchar(50),cast(isnull(T.[Setup Cost],'0') as numeric(10,4))) as [Supplier Cost],
Convert(varchar(50),cast(isnull(T.[setup Promo],'0') as numeric(10,4))) as [Supplier Promo],
Convert(varchar(50),cast(isnull(T.[Setup Net],'0') as numeric(10,4))) as [Supplier Net],
Convert(varchar(50),cast(isnull(T.[Reported Cost],'0') as numeric(10,4))) as [Retailer Cost],
Convert(varchar(50),cast(isnull(T.[Reported Promo],'0') as numeric(10,4))) as [Retailer Promo],
Convert(varchar(50),cast(isnull(T.RetailerNet,'0') as numeric(10,4))) as [Retailer Net],
convert(varchar(10),Cast(T.SaleDate as date),101) as [Transaction Date],
T.CostZoneName as [Cost Zone],
T.SupplierID as [Supplier ID #]
FROM  DataTrue_CustomResultSets.dbo.tmpCostDifferences T with(nolock)
INNER JOIN ProductBrandAssignments PB  with (nolock)   
on PB.ProductID=T.ProductID
inner join ProductIdentifiers PD1 with (nolock)   
ON T.ProductID = PD1.ProductID  
and pd1.IdentifierValue = t.UPC
INNER JOIN Brands B with (nolock)  ON PB.BrandID = B.BrandID
WHERE  1 =1 and t.ChainID =40393 and pd1.ProductIdentifierTypeID = 2
and cast(T.SaleDate as date) >= cast(dateadd(d,-2, cast(getdate() as date)) as date) and T.SaleDate  <= getdate()
	end
GO
