USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateOrderUnitsBasedOnBulkOrder]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UpdateOrderUnitsBasedOnBulkOrder]
@SupplierId varchar(20),
@ChainId varchar(20),
@DeliveryDate varchar(20),
@DeleteFlag varchar(1)
as 
--exec [usp_UpdateOrderUnitsBasedOnBulkOrder] 44246, 44199, '06/26/2013'
Begin
	Declare @Pad int = 100
	
	update PO_PurchaseOrderHistoryDataDetailed set [Order Units]=[PO Units] where SupplierId=@SupplierId and ChainId=@ChainId and [Upcoming Delivery Date]= @DeliveryDate and DeleteFlag=@DeleteFlag
	
	update D set D.[Order Units] = D1.[Order Units], D.[PO Units] = D1.[PO Units]
	from PO_PurchaseOrderHistoryDataDetailed D
	inner join PO_PurchaseOrderHistoryData D1 on D1.SupplierId=D.SupplierId and D1.StoreId=D.Storeid and  D1.ProductId=D.ProductId and D1.[Upcoming Delivery Date]=D.[Upcoming Delivery Date]
	where D.[PO Units] is null and D1.[PO Units] is not null and D.SupplierId=@SupplierId and D.ChainId=@ChainId and D.[Upcoming Delivery Date]= @DeliveryDate
	and D.DeleteFlag=@DeleteFlag
	
	update D set [Order Units] = case when (isnull(H.TotalOrderUnits,0) = 0) or (B.BulkUnits is null) or (D.[PO Units] is null) then NULL else round(D.[PO Units] * B.BulkUnits / H.TotalOrderUnits, 0) end
	from PO_PurchaseOrderHistoryDataDetailed D
	inner join (
					Select SupplierId, ProductId, [Upcoming Delivery Date], sum(isnull([order units],0)) as TotalOrderUnits
					from PO_PurchaseOrderHistoryDataDetailed H 
					where SupplierId=@SupplierId and ChainId=@ChainId and DeleteFlag=@DeleteFlag
					group by SupplierId, ProductId, [Upcoming Delivery Date]
				) as H	on H.SupplierID=D.SupplierId and H.ProductId=D.ProductId and H.[Upcoming Delivery Date] = D.[Upcoming Delivery Date]
	left join (
					Select SupplierId, ProductId, [DueDate], sum(isnull(Qty,0)) as BulkUnits
					from PO_BulkOrderData B 
					where SupplierId=@SupplierId and ChainId=@ChainId
					group by SupplierId, ProductId, [DueDate]
				) as B	on B.SupplierID=D.SupplierId and B.ProductId=D.ProductId and B.[DueDate] = D.[Upcoming Delivery Date]
	where D.SupplierId=@SupplierId and D.ChainId=@ChainId and D.[Upcoming Delivery Date]= @DeliveryDate
	and D.DeleteFlag=@DeleteFlag
	
	if(getdate()>'2013-06-16')
	--Converting the Order Units based on Units Per Case	(Round Case Upwards)
		update P set [Order Units] = ceiling(([Order Units]/(C.CasePortion * C.ItemsPerCase)))*(C.CasePortion * C.ItemsPerCase) 
		from PO_PurchaseOrderHistoryDataDetailed P
		inner join (Select SupplierId, ProductId, min(ItemsPerCase) as ItemsPerCase, CasePortion
					from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion 
					where SupplierId=@SupplierId and ItemsPerCase is not null
					group by SupplierId, ProductId, CasePortion
				) C on C.SupplierId=P.SupplierId and C.ProductId=P.ProductId
		where P.SupplierId=@SupplierId and ChainId=@ChainId  and [PO units] is not null and P.[Upcoming Delivery Date]= @DeliveryDate and P.DeleteFlag=@DeleteFlag
	else
	--(Round Case downwards)
		update P set [Order Units] = floor(([Order Units]/(C.CasePortion * C.ItemsPerCase)))*(C.CasePortion * C.ItemsPerCase) 
		from PO_PurchaseOrderHistoryDataDetailed P
		inner join (Select SupplierId, ProductId, min(ItemsPerCase) as ItemsPerCase, CasePortion
					from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion 
					where SupplierId=@SupplierId and ItemsPerCase is not null
					group by SupplierId, ProductId, CasePortion
				) C on C.SupplierId=P.SupplierId and C.ProductId=P.ProductId
		where P.SupplierId=@SupplierId and ChainId=@ChainId  and [PO units] is not null and P.[Upcoming Delivery Date]= @DeliveryDate and P.DeleteFlag=@DeleteFlag
	
	select D.ProductId, count(StoreId) as Recordcount, sum([Order Units]) as [Order Units], BulkUnits, (sum([Order Units])- BulkUnits) as ExtraUnits, 
	((sum([Order Units])- BulkUnits)/ (C.CasePortion * C.ItemsPerCase)) as NoofReductions, (C.CasePortion * C.ItemsPerCase) as MinUnits 
	into #tmp1
	from PO_PurchaseOrderHistoryDataDetailed D
	inner join (Select SupplierId, ProductId, min(ItemsPerCase) as ItemsPerCase, CasePortion
					from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion 
					where SupplierId=@SupplierId and ItemsPerCase is not null
					group by SupplierId, ProductId, CasePortion
				) C on C.SupplierId=D.SupplierId and C.ProductId=D.ProductId
	inner join (select SupplierId, ProductId, [DueDate], sum(isnull(Qty,0)) as BulkUnits 
				from PO_BulkOrderData where SupplierId=@SupplierId and ChainId=@ChainId
				group by SupplierId, ProductId, [DueDate] )
				B on B.SupplierID=D.SupplierId and B.ProductId=D.ProductId and B.[DueDate] = D.[Upcoming Delivery Date]
	where D.SupplierId=@SupplierId and D.ChainId=@ChainId and D.[Upcoming Delivery Date]= @DeliveryDate and D.[Order Units] is not null and D.DeleteFlag=@DeleteFlag
	group by D.ProductId, BulkUnits, C.CasePortion , C.ItemsPerCase
	
	--Select ProductId, NoOfReductions, MinUnits from #tmp1
	
	Declare @ProductId varchar(10), @NoOfReductions int, @MinUnits int
	DECLARE BULK_CURSOR CURSOR FOR 
	Select ProductId, isnull(NoOfReductions,0) as NoOfReductions, isnull(MinUnits,0) as MInUnits from #tmp1 
	OPEN BULK_CURSOR;
		FETCH NEXT FROM BULK_CURSOR INTO @ProductId, @NoOfReductions, @MinUnits
		while @@FETCH_STATUS = 0
			begin
					if(@NoOfReductions>0 and @MinUnits>0)
					Begin
						update D set D.[Order Units] = D.[Order Units] - @MinUnits
						from PO_PurchaseOrderHistoryDataDetailed D
						inner join (
									select top (@NoOfReductions) D.StoreSetupId, D.[Upcoming Delivery Date]
									from PO_PurchaseOrderHistoryDataDetailed D
									where D.SupplierId=@SupplierId and D.ChainId=@ChainId and D.[Upcoming Delivery Date]= @DeliveryDate and d.ProductId=@ProductId  and D.[Order Units] is not null and D.DeleteFlag=@DeleteFlag
									order by D.[PO units] asc
									) D1 on D.StoreSetupId=D1.StoreSetupId and D.[Upcoming Delivery Date]= D1.[Upcoming Delivery Date]
						where D.SupplierId=@SupplierId and D.ChainId=@ChainId and D.[Upcoming Delivery Date]= @DeliveryDate and d.ProductId=@ProductId  and D.[Order Units] is not null and D.DeleteFlag=@DeleteFlag
					End
				FETCH NEXT FROM BULK_CURSOR INTO @ProductId, @NoOfReductions, @MinUnits
			end
	CLOSE BULK_CURSOR;
	DEALLOCATE BULK_CURSOR;
	
End
GO
