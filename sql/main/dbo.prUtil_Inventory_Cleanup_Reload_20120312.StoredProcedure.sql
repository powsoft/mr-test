USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Cleanup_Reload_20120312]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Inventory_Cleanup_Reload_20120312]
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


--***************************How Many Count Dates********************************

select CAST(effectivedate as date), COUNT(recordid)
from datatrue_edi.dbo.Inbound846Inventory
where 1 = 1
and EdiName = 'LWS'
--and charindex('farm', filename) > 0
and PurposeCode = 'CNT'
group by CAST(effectivedate as date)
order by CAST(effectivedate as date)

--LWS supplierid = 41464

select *
from datatrue_edi.dbo.Inbound846Inventory
where 1 = 1
and EdiName = 'BIM'
--and charindex('farm', filename) > 0
and PurposeCode = 'CNT'
and CAST(effectivedate as date) = '1/2/2012'
order by purposecode

select *
from datatrue_edi.dbo.Inbound846Inventory
--where filename = '302508.msg'
where charindex('farmfresh-inv-mie0102', filename) > 0
and PurposeCode = 'CNT'
order by purposecode

select *
from StoreTransactions
where TransactionTypeID = 11
and SupplierID = 41465
and CAST(saledatetime as date) = '12/3/2011'

select *
from stores
where StoreIdentifier = '6102'

select distinct cast(saledatetime as date)
from StoreTransactions
where SupplierID = 41464
and TransactionTypeID = 11
order by cast(saledatetime as date)

select distinct cast(saledatetime as date)
from StoreTransactions
where SupplierID = 41464
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




--*************************************SYNC*************************************************************


select * into import.dbo.inventoryperpetual_20120122_AfterPEPSyncBeforeCounts from InventoryPerpetual

--inventory perpetual by supplier
select t.qty, i.OriginalQty, i.*
--update i set i.EffectiveDateTime = '2011-12-01 00:00:00.000' --i.OriginalQty = t.qty
--update i set i.OriginalQty = t.qty
from InventoryPerpetual i
inner join
(
select distinct storeid, ProductId, brandid, qty
from StoreTransactions
where SupplierID = 41465
and TransactionTypeID = 11
and CAST(saledatetime as date) = '12/3/2011'
) t
on i.StoreID = t.StoreID
and i.ProductID = t.ProductID
and i.BrandID = t.BrandID
where 1 = 1
and Qty <> i.OriginalQty
order by DateTimeCreated desc

select *
from StoreTransactions
where SupplierID = 41465
and TransactionTypeID = 11
and CAST(saledatetime as date) = '12/3/2011'

select distinct transactionstatus
--select *
--update t set transactionstatus = 2
from StoreTransactions t
where SupplierID = 41464
and TransactionTypeID = 11
and TransactionStatus = 0
and CAST(saledatetime as date) = '12/3/2011'

select *
from StoreTransactions
where SupplierID = 41464
and TransactionTypeID = 11
and CAST(saledatetime as date) = '12/3/2011'
and storeid = 40966	
and productid = 16397

select * into import.dbo.inventoryperpetual_20120224c from inventoryperpetual
select * into import.dbo.inventorycost_20120224 from inventorycost

select p.UnitPrice, t.SetupCost, *
from StoreTransactions t
inner join ProductPrices p
on t.StoreID = p.StoreID
and t.ProductID = p.ProductID
and t.SupplierID = p.supplierid
and p.ProductPriceTypeID = 3
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and t.SetupCost <> p.Unitprice
where t.SupplierID = 40557
and t.TransactionTypeID = 11


--inventory perpetual by supplier
select t.qty, i.OriginalQty, i.*
--select i.*
--update i set i.EffectiveDateTime = '2011-12-01 00:00:00.000' --i.OriginalQty = t.qty
--update i set i.OriginalQty = t.qty
--update i set i.Cost = t.RuleCost, i.Retail = t.ruleretail
from InventoryPerpetual i
inner join
(
select distinct storeid, ProductId, brandid, qty, rulecost, ruleretail
from StoreTransactions
where SupplierID = 40557
and TransactionTypeID = 11
and CAST(saledatetime as date) = '12/1/2011'
) t
on i.StoreID = t.StoreID
and i.ProductID = t.ProductID
and i.BrandID = t.BrandID
where 1 = 1
--and t.Qty <> i.OriginalQty
and i.Cost <> t.RuleCost
and t.RuleCost <> 0
and t.RuleCost is not null
order by DateTimeCreated desc


select *
	--update i set Deliveries = 0, Pickups = 0, sbtsales = 0, currentonhandqty = 0
	from InventoryPerpetual i
	inner join
	(
	select distinct storeid, ProductId, brandid
	from StoreTransactions
	where SupplierID = 40557
	and TransactionTypeID in (2, 5, 8)
	and SaleDateTime > '11/30/2011'
	--and StoreID = 40509
	--and ProductID = 5511
	) t
	on i.StoreID = t.StoreID
	and i.ProductID = t.ProductID
	and i.BrandID = t.BrandID


declare @rec cursor
declare @recordid int
--declare @storeid int
--declare @productid int
--declare @brandid int=0
declare @originalqty int
declare @loadqty int
declare @sbtsalestable int
declare @sbtsalesnew int
declare @deliveriesnew int
declare @pickupsnew int



set @rec = CURSOR local fast_forward FOR
	select i.RecordID, i.StoreID, i.ProductID, i.OriginalQty, i.SBTSales
	--select *
	from InventoryPerpetual i
	inner join
	(
	select distinct storeid, ProductId, brandid
	from StoreTransactions
	where SupplierID = 40557
	and TransactionTypeID in (2)
	and SaleDateTime > '11/30/2011'
	--and StoreID = 40509
	--and ProductID = 5511
	) t
	on i.StoreID = t.StoreID
	and i.ProductID = t.ProductID
	and i.BrandID = t.BrandID
	
open @rec

fetch next from @rec into 
	@recordid
	,@storeid
	,@productid
	,@originalqty
	,@sbtsalestable
	--,@loadqty
	
while @@FETCH_STATUS = 0
	begin

		set @sbtsalesnew = 0
		
		select @sbtsalesnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16)
		and cast(SaleDateTime as date) >= '12/1/2011'
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		
		if @sbtsalesnew is null
			set @sbtsalesnew = 0
			
		set @deliveriesnew = 0
		
		select @deliveriesnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4)		
		and cast(SaleDateTime as date) >= '12/1/2011'
		and TransactionStatus in (2, 810)
		and RuleCost is not null
				
		if @deliveriesnew is null
			set @deliveriesnew = 0
			
			
		set @pickupsnew = 0
		
		select @pickupsnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8)		
		and cast(SaleDateTime as date) >= '12/1/2011'
		and TransactionStatus in (2, 810)
		and RuleCost is not null
				
		if @pickupsnew	is null
			set @pickupsnew = 0	

print @originalqty
--print @loadqty
print @sbtsalestable
print @sbtsalesnew	
print  @deliveriesnew
print @pickupsnew

		update i set i.sbtsales = @sbtsalesnew, i.Deliveries = @deliveriesnew, i.Pickups = @pickupsnew,
		i.currentonhandqty = @originalqty - @sbtsalesnew + @deliveriesnew - @pickupsnew
		from InventoryPerpetual i
		where i.RecordID = @recordid
		
	
		fetch next from @rec into 
			@recordid
			,@storeid
			,@productid
			,@originalqty
			,@sbtsalestable	
			--,@loadqty
	end
	
close @rec
deallocate @rec

select * from StoreTransactions where StoreTransactionID = 9334633

select * into import.dbo.inventoryperpetual_20120120 from inventoryperpetual


select i.QtyAvailableAtThisCost, t.CurrentOnHandQty, i.*
--update i set i.QtyAvailableAtThisCost = t.CurrentOnHandQty
from Inventorycost i
inner join inventoryperpetual t

on i.StoreID = t.StoreID
and i.ProductID = t.ProductID
and i.BrandID = t.BrandID
where 1 = 1
and i.QtyAvailableAtThisCost <> t.CurrentOnHandQty
--and Qty <> i.OriginalQty
order by DateTimeCreated desc


	select i.* --i.RecordID, i.StoreID, i.ProductID, i.OriginalQty, i.SBTSales, t.Qty
	--update i set i.supplierid = 41464
	from InventoryCost i
	inner join
	(
	select distinct storeid, ProductId, brandid
	from StoreTransactions
	where SupplierID = 41464
	and TransactionTypeID = 11
	) t
	on i.StoreID = t.StoreID
	and i.ProductID = t.ProductID
	and i.BrandID = t.BrandID
	
	select c.supplierid, c.QtyAvailableAtThisCost, p.CurrentOnHandQty, p.*, c.*
	--update p set CurrentOnHandQty = QtyAvailableAtThisCost
	from InventoryCost c
	inner join InventoryPerpetual p
	on c.StoreID = p.StoreID
	and c.ProductID = p.ProductID
	and c.BrandID = p.brandid
	and c.SupplierID = 41464
	where 1 = 1
	--and c.QtyAvailableAtThisCost <> p.CurrentOnHandQty
	order by c.supplierid --p.CurrentOnHandQty
	
	select SUM(qty)
	from StoreTransactions
	where StoreID = 40945
	and ProductID = 16680
	and TransactionTypeID in (2,6,7,16)
	
	
	
--**************************LOAD ALL COUNTS**************************
declare @reccount cursor
declare @countdate date
declare @cntsupplierid int=40562
declare @initialcountdate as date='12/1/2012'

set @reccount = CURSOR local fast_forward FOR
	select distinct CAST(saledatetime as date)
	from StoreTransactions t
	where SupplierID = @cntsupplierid
	and t.TransactionTypeID = 11
	and CAST(saledatetime as date) > @initialcountdate
	
	
return
GO
