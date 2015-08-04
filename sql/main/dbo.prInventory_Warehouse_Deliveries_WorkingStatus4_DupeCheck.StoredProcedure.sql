USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Warehouse_Deliveries_WorkingStatus4_DupeCheck]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery3.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\4\~vs3495.sql
CREATE procedure [dbo].[prInventory_Warehouse_Deliveries_WorkingStatus4_DupeCheck]
as


declare @recremovedupes cursor
declare @remtransactionid bigint
declare @remWarehouseid int
declare @remproductid int
declare @rembrandid int
declare @remsaledate date
declare @curWarehouseid int
declare @curproductid int
declare @curbrandid int
declare @cursaledate date
declare @firstrowpassed bit
declare @dupecount int
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @Warehousenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
declare @supplierid int
declare @workingsource nvarchar(50)
declare @Warehouseid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
--/*

update i set TransactionTypeID = case when WorkingSource = 'WHS-DB' then 5 else 8 end
--select *
from DataTrue_Main.dbo.WarehouseTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and EffectiveDateTime > '11/30/2011'
and TransactionTypeID is null
and workingsource in ('WHS-DB','WHS-CR')


update w set w.WorkingStatus = -6
--select *
from DataTrue_Main.dbo.WarehouseTransactions_Working w
inner join WarehouseTransactions t
on w.ChainID = t.ChainID
and w.WarehouseID = t.WarehouseID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
and w.SupplierID = t.SupplierID
and w.TransactionTypeID = t.TransactionTypeID
and CAST(w.EffectiveDateTime as date) = CAST(t.EffectiveDateTime as date)
and isnull(w.SupplierInvoiceNumber, '') = isnull(t.SupplierInvoiceNumber, '')
and w.WorkingStatus = 4
and w.Qty = t.qty

select supplierid, workingsource, Warehouseid, productid, cast(EffectiveDateTime as date) as saledate, qty, SupplierInvoiceNumber, count(Warehousetransactionid) as dupecount 
into #tempdupes
from DataTrue_Main.dbo.WarehouseTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and EffectiveDateTime > '11/30/2011'
and Qty <> 0
--and SupplierID = 40557
and workingsource in ('WHS-DB','WHS-CR')
group by  supplierid, workingsource, Warehouseid, productid, cast(EffectiveDateTime as date), qty, SupplierInvoiceNumber
having count(Warehousetransactionid) > 1


set @recremovedupes = CURSOR local fast_forward FOR
select  supplierid, workingsource, Warehouseid, productid, cast(saledate as date) as saledate, qty, supplierinvoicenumber, dupecount
from #tempdupes
	
	open @recremovedupes
	
	fetch next from @recremovedupes into
			@supplierid
			,@workingsource
			,@Warehouseid
			,@productid
			,@date
			,@qty
			,@supplierinvoicenumber
			,@dupecount
										
	while @@FETCH_STATUS = 0
		begin

print @dupecount

			update DataTrue_Main.dbo.WarehouseTransactions_Working set workingstatus = -6
			where supplierid = @supplierid
			and ltrim(rtrim(workingsource)) = @workingsource
			and WarehouseID  = @Warehouseid
			and productid = @productid
			and CAST(EffectiveDateTime as date) = @date
			and Qty = @qty
			and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
			and WarehouseTransactionID not in
			(
				select top 1 WarehouseTransactionID from DataTrue_Main.dbo.WarehouseTransactions_Working
				where supplierid = @supplierid
				and ltrim(rtrim(workingsource)) = @workingsource
				and WarehouseID  = @Warehouseid
				and productid = @productid
				and CAST(EffectiveDateTime as date) = @date
				and Qty = @qty
				and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
				order by WarehouseTransactionID
			 )
			 							
			fetch next from @recremovedupes into
				@supplierid
				,@workingsource
				,@Warehouseid
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
