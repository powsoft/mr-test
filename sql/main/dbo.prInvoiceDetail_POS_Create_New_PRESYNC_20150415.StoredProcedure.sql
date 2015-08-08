USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_POS_Create_New_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Create Invoice Details based off Store Transaction records that are ready for invoicing
-- =============================================
CREATE PROCEDURE [dbo].[prInvoiceDetail_POS_Create_New_PRESYNC_20150415]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint
declare @invoicedetailswithnullretailerinvoiceid int
declare @saledate date=null

if @saledate is null
	set @saledate = GETDATE()

set @MyID = 24126
set @invoicedetailtype = 1 --POSSource

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

begin transaction


select Distinct StoreTransactionID
into #tempStoreTransactions
--select Distinct T.*
from StoreTransactions T 
where TransactionStatus in (800, 801)
and TransactionTypeID in (2,6)
and isnull(RuleCost,0) <> 0
and RuleRetail is not null
and Qty <> 0
and ProcessID = @ProcessID


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
		  ,[RetailUOM]
		  ,[RetailTotalQty]
		  ,[PDIParticipant]
		  ,[ProcessID]
		  ,[recordtype]
		  ,EDIRecordID
		  ,RetailerItemNo
		  )
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(Qty) as TotalQty
           ,Case When s.RecordType = 2 then SUM(Qty * (RuleCost - isnull(PromoAllowance, 0))) +  SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) Else SUM(Qty * (RuleCost - isnull(PromoAllowance, 0))) +  SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail_SBT(S.ChainID) End as TotalCost
           ,SUM(Qty * RuleRetail) as TotalRetail
           ,SUM(Qty * (RuleCost))/SUM(Qty) as UnitCost
           ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
           ,@MyID
           ,CAST(s.SaleDateTime as DATE) as SaleDate
           ,@batchstring --ChainIdentifier
           ,StoreIdentifier
           ,StoreName
           ,UPC
           ,ProductQualifier
       ,RawProductIdentifier
           ,SupplierName
           ,SupplierIdentifier
           ,BrandIdentifier
           ,DivisionIdentifier
           ,UOM
           ,SalePrice
           ,ReportedAllowance as Allowance
           ,SupplierInvoiceNumber
           ,PONo
           ,CorporateName
           ,CorporateIdentifier
           ,Banner
           ,PromoTypeID
           ,PromoAllowance
           ,SBTNumber
           ,[InvoiceDueDate]
		  ,Case when s.RecordType = 2 then SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) else SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail_SBT(S.ChainID) End
		  ,isnull([Adjustment2],0)
		  ,isnull([Adjustment3],0)
		  ,isnull([Adjustment4],0)
		  ,isnull([Adjustment5],0)
		  ,isnull([Adjustment6],0)
		  ,isnull([Adjustment7],0)
		  ,isnull([Adjustment8] ,0)
		  ,Case When RecordType = 2 Then UPC Else SupplierItemNumber End
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID]
		  ,Case When UOM = 'EA' then 'EACH' else ' ' end
		  ,Qty 
		  ,CASE WHEN ISNULL(ch.PDITradingPartner, 0) = 1 THEN 1 ELSE 0 END 
		  ,s.ProcessID
		  ,RecordType
		  ,EDIRecordID
		  ,RetailerItemNo
		FROM [dbo].[StoreTransactions] s
		inner join DataTrue_Main.dbo.chains ch
		on s.ChainID = ch.ChainID
		inner join #tempStoreTransactions tmp
		on s.StoreTransactionID = tmp.StoreTransactionID
		left join @tempinvoicedetails i
		on i.ChainID = s.ChainID
		and i.StoreID = s.StoreID 
		and i.ProductID = s.ProductID
		and i.BrandID = s.BrandID
		and i.SupplierID = s.SupplierID
		and DATEDIFF(D,i.SaleDateTime,s.SaleDateTime)=0
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
           ,s.UPC
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
		  ,isnull([Adjustment1],0)
		  ,isnull([Adjustment2],0)
		  ,isnull([Adjustment3],0)
		  ,isnull([Adjustment4],0)
		  ,isnull([Adjustment5],0)
		  ,isnull([Adjustment6],0)
		  ,isnull([Adjustment7],0)
		  ,isnull([Adjustment8] ,0) 
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]
		  ,Qty    
		  ,ch.PDITradingPartner  
		  ,SourceID  
		  ,RecordType 
		  ,s.ProcessID
		  ,s.EDIRecordID
		  ,s.RetailerItemNo    
        having SUM(Qty) <> 0 
	

update t set TransactionStatus = case when transactionstatus = 800 then 810 else 811 end
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

		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_New'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyPOSBilling_New'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Invoicing Has Stopped'
			,'An exception occurred in prInvoiceDetail_POS_Create_New.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
		
end catch

Drop Table #tempStoreTransactions
END
GO
