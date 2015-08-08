USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_RC_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_RC_PRESYNC_20150415]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable

set @MyID = 7586

begin try

--update w
--set w.TransactionStatus = 5
----select *
--from StoreTransactions_Working w
--where ProcessingErrorDesc IS null
--and workingstatus = 4
--and WorkingSource in ('RC')
--and Qty = 0

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
and WorkingSource in ('R-DB','R-CR')
--and SupplierID = 40558
--and SupplierID = 40557
--and SupplierID = 41464
--and SupplierID not in (40558, 41464)
--and SupplierID = 40561
--and SupplierID = 40562
order by StoreTransactionID

begin transaction

set @loadstatus = 5

--update transaction type
update t
set t.TransactionTypeID = 
case when WorkingSource = 'R-CR' then 32
when WorkingSource='R-DB' then 32
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
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 --in 
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --5 is Supplier Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate


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

exec prApplyCostRules @transidtable, 2 --1=POS, 2=SUP, 3=INV
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
           ,PONo
           ,RefIDToOriginalInvNo)
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
           ,PONo
           ,RefIDToOriginalInvNo
from [dbo].[StoreTransactions_Working] s
inner join #tempStoreTransaction tmp
on s.StoreTransactionID = tmp.StoreTransactionID
where s.transactiontypeid in (32)

		commit transaction
	
						
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
		--		,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
		--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com;edi@icontroldsd.com'	
end catch
	
--Print 'Got Here'
--/*
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
--*/

return
GO
