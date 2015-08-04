USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_Newspapers_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery13.sql|7|0|C:\Users\charlie.clark\AppData\Local\Temp\4\~vsE0D5.sql
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_Newspapers_PRESYNC_20150329]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable

set @MyID = 7586

DECLARE @ProcessID INT
SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'

begin try

--update w
--set w.TransactionStatus = 5
----select *
--from StoreTransactions_Working w
--where ProcessingErrorDesc IS null
--and workingstatus = 4
--and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
--and Qty = 0

/*
select *
--select distinct supplierid
--select distinct saledatetime
from [dbo].[StoreTransactions]
where TransactionTypeID in (5, 8)
and SupplierID = 40557
--and SaleDateTime = '2012-01-26 00:00:00.000'
order by saledatetime desc

select *
--select distinct supplierid
--select distinct saledatetime
from [dbo].[StoreTransactions_working]
where workingstatus = 4
and WorkingSource in ('SUP-S', 'SUP-U')
and SupplierID = 40557
order by saledatetime
*/

--GET FIXED SUP MISMATCH RECORDS FROM EXCEPTIONS
DECLARE @FixedSuppliersTable TABLE (ChainID INT, SupplierID INT, StoreID INT, ProductID INT, SaleDateTime DATETIME, TransactionTypeID INT)

UPDATE w
SET w.WorkingStatus = 4, w.ProcessID = @ProcessID 
OUTPUT inserted.ChainID, inserted.SupplierID, inserted.StoreID, inserted.ProductID, inserted.SaleDateTime, inserted.TransactionTypeID INTO @FixedSuppliersTable (ChainID, SupplierID, StoreID, ProductID, SaleDateTime, TransactionTypeID)
FROM DataTrue_Main.dbo.StoreTransactions_Working AS w
INNER JOIN DataTrue_Main.dbo.storesetup AS s
ON w.SupplierID = s.SupplierID
AND w.StoreID = s.StoreID
AND w.ProductID = s.ProductID
AND w.SaleDateTime BETWEEN s.ActiveStartDate and s.ActiveLastDate
AND w.WorkingStatus = -26

UPDATE w
SET w.WorkingStatus = 4, w.ProcessID = @ProcessID 
OUTPUT inserted.ChainID, inserted.SupplierID, inserted.StoreID, inserted.ProductID, inserted.SaleDateTime, inserted.TransactionTypeID INTO @FixedSuppliersTable (ChainID, SupplierID, StoreID, ProductID, SaleDateTime, TransactionTypeID)
FROM DataTrue_Main.dbo.StoreTransactions_Working AS w
INNER JOIN DataTrue_Main.dbo.ProductPrices AS p
ON w.SupplierID = p.SupplierID
AND w.StoreID = p.StoreID
AND w.ProductID = p.ProductID
AND w.SaleDateTime BETWEEN p.ActiveStartDate and p.ActiveLastDate
AND w.WorkingStatus = -28

UPDATE ex
SET ex.ExceptionStatus = 1
FROM DataTrue_Main.dbo.StoreTransactions_Exceptions AS ex
INNER JOIN @FixedSuppliersTable AS fixed
ON ex.ChainID = fixed.ChainID
AND ex.SupplierID = fixed.SupplierID
AND ex.StoreId = fixed.StoreID
AND ex.ProductID = fixed.ProductID
AND ex.SaleDateTime = fixed.SaleDateTime
AND ex.TransactionTypeId = fixed.TransactionTypeID

select distinct StoreTransactionID, saledatetime
into #tempStoreTransaction
--select *
--select distinct supplierid
--select distinct top 1 StoreTransactionID, saledatetime
--select distinct saledatetime
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
--and WorkingSource in ('SUP-S')
--and WorkingSource in ('SUP-U')
--and CAST(saledatetime as date) = '1/26/2012'
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
and ProcessID = @ProcessID
--and SupplierID = 40558
--and SupplierID = 40557
--and SupplierID = 41464
--and SupplierID not in (40558, 41464)
--and SupplierID = 40561
--and SupplierID = 40562
order by StoreTransactionID


--******************Remove Dupes Begin*******************************
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
/*
select storeid, productid, brandid, cast(saledatetime as date) as [date], workingsource, Qty
		from storetransactions_working
		where workingstatus = 4
		and WorkingSource in ('SUP-S','SUP-U')
		group by storeid, productid, brandid, cast(saledatetime as date), workingsource, qty--, isnull(supplierinvoicenumber, '')
		having count(storetransactionid) > 1
		
if @@ROWCOUNT > 0
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select distinct w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
		,w.workingsource
		,w.Qty
	from storetransactions_working w
	inner join #tempStoreTransaction tmp
	on w.storetransactionid = tmp.storetransactionid
	where WorkingSource in ('SUP-S', 'SUP-U')
	and tmp.StoreTransactionID in
	(
	select storetransactionid
	from storetransactions_working w
	inner join
		(select storeid, productid, brandid, cast(saledatetime as date) as [date], workingsource, Qty
		from storetransactions_working
		where workingstatus = 4
		group by storeid, productid, brandid, cast(saledatetime as date), workingsource, qty
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid 
	and cast(w.saledatetime as date) = cast(s.date as date) 
	and w.workingsource = s.workingsource and w.Qty = s.qty
	)
	order by w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
		,w.workingsource
		,w.qty
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate
										,@workingsource
										,@workingqty
/*
	set @curstoreid = @remstoreid
	set @curproductid = @remproductid
	set @curbrandid = @rembrandid
	set @cursaledate = @remsaledate	
	set @firstrowpassed = 0					
*/										
	while @@FETCH_STATUS = 0
		begin
/*		
			if @firstrowpassed = 0
				begin
					set @firstrowpassed = 1
				end
			else
				begin
					delete #tempStoreTransaction where storetransactionid = @remtransactionid
				end
*/
			delete from #tempStoreTransaction
			where StoreTransactionID in
			(
				select StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
			 )
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate
										,@workingsource	
										,@workingqty
/*
			if @@FETCH_STATUS = 0
			  begin							
				if @curstoreid <> @remstoreid
					or @curproductid <> @remproductid
					or @curbrandid <> @rembrandid
					or @cursaledate <> @remsaledate	
					  begin
						set @curstoreid = @remstoreid
						set @curproductid = @remproductid
						set @curbrandid = @rembrandid
						set @cursaledate = @remsaledate	
						set @firstrowpassed = 0					
					  end	
			  end
*/
		end
		
	close @recremovedupes
	deallocate @recremovedupes
end
--******************Remove Dupes End**********************************
*/
--declare @transidtable StoretransactionIDTable
insert @transidtable
select StoreTransactionID from #tempStoreTransaction
--exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV

begin transaction

set @loadstatus = 5

--update transaction type
update t
set t.TransactionTypeID = 
case when WorkingSource = 'SUP-S' then 5
	 when WorkingSource = 'SUP-U' then 8
	 when WorkingSource = 'SUP-O' then 39
else null end
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.TransactionTypeID is null
and t.ProcessID = @ProcessID

update t set WorkingStatus = -5
--case when t.TransactionTypeID in (10,11) then 5 else -5 end
, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is null
and t.ProcessID = @ProcessID

--***************Promo Lookup Start**************************

update t set t.PromoAllowance = p.UnitPrice,
t.PromoTypeID = P.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and t.ProcessID = @ProcessID

--***************Cost Lookup Start**************************

--First look for exact match for all entities
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 --in 
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --5 is Supplier Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and t.ProcessID = @ProcessID

commit transaction

--***************Cost Lookup End****************************

exec prApplyCostRules_NewsPapers @transidtable, 2 --1=POS, 2=SUP, 3=INV

exec prApplySupplierRules_NewsPapers @transidtable, 2

begin transaction

--update CostMisMatch
update t set t.CostMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost <> t.ReportedCost
or t.SetupCost is null or t.ReportedCost is null
--or (t.SetupCost is null and t.ReportedCost is null)
and t.ProcessID = @ProcessID

--update RetailMisMatch
update t set t.RetailMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupRetail <> t.ReportedRetail
or t.SetupRetail is null or t.ReportedRetail is null
--or (t.SetupRetail is null and t.ReportedRetail is null)
and t.ProcessID = @ProcessID


/*
--***************Cost Rules Start***************************
--If Type is Retailer and B is null, 
then F=D
--If Type is Retailer and C is null, then G=E
update t
set RuleCost =
case when SetupCost IS NULL then ReportedCost
		when SetupCost is not null and ReportedCost > SetupCost then ReportedCost
 else SetupCost end,
 RuleRetail =
case when SetupRetail IS NULL then ReportedRetail
		when SetupRetail is not null and ReportedRetail > SetupRetail then ReportedRetail
 else SetupRetail end
 from [dbo].[StoreTransactions_Working] t
 inner join #tempStoreTransaction tmp
 on t.StoreTransactionID = tmp.StoreTransactionID

--***************Cost Rules End***************************
*/

--update [dbo].[StoreTransactions_Working] set SupplierID = 0 where SupplierID is null
--update [dbo].[StoreTransactions_Working] set ProductID = 100 where ProductID is null
--update [dbo].[StoreTransactions_Working] set SourceID = 0 where SourceID is null

		--select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed, CAST(4 as int) as Workingstatus
		--into #tempsup		
		--from DataTrue_Main.dbo.StoreTransactions_Working w
		--where charindex('POS', WorkingSource) > 0
		--and WorkingStatus = 4

		--select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed
		--into #tempsup2
		--from DataTrue_Main.dbo.StoreTransactions
		--where 1 = 1
		--and TransactionTypeID in (2, 6)
		--and CAST(SaleDateTime as date) in 
		--(select distinct CAST(SaleDateTime as date) from #tempsup)	

insert into [dbo].[StoreTransactions]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[RuleCost]
           ,[RuleRetail]
			,[CostMisMatch]
			,[RetailMisMatch]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail]
           ,[InvoiceDueDate]
           ,[Route]
           ,[SupplierItemNumber]
           ,[ProductDescriptionReported]
           ,[UOM]
           ,[ProcessID]
           ,[EDIRecordID]
           )
select		S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,s.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'POS' then 2 when S.[WorkingSource] = 'SUP' then 5 else 0 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[SetupCost]
           ,S.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedCost]
           ,S.[ReportedRetail]
           ,S.[RuleCost]
           ,S.[RuleRetail]
			,s.[CostMisMatch]
			,s.[RetailMisMatch]
           ,0
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end
           ,s.[InvoiceDueDate]
           ,[Route]
           ,[ItemSKUReported]
           ,[ItemDescriptionReported]
           ,[UOM]
           ,[ProcessID]
           ,RecordID_EDI_852
from [dbo].[StoreTransactions_Working] s
inner join #tempStoreTransaction tmp
on s.StoreTransactionID = tmp.StoreTransactionID
where s.transactiontypeid in (5, 8, 39)
and s.WorkingStatus = 4
and s.ProcessID = @ProcessID


/*
MERGE INTO [dbo].[StoreTransactions] t

USING (select w.[StoreTransactionID]
	  ,[ChainID] as ChainID
	  ,[StoreID] as StoreID
      ,[ProductID] as ProductID
      ,[SupplierID] as SupplierID
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,w.[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[WorkingSource]
      ,[TrueCost]
      ,[TrueRetail]
from [dbo].[StoreTransactions_Working] w
inner join #tempStoreTransaction tmp
on w.StoreTransactionID = tmp.StoreTransactionID
where w.transactiontypeid in (5)) S
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
--and t.TransactionTypeID = s.TransactionTypeID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID in (5, 20)
and t.Reversed = 0
--and charindex(t.ProcessingErrorDesc, 'REVERSED') < 1
--select cast(getdate() as date)
/*
and s.StoreTransactionID not in
(
select storetransactionid
from storetransactions_working w
inner join
	(select storeid, productid, brandid, cast(z.saledatetime as date) as [date]
	from storetransactions_working z
	group by storeid, productid, brandid, cast(z.saledatetime as date)
	having count(storetransactionid) > 1) s
on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
)
*/

WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))

WHEN NOT MATCHED 

        THEN INSERT     
           --(
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[RuleCost]
           ,[RuleRetail]
			,[CostMisMatch]
			,[RetailMisMatch]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail])
     VALUES
     --(S.[StoreID]
     (S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,s.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'POS' then 2 when S.[WorkingSource] = 'SUP' then 5 else 0 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[SetupCost]
           ,S.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedCost]
           ,S.[ReportedRetail]
           ,S.[RuleCost]
           ,S.[RuleRetail]
			,s.[CostMisMatch]
			,s.[RetailMisMatch]
           ,0
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end);
--*********************Pickups**********************************


MERGE INTO [dbo].[StoreTransactions] t

USING (select w.[StoreTransactionID]
	  ,[ChainID] as ChainID
	  ,[StoreID] as StoreID
      ,[ProductID] as ProductID
      ,[SupplierID] as SupplierID
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,w.[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[WorkingSource]
      ,[TrueCost]
      ,[TrueRetail]
from [dbo].[StoreTransactions_Working] w
inner join #tempStoreTransaction tmp
on w.StoreTransactionID = tmp.StoreTransactionID
where w.transactiontypeid in (8)) S
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
--and t.TransactionTypeID = s.TransactionTypeID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID in (8, 21)
and t.Reversed = 0
--and charindex(t.ProcessingErrorDesc, 'REVERSED') < 1
--select cast(getdate() as date)
/*
and s.StoreTransactionID not in
(
select storetransactionid
from storetransactions_working w
inner join
	(select storeid, productid, brandid, cast(z.saledatetime as date) as [date]
	from storetransactions_working z
	group by storeid, productid, brandid, cast(z.saledatetime as date)
	having count(storetransactionid) > 1) s
on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
)
*/

WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))

WHEN NOT MATCHED 

        THEN INSERT     
           --(
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[RuleCost]
           ,[RuleRetail]
			,[CostMisMatch]
			,[RetailMisMatch]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail])
     VALUES
     --(S.[StoreID]
     (S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,s.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'POS' then 2 when S.[WorkingSource] = 'SUP' then 5 else 0 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[SetupCost]
           ,S.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedCost]
           ,S.[ReportedRetail]
           ,S.[RuleCost]
           ,S.[RuleRetail]
			,s.[CostMisMatch]
			,s.[RetailMisMatch]
           ,0
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end);
*/
--*********************Pickups**********************************
		commit transaction
/*
--******************************Handle Multiple Records with Same Assignment Start*****************************************
declare @recdupes cursor
declare @dupetransactionid bigint

set @recdupes = cursor local fast_forward for
	select storetransactionid from #tempStoreTransaction tmp
	where tmp.StoreTransactionID in
	(
	select storetransactionid
	from storetransactions_working w
	inner join
		(select storeid, productid, brandid, cast(saledatetime as date) as [date]
		from storetransactions_working
		group by storeid, productid, brandid, cast(saledatetime as date)
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
	)
	order by tmp.saledatetime
	
open @recdupes

fetch next from @recdupes into @dupetransactionid

while @@fetch_status = 0
	begin
--print @dupetransactionid

begin transaction
-----------------------------------------------------------------------------
MERGE INTO [dbo].[StoreTransactions] t

USING (select w.[StoreTransactionID]
	  ,[ChainID] as ChainID
	  ,[StoreID] as StoreID
      ,[ProductID] as ProductID
      ,[SupplierID] as SupplierID
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,w.[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TransactionStatus]
      ,[IsProcessedInSystem]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[WorkingSource]
      ,[TrueCost]
      ,[TrueRetail]
from [dbo].[StoreTransactions_Working] w
inner join #tempStoreTransaction tmp
on w.StoreTransactionID = tmp.StoreTransactionID) S
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.TransactionTypeID = s.TransactionTypeID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and charindex(t.ProcessingErrorDesc, 'REVERSED') < 1
--select cast(getdate() as date)
and s.StoreTransactionID = @dupetransactionid

WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))

WHEN NOT MATCHED 

        THEN INSERT     
           --(
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[RuleCost]
           ,[RuleRetail]
			,[CostMisMatch]
			,[RetailMisMatch]
           ,[TransactionStatus]
           ,[IsProcessedInSystem]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail])
     VALUES
     --(S.[StoreID]
     (S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,s.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'POS' then 2 when S.[WorkingSource] = 'SUP' then 5 else 0 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[SetupCost]
           ,S.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedCost]
           ,S.[ReportedRetail]
           ,S.[RuleCost]
           ,S.[RuleRetail]
			,s.[CostMisMatch]
			,s.[RetailMisMatch]
           ,0
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end);

		update storetransactions_working set workingstatus = 5 where storetransactionid = @dupetransactionid

		commit transaction

-----------------------------------------------------------------------------
		fetch next from @recdupes into @dupetransactionid
	end
	
close @recdupes
deallocate @recdupes
	
	
*/	
	

--******************************Handle Multiple Records with Same Assignment End*****************************************

/*           
update t set TrueCost = RuleCost, TrueRetail = RuleRetail
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.CostMisMatch = 0 and t.RetailMisMatch = 0
*/

--declare @MyID int declare @errormessage varchar(4500) declare @errorlocation varchar(255) declare @errorsenderstring nvarchar(255)

/*
--remove cdc records for the temporary storage of transactionid in ProcessErrorDesc
select StoreTransactionID
		from StoreTransactions
		where len(ProcessingErrorDesc) > 0
		
if @@ROWCOUNT > 0
	begin
		waitfor delay '0:0:5'
		
		delete from cdc.dbo_StoreTransactions_CT
			where StoreTransactionID in
				(select StoreTransactionID
				from StoreTransactions
				where len(ProcessingErrorDesc) > 0)
	end
*/	

delete from CDCControl where ProcessID = @MyID

/*
delete
from StoreTransactions t
--inner join #tempStoreTransaction tmp
--on cast(t.ProcessingErrorDesc as bigint) = tmp.StoreTransactionID
where t.Qty = 0
and (len(t.ProcessingErrorDesc) = 0 or t.ProcessingErrorDesc is null)
and isnumeric(t.ProcessingErrorDesc) > 0
*/
	
declare @rec cursor
declare @workingtransactionidstring nvarchar(100)
declare @transactionid bigint
declare @relatedcount smallint
declare @existingpostransactionupdatelimitstring nvarchar(10)
declare @existingpostransactionupdatelimit smallint
declare @oldsetupcost money
declare @oldsetupretail money
declare @oldreportedcost money
declare @oldreportedretail money
declare @oldqty int
declare @oldsupplierid int
declare @newsetupcost money
declare @newsetupretail money
declare @newreportedcost money
declare @newreportedretail money
declare @newqty int
declare @newsupplierid int
declare @reversingtransactionid bigint
declare @lastprocessingerrordesc nvarchar(255)
/*
set @rec = CURSOR local fast_forward FOR
	select t.StoreTransactionID, t.ProcessingErrorDesc,
	isnull(t.SetupCost,0), isnull(t.SetupRetail,0), isnull(t.ReportedCost,0), isnull(t.ReportedRetail,0),
	t.Qty, t.SupplierID
	from StoreTransactions t
	inner join #tempStoreTransaction tmp
	on cast(t.ProcessingErrorDesc as bigint) = tmp.StoreTransactionID
	where len(t.ProcessingErrorDesc) > 0
	and isnumeric(t.ProcessingErrorDesc) > 0
	
open @rec

fetch next from @rec into @transactionid
	,@workingtransactionidstring
	,@oldsetupcost
	,@oldsetupretail
	,@oldreportedcost
	,@oldreportedretail
	,@oldqty
	,@oldsupplierid

set @lastprocessingerrordesc = ''

if @@FETCH_STATUS = 0
	begin
		select @existingpostransactionupdatelimitstring = v.AttributeValue
		--select *
		from AttributeDefinitions d
		inner join AttributeValues v
		on d.AttributeID = v.AttributeID
		where d.AttributeName = 'ExistingSUPTransactionUpdateLimit'
		
		set @existingpostransactionupdatelimit = cast(@existingpostransactionupdatelimitstring as smallint)

	end

while @@FETCH_STATUS = 0
	begin
	
	if @workingtransactionidstring <> @lastprocessingerrordesc
	begin
	begin transaction
		set @relatedcount = 0
		
		select @relatedcount = COUNT(StoreTransactionID) from RelatedTransactions where StoreTransactionID = @transactionid
		
		If @relatedcount < @existingpostransactionupdatelimit
			begin
			
			--select * from [dbo].[RelatedTransactions]
				INSERT INTO [dbo].[RelatedTransactions]
						   ([WorkingTransactionID]
						   ,[StoreTransactionID]
						   ,[Status]
						   ,[RelationshipTypeID])
					 VALUES
						   (CAST(@workingtransactionidstring as bigint)
						   ,@transactionid
						   ,0 --<Status, smallint,>
						   ,1)
--print @workingtransactionidstring						   
				select @newsetupcost = isnull(setupcost,0)
						,@newsetupretail = isnull(setupretail,0)
						,@newreportedcost = isnull(reportedcost,0)
						,@newreportedretail = isnull(reportedretail,0)
						,@newqty = isnull(qty,0)
						,@newsupplierid = isnull(supplierid,0)
				from StoreTransactions_Working
				where StoreTransactionID = CAST(@workingtransactionidstring as bigint)
/*				
				if @newsetupcost = @oldsetupcost
						and @newsetupretail = @oldsetupretail
						and @newreportedcost = @oldreportedcost
						and @newreportedretail = @oldreportedretail
						--and @newqty = @oldqty
						and @newsupplierid = @oldsupplierid	
					begin
						if @newqty <> @oldqty --Qty to add to saledate
							begin
								INSERT INTO [dbo].[StoreTransactions]
										   ([ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,[TransactionTypeID]
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,[Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,[TrueCost]
										   ,[TrueRetail]
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[WorkingTransactionID])
									 select [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,case when TransactionTypeID = 5 then 4 else 13 end --4 --Appended SUP transaction
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,[Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
										   ,case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,CAST(@workingtransactionidstring as bigint)
										   from StoreTransactions_Working w
										where w.StoreTransactionID = CAST(@workingtransactionidstring as bigint)
										
								update t set t.ProcessingErrorDesc = ''
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid							
							end
						else --exact duplicate
							begin
								update t set t.ProcessingErrorDesc = ''
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid
								
								update StoreTransactions_Working set WorkingStatus = -6 where StoreTransactionID = CAST(@workingtransactionidstring as bigint)
							end
					
					end			   
					*/
					/*	   
				if @newsetupcost <> @oldsetupcost
						or @newsetupretail <> @oldsetupretail
						or @newreportedcost <> @oldreportedcost
						or @newreportedretail <> @oldreportedretail
						or @newsupplierid <> @oldsupplierid	
					begin
					*/
								set @reversingtransactionid = null
					
					
								INSERT INTO [dbo].[StoreTransactions]
										   ([ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,[TransactionTypeID]
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,[Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,[TrueCost]
										   ,[TrueRetail]
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[WorkingTransactionID]
										   ,[InvoiceDueDate])
									 select [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,case when TransactionTypeId in (5, 20) then 9 else 14 end
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,-1 * [Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
										   ,case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[WorkingTransactionID]
										   ,[InvoiceDueDate]
										   from StoreTransactions
										where StoreTransactionID = @transactionid
										
								set @reversingtransactionid = SCOPE_IDENTITY()
								
								update t set t.ProcessingErrorDesc = 'REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
								,Reversed = 1
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid
					

															
								INSERT INTO [dbo].[StoreTransactions]
										   ([ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,[TransactionTypeID]
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,[Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,[TrueCost]
										   ,[TrueRetail]
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[WorkingTransactionID]
										   ,[InvoiceDueDate])
									 select [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,case when TransactionTypeId = 5 then 20 else 21 end
										   ,[ProductPriceTypeID]
										   ,[BrandID]
										   ,[Qty]
										   ,[SetupCost]
										   ,[SetupRetail]
										   ,[SaleDateTime]
										   ,[UPC]
										   ,[ReportedCost]
										   ,[ReportedRetail]
										   ,[RuleCost]
										   ,[RuleRetail]
										   ,[CostMisMatch]
										   ,[RetailMisMatch]
										   ,case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
										   ,case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[StoreTransactionID]
										   ,[InvoiceDueDate]
										   from StoreTransactions_Working w
										where w.StoreTransactionID = CAST(@workingtransactionidstring as bigint)
										and [Qty] <> 0
					
					
					--end
									
				insert into CDCControl
					(StoreTransactionID, ProcessID)
					values(@transactionid,@MyID)
									
			end
		else
			begin

				--declare @errormessage varchar(4500)
				--declare @errorlocation varchar(255)
				
				update StoreTransactions_Working set WorkingStatus = -5 where StoreTransactionID = CAST(@workingtransactionidstring as bigint)

				update t set t.ProcessingErrorDesc = ''
				from StoreTransactions t
				where t.StoreTransactionID = @transactionid

				set @errormessage = 'Warning: It appears that working transaction ' + ltrim(rtrim(@workingtransactionidstring)) + ' is an update of transaction ' + ltrim(rtrim(cast(@transactionid as nvarchar(50)))) + ' but this would violate the update limit of ' + @existingpostransactionupdatelimitstring + '.  This new transaction has not been processed into the StoreTransactions table.'
				set @errorlocation = 'prValidateTransactionTypeInStoreTransactions_Working'
				set @errorsenderstring = 'prValidateTransactionTypeInStoreTransactions_Working'
				
				exec dbo.prLogExceptionAndNotifySupport
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,@MyID
				
			end	
					commit transaction
			end --if @workingtransactionidstring <> @lastprocessingerrordesc
--print @relatedcount

			set @lastprocessingerrordesc = @workingtransactionidstring
			
			fetch next from @rec into @transactionid
				,@workingtransactionidstring
				,@oldsetupcost
				,@oldsetupretail
				,@oldreportedcost
				,@oldreportedretail
				,@oldqty
				,@oldsupplierid				
	end
	
close @rec
deallocate @rec
*/
          
--		commit transaction
		
/*			
				select StoreTransactionID from CDCControl where ProcessID = @MyID
				if @@ROWCOUNT > 0
					begin	
						waitfor delay '0:0:10'
						repeatdelete:
						delete from cdc.dbo_StoreTransactions_CT
						where StoreTransactionID in (select StoreTransactionID 
								from CDCControl
								where ProcessID = @MyID)
						if @@ROWCOUNT < 1
							begin
								waitfor delay '0:0:2'
								goto repeatdelete
							end
						delete from CDCControl where ProcessID = @MyID
					end
*/			
						
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com;edi@icontroldsd.com'	
end catch
	
--Print 'Got Here'
--/*
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.ProcessID = @ProcessID
--*/

return
GO
