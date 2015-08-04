USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck_RollBack_20120221]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck_RollBack_20120221]
as


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
--/*

select supplierid, workingsource, storeid, productid, cast(saledatetime as date) as saledate, qty, SupplierInvoiceNumber, count(storetransactionid) as dupecount 
into #tempdupes
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and SaleDateTime > '11/30/2011'
and Qty <> 0
--and SupplierID = 40557
and workingsource in ('SUP-S','SUP-U')
group by  supplierid, workingsource, storeid, productid, cast(saledatetime as date), qty, SupplierInvoiceNumber
having count(storetransactionid) > 1


set @recremovedupes = CURSOR local fast_forward FOR
select  supplierid, workingsource, storeid, productid, cast(saledate as date) as saledate, qty, supplierinvoicenumber, dupecount
from #tempdupes
	
	open @recremovedupes
	
	fetch next from @recremovedupes into
			@supplierid
			,@workingsource
			,@storeid
			,@productid
			,@date
			,@qty
			,@supplierinvoicenumber
			,@dupecount
										
	while @@FETCH_STATUS = 0
		begin

print @dupecount

			update DataTrue_Main.dbo.StoreTransactions_Working set workingstatus = -6
			where supplierid = @supplierid
			and ltrim(rtrim(workingsource)) = @workingsource
			and StoreID  = @storeid
			and productid = @productid
			and CAST(saledatetime as date) = @date
			and Qty = @qty
			and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from DataTrue_Main.dbo.StoreTransactions_Working
				where supplierid = @supplierid
				and ltrim(rtrim(workingsource)) = @workingsource
				and StoreID  = @storeid
				and productid = @productid
				and CAST(saledatetime as date) = @date
				and Qty = @qty
				and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into
				@supplierid
				,@workingsource
				,@storeid
				,@productid
				,@date
				,@qty
				,@supplierinvoicenumber
				,@dupecount
		end
		
	close @recremovedupes
	deallocate @recremovedupes
	
return
GO
