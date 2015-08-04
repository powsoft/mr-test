USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery13.sql|7|0|C:\Users\charlie.clark\AppData\Local\Temp\4\~vsE0D5.sql
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH_PRESYNC_20150329]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable

set @MyID = 7666

DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH'

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransaction TABLE
(
	StoreTransactionID INT,
	SaleDateTime DATETIME
);

--===============================
EXEC dbo.[Audit_Log_SP] 'STEP 000 ENTRY POINT =>',@source


begin transaction

--select distinct StoreTransactionID, saledatetime
--into @tempStoreTransaction
--select *
insert into @tempStoreTransaction (StoreTransactionID, SaleDateTime)
select distinct StoreTransactionID, saledatetime
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
and WorkingSource in ('SUP-S', 'SUP-U')
and ProcessID = @ProcessID
--and EDIName in (select EDIName from Suppliers where IsRegulated = 1)
--and ChainIdentifier in (select distinct ChainIdentifier from @RegulatedChains)
--and CAST(saledatetime as date) = cast(DATEadd(day,-1,getdate()) as date)
--and EDIName in(
--	Select SupplierName 
--	From DataTrue_EDI.dbo.ProcessStatus_ACH 
--	Where BillingIsRunning = 1
--	and BillingComplete = 0)
order by StoreTransactionID


--- STEP 1
EXEC dbo.[Audit_Log_SP] 'STEP 001 => INSERT INTO @tempStoreTransaction FROM [StoreTransactions_Working]', @source 

insert @transidtable
select StoreTransactionID from @tempStoreTransaction


set @loadstatus = 5

update t
set t.TransactionTypeID = 
case when WorkingSource = 'SUP-S' then 5
	 when WorkingSource = 'SUP-U' then 8
else null end
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.TransactionTypeID is null

update t set WorkingStatus = -5
, LastUpdateUserID = @MyID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and t.TransactionTypeID is null


--UPDATE SETUPCOST

update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from @tempStoreTransaction tmp
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



--update CostMisMatch
update t set t.CostMisMatch = 1
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost <> t.ReportedCost
or t.SetupCost is null or t.ReportedCost is null
--or (t.SetupCost is null and t.ReportedCost is null)

--update RetailMisMatch
update t set t.RetailMisMatch = 1
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupRetail <> t.ReportedRetail
or t.SetupRetail is null or t.ReportedRetail is null
--or (t.SetupRetail is null and t.ReportedRetail is null)

update t set t.RuleCost = t.ReportedCost, t.RuleRetail = t.ReportedRetail
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

--- STEP 2
EXEC dbo.[Audit_Log_SP] 'STEP 002 => UPDATEs [StoreTransactions_Working]', @source 

DECLARE @storetransactionsids TABLE (storetransactionID int);
/*
		select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed, CAST(4 as int) as Workingstatus
		into #tempsup		
		from DataTrue_Main.dbo.StoreTransactions_Working w
		where charindex('POS', WorkingSource) > 0
		and WorkingStatus = 4

		select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed
		into #tempsup2
		from DataTrue_Main.dbo.StoreTransactions
		where 1 = 1
		and TransactionTypeID in (2, 6)
		and CAST(SaleDateTime as date) in 
		(select distinct CAST(SaleDateTime as date) from #tempsup)
		
		update t set t.ProcessingErrorDesc=ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
		OUTPUT INSERTED.ProcessingErrorDesc INTO @storetransactionsids
		--select * 
		from #tempsup2 t join
		(select w.* from #tempsup w join @tempStoreTransaction tmp
		on w.StoreTransactionID=tmp.StoreTransactionID ) s
		on t.StoreID = s.StoreID 
		and t.ProductID = s.ProductID
		and t.BrandID = s.BrandID
		--and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
		and DATEDIFF(D,t.SaleDateTime,s.SaleDateTime)=0
		and t.TransactionTypeID in (5, 8)
		and t.PoNo = s.PONO
		and t.Reversed = 0
		and cast(s.saledatetime as date) < cast(DATEADD(day,-1,getdate()) as date)
		
		update t set t.ProcessingErrorDesc = tmp.ProcessingErrorDesc
		from #tempsup2 tmp
		inner join storetransactions t
		on tmp.StoreTransactionID = t.StoreTransactionID
		and tmp.ProcessingErrorDesc is not null
		
		drop table #tempsup
		drop table #tempsup2			
*/



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
           ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[SupplierItemNumber]
		  ,[ProductDescriptionReported]
		  ,[UOM]
		  ,[UnAuthorizedAssignment]
		  ,[AccountCode]
		  ,[RecordType]
		  ,[ProcessID]
		  ,[RefIDToOriginalInvNo]
		  ,[PackSize]
		  ,[ProductIdentifier]
		  ,[RawProductIdentifier]
		  ,[Pono]
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
           ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[ItemSKUReported]
		  ,[ItemDescriptionReported]
		  ,[UOM]
		  ,[UnAuthorizedAssignment]
		  ,s.[AccountCode]
		  ,s.[RecordType]
		  ,s.[ProcessID]
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
		  ,s.[UPC]
		  ,s.RawProductIdentifier
		  ,s.PONo
		  ,s.RecordID_EDI_852
from [dbo].[StoreTransactions_Working] s with(nolock)
inner join @tempStoreTransaction tmp
on s.StoreTransactionID = tmp.StoreTransactionID
where s.transactiontypeid in (5, 8)
--and tmp.StoreTransactionID not in (select storetransactionID from @storetransactionsids)
--- STEP 3
EXEC dbo.[Audit_Log_SP] 'STEP 003 => INSERT INTO [StoreTransactions] FROM [StoreTransactions_Working]', @source  

	
--Print 'Got Here'
--/*
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
--*/

--- STEP 4
EXEC dbo.[Audit_Log_SP] 'STEP 004 => update INTO [StoreTransactions] FROM [StoreTransactions_Working]', @source 

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
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
end catch


return
GO
