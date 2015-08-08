USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_Shrink_Create_Newspapers_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery9.sql|7|0|C:\Users\vince.moore\AppData\Local\Temp\7\~vs38A6.sql


CREATE procedure [dbo].[prInvoiceDetail_Shrink_Create_Newspapers_PRESYNC_20150415]
--@invoicedetailtype tinyint,
@saledate date=null
/*
prInvoiceDetail_Retailer_POS_Create '6/2/2011', 1
*/
as

--SET PROCESS ID
	DECLARE @ProcessID INT
	INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (11) --JobRunningID 11 = NewspaperShrink_Invoice
	SELECT @ProcessID = SCOPE_IDENTITY()
	UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobName = 'NewspaperShrink_Invoice'

--declare @saledate date set @saledate = null --'11/7/2011'
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint
declare @invoicedetailswithnullretailerinvoiceid int

if @saledate is null
	set @saledate = GETDATE()

set @MyID = 24126
set @invoicedetailtype = 3 --Retailer Shrink Source

begin try

begin transaction

update StoreTransactions
set ProductIdentifier = UPC
where TransactionStatus in (800, 801, 820)
and TransactionTypeID in (17, 19)
and ProcessID IN (select ProcessID from JobProcesses where JobRunningID = 10)
--and CAST(datetimecreated as date) = '4/8/2014'
and isnull(RuleCost,0) <> 0
--and isnull(RuleRetail,0) <> 0
and Qty <> 0
and ISNULL(UPC, '') <> ''
and ISNULL(ProductIdentifier, '') = ''

select StoreTransactionID
into #tempStoreTransactions
--select *
--select sum(case when transactiontypeid = 19 then (qty * -1) else qty end * rulecost)
from StoreTransactions
where TransactionStatus in (800, 801, 820)
and TransactionTypeID in (17, 19)
and ProcessID IN (select ProcessID from JobProcesses where JobRunningID = 10)
--and CAST(datetimecreated as date) = '4/8/2014'
and isnull(RuleCost,0) <> 0
--and isnull(RuleRetail,0) <> 0
and Qty <> 0
order by SaleDateTime

if @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end
	
	DECLARE @tempinvoicedetails TABLE (ChainID int
           ,[StoreID] int
           ,[ProductID] int
           ,[BrandID] int
           ,[SupplierID] int
           ,SaleDateTime DATE
           ,UnitCost money);

	
	INSERT into InvoiceDetails
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[LastUpdateUserID]
           ,[SaleDate]
           ,[BatchID]
           ,StoreIdentifier
           ,StoreName
           ,ProductIdentifier
           ,ProductQualifier
           ,RawProductIdentifier
           ,SupplierName
           ,SupplierIdentifier
           ,BrandIdentifier
           ,DivisionIdentifier
           ,UOM
           ,SalePrice
           ,Allowance
           ,InvoiceNo
           ,PONo
           ,CorporateName
           ,CorporateIdentifier
           ,Banner
           ,PromoTypeID
           ,PromoAllowance
           ,SBTNumber
           ,[PaymentDueDate]
		  ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[VIN]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[SourceID]
		  ,[ProcessID]
		  ,[RecordStatus]
		  ,[EDIRecordID]
		  )
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,CASE WHEN s.TransactionTypeID = 17 THEN 3 WHEN s.TransactionTypeID = 19 THEN 9 END
           ,SUM(case when Transactiontypeid in (17) then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid in (17) then Qty else Qty * -1 end * (RuleCost - isnull(PromoAllowance, 0))) --+ SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) as TotalCost
           ,SUM(case when Transactiontypeid in (17) then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,SUM(Qty * (RuleCost))/SUM(Qty) as UnitCost
           ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
           ,@MyID
           ,CAST(s.SaleDateTime as DATE) as SaleDate
           ,@batchstring --ChainIdentifier
           ,StoreIdentifier
           ,StoreName
           ,ProductIdentifier
           ,ProductQualifier
           ,RawProductIdentifier
           ,SupplierName
           ,SupplierIdentifier
           ,BrandIdentifier
           ,DivisionIdentifier
           ,UOM
           ,SalePrice
           ,ReportedAllowance as Allowance
           ,ISNULL(SupplierInvoiceNumber, '')
           ,ISNULL(PONo, '')
           ,CorporateName
           ,CorporateIdentifier
           ,Banner
           ,PromoTypeID
           ,PromoAllowance
           ,SBTNumber
           ,[InvoiceDueDate]
		  ,sum(isnull([Adjustment1],0)) --SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) --isnull([Adjustment1],0)
		  ,sum(isnull([Adjustment2],0))
		  ,sum(isnull([Adjustment3],0))
		  ,sum(isnull([Adjustment4],0))
		  ,sum(isnull([Adjustment5],0))
		  ,sum(isnull([Adjustment6],0))
		  ,sum(isnull([Adjustment7],0))
		  ,sum(isnull([Adjustment8] ,0))
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID] 
		  ,@ProcessID  
		  ,CASE WHEN s.TransactionStatus = 820 THEN 820 ELSE 0 END
		  ,MAX(EDIRecordID)
		FROM [dbo].[StoreTransactions] s
		inner join #tempStoreTransactions tmp
		on s.StoreTransactionID = tmp.StoreTransactionID
		left join @tempinvoicedetails i
		on i.ChainID = s.ChainID
		and i.StoreID = s.StoreID 
		and i.ProductID = s.ProductID
		and i.BrandID = s.BrandID
		and i.SupplierID = s.SupplierID
		--and i.SaleDateTime = s.SaleDateTime
		and DATEDIFF(D,i.SaleDateTime,s.SaleDateTime)=0
		--and i.UnitCost = SUM(Qty * (RuleCost))/SUM(Qty)--s.UnitCost
		where i.ChainID is null
		group by s.[ChainID]
           ,s.[StoreID]
           ,s.[ProductID]
           ,s.[BrandID]
           ,s.[SupplierID]
           ,CAST(s.SaleDateTime as DATE)
           ,s.RuleCost--) S
           ,s.ChainIdentifier
           ,s.StoreIdentifier
           ,s.StoreName
           ,s.ProductIdentifier
           ,s.ProductQualifier
           ,s.RawProductIdentifier
           ,s.SupplierName
           ,s.SupplierIdentifier
           ,s.BrandIdentifier
           ,s.DivisionIdentifier
           ,s.UOM
           ,s.SalePrice
           ,s.ReportedAllowance
           ,s.SupplierInvoiceNumber
           ,s.PONo
           ,s.CorporateName
           ,s.CorporateIdentifier
           ,s.Banner
           ,s.PromoTypeID
           ,s.PromoAllowance
           ,s.SBTNumber
           ,[InvoiceDueDate]
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]     
		  ,s.TransactionTypeID
		  ,s.TransactionStatus
        having SUM(Qty) <> 0 
        
        UPDATE InvoiceDetails
        SET TotalCost = (TotalQty * UnitCost) + ISNULL(Adjustment1, 0)
        WHERE InvoiceDetailTypeID = 3
        AND ProcessID = @ProcessID
        
        UPDATE InvoiceDetails
        SET Adjustment1 = (ISNULL(Adjustment1, 0) * -1),
            TotalCost = (TotalQty * UnitCost) + (ISNULL(Adjustment1, 0) * -1)
        WHERE InvoiceDetailTypeID = 9
        AND ProcessID = @ProcessID
        
IF
(
	SELECT COUNT(InvoiceDetailID)
	FROM DataTrue_Main.dbo.InvoiceDetails
	WHERE ProcessID = @ProcessID
	AND ISNULL(ProductIdentifier, '') = ''
) > 0
	BEGIN
		RAISERROR ('Blank/Null UPCs in prInvoiceDetail_Shrink_Create_Newspapers.' , 16 , 1)
	END	
	
IF
(
	SELECT COUNT(InvoiceDetailID)
	FROM DataTrue_Main.dbo.InvoiceDetails
	WHERE ProcessID = @ProcessID
	AND LEN(ISNULL(ProductIdentifier, '')) < 12
) > 0
	BEGIN
		RAISERROR ('UPCs in prInvoiceDetail_Shrink_Create_Newspapers with under 12 length.' , 16 , 1)
	END	
	
update t set TransactionStatus = case when transactionstatus = 800 then 810 when transactionstatus = 820 then 821 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID


commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID

		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Error in Newspaper shrink create'
			,'An exception occurred in [prInvoiceDetail_Shrink_Create_Newspapers].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch

return
GO
