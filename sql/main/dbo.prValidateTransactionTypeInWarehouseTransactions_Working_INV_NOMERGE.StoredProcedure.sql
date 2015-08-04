USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInWarehouseTransactions_Working_INV_NOMERGE]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prValidateTransactionTypeInWarehouseTransactions_Working_INV_NOMERGE]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
declare @errorrecordcount int
declare @transidtable WarehousetransactionIDTable

set @MyID = 0

begin try

select distinct WarehouseTransactionID
into #tempWarehouseTransaction
--select *
--select distinct cast(saledatetime as date)
from [dbo].[WarehouseTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('INV', 'INV-BOD')


insert @transidtable
select WarehouseTransactionID from #tempWarehouseTransaction

begin transaction

set @loadstatus = 5

update t
set t.WorkingSource = a.AttributeValue
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].AttributeValues a
on t.SupplierID = a.OwnerEntityID
where t.WorkingStatus = 4
and t.WorkingSource in ('INV')
and a.AttributeID = 1 --InventoryCountTime

--look for later count dates for same assignments and set to type 12
update w set w.TransactionTypeID = 12
from #tempWarehouseTransaction tmp
inner join WarehouseTransactions_working w
on tmp.WarehouseTransactionID = w.WarehouseTransactionID
inner join WarehouseTransactions t
on w.chainid = t.chainid
and w.Warehouseid = t.Warehouseid
and w.productid = t.productid
and w.brandid = t.brandid
where t.TransactionTypeID in (10, 11)
and t.SaleDateTime >= w.saledatetime
--*/


update t
set t.TransactionTypeID = y.TransactionTypeID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].TransactionTypes y
on t.WorkingSource = y.TransactionTypeName
where WorkingStatus = 4
and t.WorkingSource in ('INV-BOD', 'INV-EOD') --10, 11

--if not set up then use default transaction type of count at end-of-day ('INV-EOD') = 11
update t
set t.TransactionTypeID = 11, t.WorkingSource = 'INV-BOD'
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.TransactionTypeID is null

update t set WorkingStatus = -5
--case when t.TransactionTypeID in (10,11) then 5 else -5 end
, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is null

if @@ROWCOUNT > 0
	begin
		
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Unknown Transaction Types Found.  Records in the WarehouseTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateTransactionTypeInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateTransactionTypeInWarehouseTransactions_Working_INV'
		
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
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.WarehouseID = p.WarehouseID 
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
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.WarehouseID = p.WarehouseID 
and t.SupplierID = p.SupplierID 
where t.SetupCost is null
and p.ProductPriceTypeID = 3 
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

--update CostMisMatch
update t set t.CostMisMatch = 1
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.SetupCost <> t.ReportedCost
or t.SetupCost is null or t.ReportedCost is null
--or (t.SetupCost is null and t.ReportedCost is null)

--update RetailMisMatch
update t set t.RetailMisMatch = 1
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.SetupRetail <> t.ReportedRetail
or t.SetupRetail is null or t.ReportedRetail is null
--or (t.SetupRetail is null and t.ReportedRetail is null)



--***************Cost Lookup End****************************

--***************Cost Rules Start***************************

exec prApplyCostRules @transidtable, 3 --1=POS, 2=SUP, 3=INV

insert into [dbo].[WarehouseTransactions]
           ([ChainID]
           ,[WarehouseID]
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
           ,[PromoAllowance])
select		S.[ChainID], S.[WarehouseID]
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
           ,S.[WarehouseTransactionID]
           ,case when s.[CostMisMatch] = 0 then s.[SetupCost] else s.[TrueCost] end
           ,case when s.[RetailMisMatch] = 0 then s.[SetupRetail] else s.[TrueRetail] end
           ,s.PromoAllowance
from [dbo].[WarehouseTransactions_Working] s
inner join #tempWarehouseTransaction tmp
on s.WarehouseTransactionID = tmp.WarehouseTransactionID
where s.transactiontypeid in (11)


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
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is not null

--@errorrecordcount

return
GO
