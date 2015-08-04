USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_VMI_Analysis_Report_Test]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_VMI_Analysis_Report_Test]
@SupplierId varchar(20),
@ChainId varchar(20),
@Banner varchar(50),
@StoreNumber varchar(50),
@UPC varchar(50), 
@FromDeliveryDate varchar(50),
@ToDeliveryDate varchar(50)
--@DeliveryDate varchar(20)
as -- exec [usp_VMI_Analysis_Report_Test] '44246','44199','-1','','','06/17/2013','06/18/2013'
Begin
set nocount on
	
	if(@Banner='-1' or @Banner='All')
		set @Banner = ''				
		
	select P.RecordId, P.Banner, P.StoreIdentifier as [Store Number], P.ProductName as [Product Name], 
		   P.UPC,[Upcoming Delivery Date], [Order Units] ,
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=5 and SaleDateTime=P.[Upcoming Delivery Date]
			)	as [Actual Units Delivered (if data available)],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=2 and SaleDateTime>=dateadd(d,-7,P.[Upcoming Delivery Date]) and SaleDateTime<P.[Upcoming Delivery Date]
			)	as [Total POS 1-7 days before upcoming delivery],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=5 and SaleDateTime>=dateadd(d,-7,P.[Upcoming Delivery Date]) and SaleDateTime<P.[Upcoming Delivery Date]
			)	as  [Total Deliveries 1-7 days before upcoming delivery],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=2 and SaleDateTime>=dateadd(d,-14,P.[Upcoming Delivery Date]) 
				and SaleDateTime<dateadd(d,-7,P.[Upcoming Delivery Date])
			)	as [Total POS 8-14 days before upcoming delivery],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=5 and SaleDateTime>=dateadd(d,-14,P.[Upcoming Delivery Date]) 
				and SaleDateTime<dateadd(d,-7,P.[Upcoming Delivery Date])
			)	as [Total Deliveries 8-14 days before upcoming delivery],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=2 and SaleDateTime>=dateadd(d,-21,P.[Upcoming Delivery Date]) 
				and SaleDateTime<dateadd(d,-14,P.[Upcoming Delivery Date])
			)	as [Total POS 15-21 days before upcoming delivery],
			(	select sum(qty) 
				from DataTrue_Report.dbo.StoreTransactions where SupplierID=P.SupplierId and StoreId=P.StoreId and ProductId=P.ProductId 
				and TransactionTypeId=5 and SaleDateTime>=dateadd(d,-21,P.[Upcoming Delivery Date]) 
				and SaleDateTime<dateadd(d,-14,P.[Upcoming Delivery Date])
			)	as [Total Deliveries 15-21 days before upcoming delivery]
	
	from PO_PurchaseOrderHistoryDataDetailed P
	where P.SupplierID=@SupplierId and P.ChainId=@ChainId and [Upcoming Delivery Date] >= @FromDeliveryDate 
	and [Upcoming Delivery Date] <= @ToDeliveryDate
	and P.StoreIdentifier like '%' + @StoreNumber + '%' and P.UPC like '%' + @UPC + '%' and P.Banner like '%' + @Banner + '%'
	
End
GO
