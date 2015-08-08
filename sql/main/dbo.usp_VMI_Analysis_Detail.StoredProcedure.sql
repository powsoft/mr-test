USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_VMI_Analysis_Detail]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_VMI_Analysis_Detail]
@RecordId varchar(20)
as -- exec [usp_VMI_Analysis_Detail] 232126
Begin
set nocount on
	
	select StoreIdentifier as [Store Number], [UPC], convert(varchar(10),LastCountDate, 101) as [Last Count Date], LastCountQty as [Last Count Qty], 
	convert(varchar(10),cast(LastDeliveryDate as date), 101) as [Last Delivery Date],DeliveredUnits as [Delivered Units], CreditUnits as [Credit Units],	
	convert(varchar(10),cast(LastPOSDate as date), 101) as [Last POS Date],POSUnits as [POS Units],	
	convert(varchar(10),[Upcoming Delivery Date], 101) as [Upcoming Delivery Date],	MissingPOSDaysToDelivery as [Missing POS Days To Delivery], AvgDailySales as [Avg Daily Sales],	
	EndingInventoryOnNextDeliveryDate as [Expected Inventory on Upcoming delivery Date],
	convert(varchar(10),[Subsequent Delivery Date], 101) as [Subsequent Delivery Date],	DaysToNextDelivery as [Days to Subsequent delivery], QtyNeeded as [Expected POS Activity between Next and Subsequent Delivery],
	EndingInventoryOnNextDeliveryDate- QtyNeeded as [Expected Inventory on Subsquent delivery Date], 
	[Min Capacity],	[Max Capacity],	[PO Units] as [Predictive Order Units Recommended],	[Order Units] as [Adjusted Predictive Order Units (based on User Inputs and Case Rules)],
	C.ItemsPerCase as [Items Per Case], C.CasePortion as [Deliverable Case Portion], SupplierItemNumber as [Supplier Item Number],Route
	from PO_PurchaseOrderHistoryDataDetailed P
	left join DataTrue_Edi.dbo.ProductsSuppliersItemsConversion C on C.SupplierId=P.SupplierId and C.ProductId=P.ProductId
	where RecordId=@RecordId
	
End
GO
