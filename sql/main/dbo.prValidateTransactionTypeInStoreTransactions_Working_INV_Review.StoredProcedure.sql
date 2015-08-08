USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_INV_Review]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_INV_Review]
--truncate table StoreTransactions
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
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('INV')
and SupplierID in (40558, 40561, 40562, 40557, 41464)



insert @transidtable
select StoreTransactionID from #tempStoreTransaction

begin transaction

set @loadstatus = 5


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

--***************Cost Rules End***************************

MERGE INTO [dbo].[StoreTransactions] t

USING (select [StoreTransactionID]
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
from [dbo].[StoreTransactions_Working]
where workingstatus = 4
and TransactionTypeID is not null) S
on t.chainid = s.chainid
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.brandid = s.brandid
and t.SupplierID = s.SupplierID
and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
and t.TransactionTypeID = s.TransactionTypeID
and t.TransactionTypeID in (10, 11)

WHEN MATCHED 

	Then update
			set t.ProcessingErrorDesc = 
			'Warning: It appears that working transaction ' + ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50)))) + ' is a possible duplicate of this transaction!  This new transaction has not been processed into the StoreTransactions table. | ' + isnull(t.ProcessingErrorDesc, '')

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
, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is not null


return
GO
