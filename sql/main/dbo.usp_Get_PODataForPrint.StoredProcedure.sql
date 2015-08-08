USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_PODataForPrint]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Get_PODataForPrint]
	@StoreId varchar(20)
as 
set nocount on
	
	select 	T.ProductId, UPC, (ProductName) as ProductName, [PO Units], [Order Units],
			cast(P.UnitRetail as numeric(5,4)) as [Retail Price], 
			cast(isnull(P.Allowance,0) as numeric(5,4)) as Allowance, 
			cast(P.UnitPrice as numeric(5,4)) as [Unit Price],
			(isnull([PO Units],0) * isnull([UnitPrice],0)) as Total
	from PO_PurchaseOrderData T
	inner join Stores S on S.StoreID = T.StoreId
	left join Addresses A on A.OwnerEntityID = T.StoreId
	left join StoresUniqueValues SUV on SUV.SupplierID = T.SupplierId and SUV.StoreID = T.StoreId 
	inner join ProductPrices P on P.SupplierID = T.SupplierId and P.StoreID = T.StoreId and P.ProductID = T.ProductId 
	where isnull([PO Units],0) > 0
	and (P.ProductPriceTypeID = 3) AND (P.ActiveStartDate <= { fn NOW() }) AND (P.ActiveLastDate >= { fn NOW() })
	and S.StoreID=@StoreId
GO
