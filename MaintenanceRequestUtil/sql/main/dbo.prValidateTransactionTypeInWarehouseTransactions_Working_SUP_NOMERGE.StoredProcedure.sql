USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInWarehouseTransactions_Working_SUP_NOMERGE]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery13.sql|7|0|C:\Users\charlie.clark\AppData\Local\Temp\4\~vsE0D5.sql
CREATE procedure [dbo].[prValidateTransactionTypeInWarehouseTransactions_Working_SUP_NOMERGE]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable WarehousetransactionIDTable

set @MyID = 0

begin try

update w
set w.TransactionStatus = 5
--select *
from WarehouseTransactions_Working w
where ProcessingErrorDesc IS null
and workingstatus = 4
and WorkingSource in ('WHS-DB', 'WHS-CR')
and Qty = 0

select distinct WarehouseTransactionID, EffectiveDateTime
into #tempWarehouseTransaction
from [dbo].[WarehouseTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('WHS-DB', 'WHS-CR')
order by WarehouseTransactionID


--******************Remove Dupes Begin*******************************
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

--declare @transidtable WarehousetransactionIDTable

insert @transidtable
select WarehouseTransactionID from #tempWarehouseTransaction
--exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV

begin transaction

set @loadstatus = 5


update t set WorkingStatus = -5
--case when t.TransactionTypeID in (10,11) then 5 else -5 end
, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is null

--***************Temporary Update of Promo and Cost Until more requirements gathered**********
update t set t.PromoAllowance = 0,
t.PromoTypeID = 0
,t.SetupCost = 0, t.SetupRetail = 0
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID

--***************Promo Lookup Start**************************
/*
update t set t.PromoAllowance = p.UnitPrice,
t.PromoTypeID = P.ProductPriceTypeID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.WarehouseID = p.StoreID
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10)
and t.EffectiveDateTime between p.ActiveStartDate and p.ActiveLastDate

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
and t.WarehouseID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 --in 
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --5 is Supplier Entity
and t.EffectiveDateTime between p.ActiveStartDate and p.ActiveLastDate
*/

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

exec prApplyCostRules_WHS @transidtable, 2 --1=POS, 2=SUP, 3=INV

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
           ,[EffectiveDateTime]
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
           ,S.EffectiveDateTime
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
from [dbo].[WarehouseTransactions_Working] s
inner join #tempWarehouseTransaction tmp
on s.WarehouseTransactionID = tmp.WarehouseTransactionID
where s.transactiontypeid in (5, 8)

          
  commit transaction
	
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
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where WorkingStatus = 4
--*/

return
GO
