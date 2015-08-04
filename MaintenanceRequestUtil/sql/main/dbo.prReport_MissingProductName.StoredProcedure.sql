USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReport_MissingProductName]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prReport_MissingProductName]

As
Begin
	select distinct sp.SupplierName, sp.SupplierID, ''''+i.IdentifierValue as UPC,p.ProductName, p.Description, s.ProductId
	from suppliers sp
	inner join storesetup s
	on sp.SupplierID = s.SupplierID
	inner join Products p
	on s.ProductID = p.ProductID
	inner join productidentifiers i
	on p.productid = i.productid
	and i.productidentifiertypeid = 2
	where isnumeric(ProductName)>0 
	and sp.SupplierID in
	(select distinct SupplierID from storetransactions where SaleDateTime > '11/30/2011'
	and SupplierID<>0)
	and CHARINDEX('(D)',i.identifiervalue)<1
	order by sp.SupplierName, sp.supplierid, ''''+i.identifiervalue, p.Description, s.ProductId
End
GO
