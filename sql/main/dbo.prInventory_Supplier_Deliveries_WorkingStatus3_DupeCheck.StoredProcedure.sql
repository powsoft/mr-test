USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus3_DupeCheck]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus3_DupeCheck]
as

--*****************************Dupes in this batch*******************************************
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
declare @workingsource nvarchar(50)
declare @workingqty int
declare @supplierid int

select distinct storeid, productid, brandid, supplierid, cast(saledatetime as date) as [date], workingsource, Qty
		into #tempbatchdupes
		from storetransactions_working
		where workingstatus = 3
		and WorkingSource in ('SUP-S','SUP-U')
		group by storeid, productid, brandid, supplierid, cast(saledatetime as date), workingsource, qty
		having count(storetransactionid) > 1
		
if @@ROWCOUNT > 0
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select storeid
		,productid
		,brandid
		,supplierid
		,cast([date] as date)
		,workingsource
		,Qty
	from #tempbatchdupes
	order by storeid
		,productid
		,brandid
		,supplierid
		,cast([DATE] as date)
		,workingsource
		,qty
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource
										,@workingqty
									
	while @@FETCH_STATUS = 0
		begin

			update storetransactions_working set WorkingStatus = -6
			where StoreTransactionID in
			(
				select StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 3
			 )
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 3
				order by RecordID_EDI_852
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource	
										,@workingqty
		end
		
	close @recremovedupes
	deallocate @recremovedupes
end
--******************Remove Dupes End**********************************

--*****************************Dupes to StoreTransactions Records*****************************
--declare @recremovedupes cursor
--declare @remtransactionid bigint
--declare @remstoreid int
--declare @remproductid int
--declare @rembrandid int
--declare @remsaledate date
--declare @curstoreid int
--declare @curproductid int
--declare @curbrandid int
--declare @cursaledate date
--declare @firstrowpassed bit
declare @dupecount int
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @storenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
--declare @supplierid int
--declare @workingsource nvarchar(50)
declare @storeid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
--/*

update i set TransactionTypeID = case when WorkingSource = 'SUP-S' then 5 when WorkingSource = 'SUP-U' then 8 else null end
--select *
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 3
and SaleDateTime > '11/30/2011'
and TransactionTypeID is null
and workingsource in ('SUP-S','SUP-U')

--select *
update w set w.WorkingStatus = -6
from DataTrue_Main.dbo.StoreTransactions_Working w
inner join StoreTransactions t
on w.ChainID = t.ChainID
and w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
and w.SupplierID = t.SupplierID
and w.TransactionTypeID = t.TransactionTypeID
and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
and w.Qty = t.qty
and w.WorkingStatus = 3

/*
select supplierid, workingsource, storeid, productid, cast(saledatetime as date) as saledate, qty, SupplierInvoiceNumber, count(storetransactionid) as dupecount 
into #tempdupes
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 3
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
*/	
return
GO
