USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_INV]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_INV]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
declare @errorrecordcount int
declare @transidtable StoretransactionIDTable

set @MyID = 7598

begin try

select distinct StoreTransactionID
into #tempStoreTransaction
--select *
--select distinct cast(saledatetime as date)
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('INV', 'INV-BOD')
--and SupplierID in (40558, 40561, 40562, 40557, 41464, 41465)
and SupplierID in (41464)
--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Farm Fresh Markets')
--order by cast(saledatetime as date)
--and ReportedCost < 1000
--and cast(SaleDateTime as date) <> '12/5/2011'


insert @transidtable
select StoreTransactionID from #tempStoreTransaction

begin transaction

set @loadstatus = 5
/*
drop table #tempStoreTransaction
1.update transaction type based on default of 
beginning of day INV-BOD unless the supplierid
owns attributeid = 1 with INV-EOD or other value
*/
--/*
update t
set t.WorkingSource = a.AttributeValue
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].AttributeValues a
on t.SupplierID = a.OwnerEntityID
where t.WorkingStatus = 4
and t.WorkingSource in ('INV')
and a.AttributeID = 1 --InventoryCountTime
/*
if @@ROWCOUNT < 1 --Use default count time of beginning of day
	update t
	set t.WorkingSource = 'INV-BOD'
	from #tempStoreTransaction tmp
	inner join [dbo].[StoreTransactions_Working] t
	on tmp.StoreTransactionID = t.StoreTransactionID
	where t.WorkingStatus = 4
	and t.WorkingSource in ('INV')
*/
--/*
--look for later count dates for same assignments and set to type 12
update w set w.TransactionTypeID = 12
from #tempStoreTransaction tmp
inner join StoreTransactions_working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions t
on w.chainid = t.chainid
and w.storeid = t.storeid
and w.productid = t.productid
and w.brandid = t.brandid
where t.TransactionTypeID in (10, 11)
and t.SaleDateTime >= w.saledatetime
--*/


update t
set t.TransactionTypeID = y.TransactionTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].TransactionTypes y
on t.WorkingSource = y.TransactionTypeName
where WorkingStatus = 4
and t.WorkingSource in ('INV-BOD', 'INV-EOD') --10, 11

--if not set up then use default transaction type of count at end-of-day ('INV-EOD') = 11
update t
set t.TransactionTypeID = 11, t.WorkingSource = 'INV-BOD'
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.TransactionTypeID is null

update t set WorkingStatus = -5
--case when t.TransactionTypeID in (10,11) then 5 else -5 end
, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is null

if @@ROWCOUNT > 0
	begin
		
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Unknown Transaction Types Found.  Records in the StoreTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateTransactionTypeInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateTransactionTypeInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
--*/

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
and p.ProductPriceTypeID = 3 
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

--***************Cost Rules Start***************************

exec prApplyCostRules @transidtable, 3 --1=POS, 2=SUP, 3=INV

/*
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
*/
--***************Cost Rules End***************************

/*
update t
set t.WorkingSource = 'INV-BOD'
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where 1 = 1
and t.WorkingSource = 'INV'
and WorkingStatus = 4
*/

MERGE INTO [dbo].[StoreTransactions] t

USING (select t.[StoreTransactionID]
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
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[TrueCost]
      ,[TrueRetail]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[WorkingSource]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 4
and TransactionTypeID is not null) S
--and workingsource in ('INV-BOD','INV-EOD')) S
on t.chainid = s.chainid
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.brandid = s.brandid
and t.SupplierID = s.SupplierID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID = s.TransactionTypeID
and t.TransactionTypeID in (10, 11)
--select cast(getdate() as date)

WHEN MATCHED 

	Then update
			set t.ProcessingErrorDesc = 
			'Warning: It appears that working transaction ' + ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50)))) + ' is a possible duplicate of this transaction!  This new transaction has not been processed into the StoreTransactions table. | ' + isnull(t.ProcessingErrorDesc, '')
/*
        THEN INSERT     
           ([StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[UnitSalePrice]
           ,[UnitCost]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedUnitPrice]
           ,[ReportedUnitCost]
           ,[TransactionStatus]
           ,[IsProcessedInSystem]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID])
     VALUES
     (S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,S.[TransactionTypeID]
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[UnitSalePrice]
           ,S.[UnitCost]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedUnitPrice]
           ,S.[ReportedUnitCost]
           ,-1
           ,S.[IsProcessedInSystem]
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,7420)
*/
WHEN NOT MATCHED 

        THEN INSERT     
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
           --,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch])
     VALUES
     (S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,S.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'INV-BOD' then 11 when S.[WorkingSource] = 'INV-EOD' then 10 else 11 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,s.[SetupCost]
           ,s.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
		   ,S.[ReportedCost]
		   ,S.[ReportedRetail]
           ,s.[RuleCost]
           ,s.[RuleRetail]
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end
           ,[CostMisMatch]
           ,[RetailMisMatch]);

		commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997
		
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

          
update t set WorkingStatus = @loadstatus
--case when t.TransactionTypeID in (10,11) then 5 else -5 end
, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is not null

--@errorrecordcount

return
GO
