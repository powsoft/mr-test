USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Cleanup_Reload]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Inventory_Cleanup_Reload]
as



--*****************************Remove Shrink Invoice Details**********************
select * from InvoiceDetailTypes
select invoicedetailtypeid, COUNT(invoicedetailid) from InvoiceDetails group by invoicedetailtypeid
select * into dbo.invoicedetails_20120223_BeforeBimboBackout from invoicedetails

select * 
--delete
from datatrue_main.dbo.invoicedetails
where InvoiceDetailTypeID in (3, 9)
and SupplierID = 40557

select * 
--delete
from datatrue_report.dbo.invoicedetails
where InvoiceDetailTypeID in (3, 9)
and SupplierID = 40557

select * 
--delete
from datatrue_edi.dbo.invoicedetails
where InvoiceDetailTypeID in (3, 9)
and SupplierID = 40557
--****************************Remove Shrink and Shrink Adj's
select * from TransactionTypes --17 18 19 22 23

select *
into import.dbo.StoreTransactions_20120223BeforeBimboInventoryBackout
from datatrue_main.dbo.StoreTransactions
where 1 = 1
--and TransactionTypeID in (17, 18, 19, 22, 23)
and SupplierID = 40557

select *
--delete
from datatrue_main.dbo.StoreTransactions
where TransactionTypeID in (17, 18, 19, 22, 23)
and SupplierID = 40557


select *
--delete
from datatrue_report.dbo.StoreTransactions
where TransactionTypeID in (17, 18, 19, 22, 23)
and SupplierID = 40557

select *
from import.dbo.StoreTransactions_20120223BeforeBimboInventoryBackout
where TransactionTypeID in (17, 18, 19, 22, 23)
and SupplierID = 40557
--********************************Mark Dupes******************************
--set to status -97
declare @recmarkdupes cursor

select distinct workingstatus from StoreTransactions_working


select transactiontypeid, storeid, ProductId, BrandID, SupplierID, CAST(saledatetime as date), qty, COUNT(storetransactionid)--, SupplierInvoiceNumber
from StoreTransactions_working t
where 1 = 1
and TransactionTypeID in (5, 8)
and SupplierID = 40557
and SaleDateTime > '11/30/2011'
group by transactiontypeid, storeid, ProductId, BrandID, SupplierID, CAST(saledatetime as date), qty--, SupplierInvoiceNumber
having COUNT(storetransactionid) > 1



declare @recremovedupes cursor
declare @remtransactionid bigint
declare @remstoreid int
declare @remproductid int
declare @rembrandid int
declare @remsaledate date
declare @curstoreid int
declare @curproductid int
declare @curbrandid int
declare @cursaledate date
declare @firstrowpassed bit
declare @dupecount int
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @storenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
declare @supplierid int
declare @workingsource nvarchar(50)
declare @storeid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
declare @transactiontypeid int
declare @brandid int
--/*

select transactiontypeid, storeid, ProductId, BrandID, SupplierID, CAST(saledatetime as date) as saledate, qty, COUNT(storetransactionid) as dupecount--, SupplierInvoiceNumber
into #tempdupes
from StoreTransactions_working t
where 1 = 1
and TransactionTypeID in (5, 8)
and SupplierID = 40557
and SaleDateTime > '11/30/2011'
group by transactiontypeid, storeid, ProductId, BrandID, SupplierID, CAST(saledatetime as date), qty--, SupplierInvoiceNumber
having COUNT(storetransactionid) > 1

set @recremovedupes = CURSOR local fast_forward FOR
select  transactiontypeid, storeid, productid, BrandID, SupplierID, cast(saledate as date), qty,  dupecount
from #tempdupes
	
	open @recremovedupes
	
	fetch next from @recremovedupes into
			@transactiontypeid
			,@storeid
			,@productid
			,@brandid
			,@supplierid
			,@date
			,@qty
			,@dupecount
										
	while @@FETCH_STATUS = 0
		begin

print @dupecount

			update DataTrue_Main.dbo.StoreTransactions_Working set workingstatus = -97
			where transactiontypeid = @transactiontypeid
			and StoreID  = @storeid
			and productid = @productid
			and BrandID = @brandid
			and supplierid = @supplierid
			and CAST(saledatetime as date) = @date
			and Qty = @qty
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from DataTrue_Main.dbo.StoreTransactions_Working
				where transactiontypeid = @transactiontypeid
				and StoreID  = @storeid
				and productid = @productid
				and BrandID = @brandid
				and supplierid = @supplierid
				and CAST(saledatetime as date) = @date
				and Qty = @qty
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into
				@transactiontypeid
				,@storeid
				,@productid
				,@brandid
				,@supplierid
				,@date
				,@qty
				,@dupecount
		end
		
	close @recremovedupes
	deallocate @recremovedupes
	

--******************************Mark Dupes End************************************
select *
from stores
where StoreIdentifier = '6102'

select distinct cast(saledatetime as date)
from StoreTransactions
where SupplierID = 40557
and TransactionTypeID = 11
order by cast(saledatetime as date)

select distinct cast(saledatetime as date)
from StoreTransactions
where SupplierID = 40557
and TransactionTypeID = 17
order by cast(saledatetime as date)

select *
from StoreTransactions
where StoreID = 41009
and TransactionTypeID = 11
and cast(saledatetime as date) = '2011-12-12'

select *
from StoreTransactions
where StoreID = 41009
and TransactionTypeID = 17
and cast(saledatetime as date) = '2011-12-12'

select *
from StoreTransactions
where StoreID = 41009
and TransactionTypeID = 17
and cast(saledatetime as date) in
('2011-12-12',
'2011-12-19',
'2011-12-20',
'2011-12-27')

select * --into import.dbo.storetransactions_BimboCountRecordsRemoved_20120215
--delete
from datatrue_report.dbo.StoreTransactions
--from StoreTransactions
where StoreID = 41009
and TransactionTypeID = 11
and cast(saledatetime as date) in
('2011-12-12',
'2011-12-19',
'2011-12-20',
'2011-12-27')

select * from import.dbo.storetransactions_BimboCountRecordsRemoved_20120215


return
GO
