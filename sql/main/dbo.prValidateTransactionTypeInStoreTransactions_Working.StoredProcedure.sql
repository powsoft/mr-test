USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable
declare @newqtyadded bit

set @MyID = 7420

begin try

select distinct StoreTransactionID, saledatetime
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
--and ChainID = 40393
and WorkingSource in ('POS')
--and CAST(saledatetime as date) = '11/26/2011'

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
declare @dupecount int
--/*

 select storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO))
from StoreTransactions_Working w
inner join #tempStoreTransaction t
on w.StoreTransactionID = t.StoreTransactionID
where 1 = 1
and WorkingStatus = 4
group by storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO))
having COUNT(w.storetransactionid) > 1

if @@ROWCOUNT > 0 
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select distinct w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
	from storetransactions_working w
	inner join #tempStoreTransaction tmp
	on w.storetransactionid = tmp.storetransactionid
	where tmp.StoreTransactionID in
	(
	select storetransactionid
	from storetransactions_working w
	inner join
		(select storeid, productid, brandid, cast(saledatetime as date) as [date]
		from storetransactions_working
		where workingstatus = 4
		group by storeid, productid, brandid, cast(saledatetime as date)
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
	)
	order by w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate
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
				and WorkingStatus = 4
			 )
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and WorkingStatus = 4
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate	
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
--******************Remove Dupes End**********************************
	end --@@rowcount > 0
--*/
--declare @transidtable StoretransactionIDTable
insert @transidtable
select StoreTransactionID from #tempStoreTransaction
--exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV

begin transaction

set @loadstatus = 5

update t set t.TransactionTypeID = 2
--select t.*
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

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
where t.SetupCost is null
and p.ProductPriceTypeID in (3)
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

/*
--next look for product, brand, location

update t set t.SetupCost = p.UnitPrice, t.SetupRetail = p.UnitRetail, t.ProductPriceTypeID = p.ProductPriceTypeID
--select p.*
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.SupplierID = 0

--next look for product, brand, Chain
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.StoreID = 0
and p.SupplierID = 0

--next look for product, Location
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.BrandID = 0
and p.SupplierID = 0

--next look for product, brand, chain
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.ChainID = p.ChainID 
and t.BrandID = p.BrandID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.StoreID = 0
and p.SupplierID = 0

--next look for product, chain
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.ChainID = p.ChainID 
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.StoreID = 0
and p.BrandID = 0
and p.SupplierID = 0

--next look for default for product, brand
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.ChainID = 0
and p.StoreID = 0
and p.SupplierID = 0

--next look for default for product
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.ChainID = 0
and p.StoreID = 0
and p.BrandID = 0
and p.SupplierID = 0
*/
/*
--Pend records that do not have any cost or retail data
update t set t.workingstatus = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost <> t.ReportedCost
*/

--update CostMisMatch
update t set t.CostMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost <> t.ReportedCost
or t.SetupCost is null or t.ReportedCost is null
--or (t.SetupCost is null and t.ReportedCost is null)

--update RetailMisMatch
update t set t.RetailMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupRetail <> t.ReportedRetail
or t.SetupRetail is null or t.ReportedRetail is null
--or (t.SetupRetail is null and t.ReportedRetail is null)

--***************Cost Lookup End****************************

exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV
/*
--***************Cost Rules Start***************************
--If Type is Retailer and B is null, then F=D
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
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
       ,ChainIdentifier
,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber
from [dbo].[StoreTransactions_Working] w
inner join #tempStoreTransaction tmp
on w.StoreTransactionID = tmp.StoreTransactionID) S
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
--and t.TransactionTypeID = s.TransactionTypeID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID in (2, 6, 16)
and t.PoNo = s.PONO
--and t.TransactionTypeID in (2) 
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
           ,[TrueRetail]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber)
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
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,s.StoreIdentifier
,s.StoreName
,s.ProductQualifier
,s.RawProductIdentifier
,s.SupplierName
,s.SupplierIdentifier
,s.BrandIdentifier
,s.DivisionIdentifier
,s.UOM
,s.SalePrice
,s.InvoiceNo
,s.PONo
,s.CorporateName
,s.CorporateIdentifier
,s.Banner
,s.PromoTypeID
,s.PromoAllowance
,s.SBTNumber);

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
	
declare @rec cursor
declare @workingtransactionidstring nvarchar(100)
declare @transactionid bigint
declare @relatedcount smallint
declare @existingpostransactionupdatelimitstring nvarchar(10)
declare @existingpostransactionupdatelimit tinyint
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

set @rec = CURSOR local fast_forward FOR

	select t.StoreTransactionID, t.ProcessingErrorDesc,
	isnull(t.SetupCost,0), isnull(t.SetupRetail,0), isnull(t.ReportedCost,0), isnull(t.ReportedRetail,0),
	t.Qty, t.SupplierID
	from StoreTransactions t
	inner join #tempStoreTransaction tmp
	on cast(t.ProcessingErrorDesc as bigint) = tmp.StoreTransactionID
	where len(t.ProcessingErrorDesc) > 0
	and isnumeric(t.ProcessingErrorDesc) > 0
	
/*20110912 added join above since there could be supplier records
	select StoreTransactionID, ProcessingErrorDesc,
	isnull(SetupCost,0), isnull(SetupRetail,0), isnull(ReportedCost,0), isnull(ReportedRetail,0),
	Qty, SupplierID
	from StoreTransactions
	where len(ProcessingErrorDesc) > 0
	and isnumeric(ProcessingErrorDesc) > 0
20110912*/
	
open @rec

fetch next from @rec into @transactionid
	,@workingtransactionidstring
	,@oldsetupcost
	,@oldsetupretail
	,@oldreportedcost
	,@oldreportedretail
	,@oldqty
	,@oldsupplierid


if @@FETCH_STATUS = 0
	begin
		select @existingpostransactionupdatelimitstring = v.AttributeValue
		--select *
		from AttributeDefinitions d
		inner join AttributeValues v
		on d.AttributeID = v.AttributeID
		where d.AttributeName = 'ExistingPOSTransactionUpdateLimit'
		
		set @existingpostransactionupdatelimit = cast(@existingpostransactionupdatelimitstring as tinyint)

	end

set @lastprocessingerrordesc = ''

while @@FETCH_STATUS = 0
	begin
	
	if @workingtransactionidstring <> @lastprocessingerrordesc
	begin
	begin transaction
		set @newqtyadded = 0
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
				
				if @newsetupcost = @oldsetupcost
						and @newsetupretail = @oldsetupretail
						and @newreportedcost = @oldreportedcost
						and @newreportedretail = @oldreportedretail
						--and @newqty = @oldqty
						and @newsupplierid = @oldsupplierid	
					begin
						if @newqty <> @oldqty --Qty to add to saledate
							begin
								set @newqtyadded = 1
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
										   
										   

           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber										   
										   
										   
										   )
									 select Top 1 [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,6 --Updated POS transaction
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
										   
										   

           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber													   
										   
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
						   
				if (@newsetupcost <> @oldsetupcost
						or @newsetupretail <> @oldsetupretail
						or @newreportedcost <> @oldreportedcost
						or @newreportedretail <> @oldreportedretail
						or @newsupplierid <> @oldsupplierid)
						and @newqtyadded = 0	
					begin
					
								set @reversingtransactionid = null
/*					
					
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
									 select Top 1 [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,7
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
										   from StoreTransactions
										where StoreTransactionID = @transactionid
										
								set @reversingtransactionid = SCOPE_IDENTITY()
								
								update t set t.ProcessingErrorDesc = 'REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
								,Reversed = 1
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid
*/					

															
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
										   
										   

           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber										   
													   
										   
										   
										   )
									 select [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,6 --16
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
										   
										   

           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,StoreIdentifier
,StoreName
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber										   
													   
										   
										   
										   
										   from StoreTransactions_Working w
										where w.StoreTransactionID = CAST(@workingtransactionidstring as bigint)
					
					
					end
									
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
		end --if workingtransactionid <> @lastprocessingerrordesc
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
		
end catch
	
--Print 'Got Here'
--/*
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
--*/
/*
and t.StoreTransactionID not in
(
select storetransactionid
from storetransactions_working w
inner join
(select storeid, productid, brandid, cast(saledatetime as date) as [date] --, count(storetransactionid)
from storetransactions_working
where WorkingStatus = 4
group by storeid, productid, brandid, cast(saledatetime as date)
having count(storetransactionid) > 1) s
on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
)
*/
	
return
GO
