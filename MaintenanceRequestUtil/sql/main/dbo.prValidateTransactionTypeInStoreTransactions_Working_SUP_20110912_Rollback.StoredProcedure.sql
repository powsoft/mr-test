USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_20110912_Rollback]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_20110912_Rollback]
/*
truncate table StoreTransactions
delete StoreTransactions_Working where storetransactionid <> 6
update StoreTransactions_Working 
set WorkingStatus = 4, 
setupcost = null, setupretail = null,
rulecost = null, ruleretail=null,
productpricetypeid = null
where 1 = 1
--and workingstatus = 5
and StoreTransactionID = 6
*/
as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable

set @MyID = 7586

begin try

select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('SUP-S', 'SUP-U')


insert @transidtable
select StoreTransactionID from #tempStoreTransaction

begin transaction

set @loadstatus = 5

--update transaction type
update t
set t.TransactionTypeID = 
case when WorkingSource = 'SUP-S' then 5
	 when WorkingSource = 'SUP-U' then 8
else null end
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
and p.ProductPriceTypeID in 
(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5) --5 is Supplier Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

--next look for product, brand, chain, supplier
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
and t.SupplierID = p.SupplierID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.StoreID = 0 --p.StoreID 


--next look for product, brand, supplier
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.SupplierID = p.SupplierID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.ChainID = 0 --p.ChainID 
and p.StoreID = 0 --p.StoreID 

--next look for product, supplier
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.SupplierID = p.SupplierID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.BrandID = 0 --p.BrandID
and p.ChainID = 0 --p.ChainID 
and p.StoreID = 0

--next look for product, brand, location
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
and t.StoreID = p.StoreID
where t.SetupCost is null
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
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
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
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
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
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
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
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
and p.ProductPriceTypeID in (Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 5)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.ChainID = 0
and p.StoreID = 0
and p.BrandID = 0
and p.SupplierID = 0

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

exec prApplyCostRules @transidtable, 2 --1=POS, 2=SUP, 3=INV
/*
--If Type is Supplier and Setup is null, then Reported
--if Type is Supplier and Setup < Reported then Setup
update t
set RuleCost =
case when SetupCost IS NULL then ReportedCost
		when SetupCost is not null and ReportedCost > SetupCost then SetupCost
		when SetupCost is not null and ReportedCost < SetupCost then ReportedCost		
 else ReportedCost end,
 RuleRetail =
case when SetupRetail IS NULL then ReportedRetail
		when SetupRetail is not null and ReportedRetail > SetupRetail then SetupRetail
		when SetupRetail is not null and ReportedRetail < SetupRetail then ReportedRetail
 else ReportedRetail end
 from [dbo].[StoreTransactions_Working] t
 inner join #tempStoreTransaction tmp
 on t.StoreTransactionID = tmp.StoreTransactionID
*/
--***************Cost Rules End***************************



MERGE INTO [dbo].[StoreTransactions] t

USING (select [StoreTransactionID]
	  ,[ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
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
      ,[WorkingSource]
      ,[TrueCost]
      ,[TrueRetail]
from [dbo].[StoreTransactions_Working]
where workingstatus = 4) S
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID = s.TransactionTypeID
--select cast(getdate() as date)

WHEN MATCHED 
	then update
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
     (s.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,case when S.[WorkingSource] = 'SUP-S' then 5 when S.[WorkingSource] = 'SUP-U' then 8 else 0 end 
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
           ,s.[RuleCost]
           ,s.[RuleRetail]
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


commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9998
		
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
          
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


	
return
GO
