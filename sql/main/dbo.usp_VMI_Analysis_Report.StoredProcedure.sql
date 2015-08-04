USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_VMI_Analysis_Report]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_VMI_Analysis_Report]
@SupplierId varchar(20),
@ChainId varchar(20),
@Banner varchar(50),
@StoreNumber varchar(50),
@UPC varchar(50), 
@DeliveryDate varchar(20)
-- exec [usp_VMI_Analysis_Report] '44246','44199','-1','','','1900-01-01'
as 
Begin
set nocount on
	
	if(@Banner='-1' or @Banner='All')
		set @Banner = ''				
		
	select P.RecordId, P.Banner, P.StoreIdentifier as [Store Number], P.ProductName as [Product Name], P.UPC,[Upcoming Delivery Date], 
		[Order Units] ,[Actual Units Delivered (if data available)],
		[Total POS 1-7 days before upcoming delivery],[Total Deliveries 1-7 days before upcoming delivery],
		[Total POS 8-14 days before upcoming delivery],[Total Deliveries 8-14 days before upcoming delivery],
		[Total POS 15-21 days before upcoming delivery],[Total Deliveries 15-21 days before upcoming delivery]
		--,(select top 1 sum(qty) from StoreTransactions 
		--	where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId and TransactionTypeId in (10,11) and SaleDateTime<@DeliveryDate
		--	group by saledatetime 
		--	order by saledatetime desc) as [Last Inventory Count]
	
	from PO_PurchaseOrderHistoryDataDetailed P

	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Actual Units Delivered (if data available)]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=5 
					and SaleDateTime=@DeliveryDate
					group by SupplierId, StoreId, ProductId
				) S0 on S0.SupplierId=P.SupplierId and S0.StoreId=P.StoreId and S0.ProductId=P.ProductId
	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total POS 1-7 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=2 
					and SaleDateTime>=dateadd(d,-7,@DeliveryDate) and SaleDateTime<@DeliveryDate
					group by SupplierId, StoreId, ProductId
				) P1 on P1.SupplierId=P.SupplierId and P1.StoreId=P.StoreId and P1.ProductId=P.ProductId

	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total Deliveries 1-7 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=5 
					and SaleDateTime>=dateadd(d,-7,@DeliveryDate) and SaleDateTime<@DeliveryDate
					group by SupplierId, StoreId, ProductId
				) S1 on S1.SupplierId=P.SupplierId and S1.StoreId=P.StoreId and S1.ProductId=P.ProductId

	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total POS 8-14 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=2 
					and SaleDateTime>=dateadd(d,-14,@DeliveryDate) and SaleDateTime<dateadd(d,-7,@DeliveryDate)
					group by SupplierId, StoreId, ProductId
				) P2 on P2.SupplierId=P.SupplierId and P2.StoreId=P.StoreId and P2.ProductId=P.ProductId

	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total Deliveries 8-14 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=5 
					and SaleDateTime>=dateadd(d,-14,@DeliveryDate) and SaleDateTime<dateadd(d,-7,@DeliveryDate)
					group by SupplierId, StoreId, ProductId
				) S2 on S2.SupplierId=P.SupplierId and S2.StoreId=P.StoreId and S2.ProductId=P.ProductId
	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total POS 15-21 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=2 
					and SaleDateTime>=dateadd(d,-21,@DeliveryDate) and SaleDateTime<dateadd(d,-14,@DeliveryDate)
					group by SupplierId, StoreId, ProductId
				) P3 on P3.SupplierId=P.SupplierId and P3.StoreId=P.StoreId and P3.ProductId=P.ProductId
				
	left join (
					select SupplierId, StoreId, ProductId, sum(qty) as [Total Deliveries 15-21 days before upcoming delivery]
					from DataTrue_Report.dbo.StoreTransactions where SupplierID=@SupplierId and TransactionTypeId=5 
					and SaleDateTime>=dateadd(d,-21,@DeliveryDate) and SaleDateTime<dateadd(d,-14,@DeliveryDate)
					group by SupplierId, StoreId, ProductId
				) S3 on S3.SupplierId=P.SupplierId and S3.StoreId=P.StoreId and S3.ProductId=P.ProductId
				
	where P.SupplierID=@SupplierId and P.ChainId=@ChainId 
			and [Upcoming Delivery Date] = @DeliveryDate
			and P.StoreIdentifier like '%' + @StoreNumber + '%' and P.UPC like '%' + @UPC + '%' and P.Banner like '%' + @Banner + '%'
	
End
GO
