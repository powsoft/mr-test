USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Supplier_Counts_WorkingStatus3_DupeCheck]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_Supplier_Counts_WorkingStatus3_DupeCheck]
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

select distinct storeid, productid, brandid, supplierid, cast(saledatetime as date) as [date], workingsource--, Qty
		into #tempbatchdupes
		--select *
		from storetransactions_working
		where 1 = 1
		and workingstatus = 3
		and charindex('INV', WorkingSource) > 0
		group by storeid, productid, brandid, supplierid, cast(saledatetime as date), workingsource--, qty
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
		--,Qty
	from #tempbatchdupes
	order by storeid
		,productid
		,brandid
		,supplierid
		,cast([DATE] as date)
		,workingsource
		--,qty
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource
										--,@workingqty
									
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
				order by Qty desc
				--order by RecordID_EDI_852
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource	
										--,@workingqty
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

update i set TransactionTypeID = 11
--select *
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 3 
--and StoreIDCorrection = -27
and SaleDateTime > '11/30/2011'
and TransactionTypeID is null
--and CAST(saledatetime as date) = '3/12/2012'
and charindex('INV', workingsource) > 0

update w set w.WorkingStatus = -6
--select * --top 100 * from DataTrue_Main.dbo.StoreTransactions_Working
from DataTrue_Main.dbo.StoreTransactions_Working w
inner join StoreTransactions t
on w.ChainID = t.ChainID
and w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
and w.SupplierID = t.SupplierID
and w.TransactionTypeID = t.TransactionTypeID
and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
and charindex('INV', workingsource) > 0
--and w.supplierId = 40561
--and cast(w.saledatetime as date)='2/27/2012'
and t.transactiontypeid=11
--and w.Qty = t.qty
and w.WorkingStatus = 3
--and (w.WorkingStatus = 3 or StoreIDCorrection = -27)

/*
select * from StoreTransactions t
where t.supplierId = 40557
and cast(t.saledatetime as date)='3/5/2012'
and t.transactiontypeid=11
and storeid in
(select storeid from stores where ltrim(rtrim(custom1)) = 'Albertsons - SCAL')

*/

	
return
GO
