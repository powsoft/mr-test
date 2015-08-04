USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Warehouse_Counts_WorkingStatus4_DupeCheck]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prInventory_Warehouse_Counts_WorkingStatus4_DupeCheck]
as

--*****************************Dupes in this batch*******************************************
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
declare @workingsource nvarchar(50)
declare @workingqty int
declare @supplierid int

select distinct Warehouseid, productid, brandid, supplierid, cast(Effectivedatetime as date) as [date], workingsource--, Qty
		into #tempbatchdupes
		--select *
		from Warehousetransactions_working
		where 1 = 1
		and workingstatus = 4
		and charindex('INV', WorkingSource) > 0
		group by Warehouseid, productid, brandid, supplierid, cast(Effectivedatetime as date), workingsource--, qty
		having count(Warehousetransactionid) > 1
		
if @@ROWCOUNT > 0
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select Warehouseid
		,productid
		,brandid
		,supplierid
		,cast([date] as date)
		,workingsource
		--,Qty
	from #tempbatchdupes
	order by Warehouseid
		,productid
		,brandid
		,supplierid
		,cast([DATE] as date)
		,workingsource
		--,qty
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remWarehouseid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource
										--,@workingqty
									
	while @@FETCH_STATUS = 0
		begin

			update Warehousetransactions_working set WorkingStatus = -6
			where WarehouseTransactionID in
			(
				select WarehouseTransactionID from WarehouseTransactions_Working
				where WarehouseID = @remWarehouseid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(Effectivedatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
			 )
			and WarehouseTransactionID not in
			(
				select top 1 WarehouseTransactionID from WarehouseTransactions_Working
				where WarehouseID = @remWarehouseid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(Effectivedatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
				order by Qty desc
				--order by RecordID_EDI_852
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remWarehouseid
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

--*****************************Dupes to WarehouseTransactions Records*****************************
--declare @recremovedupes cursor
--declare @remtransactionid bigint
--declare @remWarehouseid int
--declare @remproductid int
--declare @rembrandid int
--declare @remsaledate date
--declare @curWarehouseid int
--declare @curproductid int
--declare @curbrandid int
--declare @cursaledate date
--declare @firstrowpassed bit
declare @dupecount int
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @Warehousenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
--declare @supplierid int
--declare @workingsource nvarchar(50)
declare @Warehouseid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
--/*

update i set TransactionTypeID = 11
--select *
from DataTrue_Main.dbo.WarehouseTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4 
--and WarehouseIDCorrection = -27
and Effectivedatetime > '11/30/2011'
and TransactionTypeID is null
--and CAST(Effectivedatetime as date) = '3/12/2012'
and charindex('INV', workingsource) > 0

update w set w.WorkingStatus = -6
--select * --top 100 * from DataTrue_Main.dbo.WarehouseTransactions_Working
from DataTrue_Main.dbo.WarehouseTransactions_Working w
inner join WarehouseTransactions t
on w.ChainID = t.ChainID
and w.WarehouseID = t.WarehouseID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
and w.SupplierID = t.SupplierID
and w.TransactionTypeID = t.TransactionTypeID
and CAST(w.Effectivedatetime as date) = CAST(t.Effectivedatetime as date)
and charindex('INV', workingsource) > 0
--and w.supplierId = 40561
--and cast(w.Effectivedatetime as date)='2/27/2012'
and t.transactiontypeid=11
--and w.Qty = t.qty
and w.WorkingStatus = 4
--and (w.WorkingStatus = 3 or WarehouseIDCorrection = -27)

/*
select * from WarehouseTransactions t
where t.supplierId = 40557
and cast(t.Effectivedatetime as date)='3/5/2012'
and t.transactiontypeid=11
and Warehouseid in
(select Warehouseid from Warehouses where ltrim(rtrim(custom1)) = 'Albertsons - SCAL')

*/

	
return
GO
