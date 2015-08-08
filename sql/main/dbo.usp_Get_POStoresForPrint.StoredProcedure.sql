USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_POStoresForPrint]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Get_POStoresForPrint]
	@ForStores varchar(255)
as 
set nocount on
	Declare @strSQL varchar(2000)
	
	set @strSQL  = ' select distinct t.StoreId, S.StoreIdentifier as [Store Number], S.StoreName as [Store Name], 
					A.Address1 as [Store Address], 
					(A.City  + '', '' + A.State + '' '' + A.PostalCode) as [Store Location], 
					SUV.SupplierAccountNumber, [Upcoming Delivery Date], SUV.DriverName, SUV.RouteNumber

					from PO_PurchaseOrderData T
					inner join Stores S on S.StoreID = T.StoreId
					left join Addresses A on A.OwnerEntityID = T.StoreId
					left join StoresUniqueValues SUV on SUV.SupplierID = T.SupplierId and SUV.StoreID = T.StoreId 
					where isnull([PO Units],0) > 0 '
	
	if(@ForStores<>'')
		set @strSQL = @strSQL +  ' and T.StoreId in (' +  @ForStores + ')'
		
	exec(@strSQL)
GO
