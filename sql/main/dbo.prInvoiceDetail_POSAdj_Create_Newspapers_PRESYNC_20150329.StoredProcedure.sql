USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_POSAdj_Create_Newspapers_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery9.sql|7|0|C:\Users\vince.moore\AppData\Local\Temp\7\~vs38A6.sql


CREATE procedure [dbo].[prInvoiceDetail_POSAdj_Create_Newspapers_PRESYNC_20150329]
--@invoicedetailtype tinyint,
@saledate date=null
/*
prInvoiceDetail_Retailer_POS_Create '6/2/2011', 1
*/
as

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
set @invoicedetailtype = 7 --POSAdjSource

begin try

begin transaction


select StoreTransactionID
into #tempStoreTransactions
--select *
--update t set t.productidentifier = t.rawproductidentifier
from StoreTransactions t
where TransactionStatus in (800, 801)
and TransactionTypeID in (7,16)
--order by StoreTransactionID desc
--and ChainID in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))
--and ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prInvoiceDetail_POS_Create_Newspapers')
--and ChainID in (64010, 65151, 65232, 60624, 74628, 62362)
--and CAST(saledatetime as date) <= '2/16/2014' 
--and ChainID in (64074,64298)
--and ChainID in (60624) --74628) --60624) --64010) --60624) --62362)
and CAST(datetimecreated as date) = CAST(GETDATE() as date) --'2/17/2015'
and isnull(RuleCost,0) <> 0
and RuleRetail is not null
--and isnull(RuleRetail,0) <> 0
and Qty <> 0
and productid in (select productid from ProductIdentifiers where ProductIdentifierTypeID = 8)
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
		  ,[SourceID])
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,0 --s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(Qty) as TotalQty
           ,SUM(Qty * (RuleCost - isnull(PromoAllowance, 0))) + SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) as TotalCost
           ,SUM(Qty * RuleRetail) as TotalRetail
           ,SUM(Qty * (RuleCost))/SUM(Qty) as UnitCost
       ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
           ,@MyID
           ,CAST(s.SaleDateTime as DATE) as SaleDate
           ,@batchstring --ChainIdentifier
           ,StoreIdentifier
           ,StoreName
           ,case when len(isnull(UPC,'')) < 1 then RawProductIdentifier else UPC end
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
		  ,SUM(Qty * RuleRetail)*dbo.fnGetServiceFeePercentOfRetail(S.ChainID) --isnull([Adjustment1],0)
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
		FROM [dbo].[StoreTransactions] s
		inner join #tempStoreTransactions tmp
		on s.StoreTransactionID = tmp.StoreTransactionID
		left join @tempinvoicedetails i
		on i.ChainID = s.ChainID
		and i.StoreID = s.StoreID 
		and i.ProductID = s.ProductID
		--and i.BrandID = s.BrandID
		and i.SupplierID = s.SupplierID
		--and i.SaleDateTime = s.SaleDateTime
		and DATEDIFF(D,i.SaleDateTime,s.SaleDateTime)=0
		--and i.UnitCost = SUM(Qty * (RuleCost))/SUM(Qty)--s.UnitCost
		where i.ChainID is null
		group by s.[ChainID]
           ,s.[StoreID]
           ,s.[ProductID]
           --,s.[BrandID]
           ,s.[SupplierID]
           ,CAST(s.SaleDateTime as DATE)
           ,s.RuleCost--) S
           ,s.ChainIdentifier
           ,s.StoreIdentifier
           ,s.StoreName
           ,s.UPC --s.ProductIdentifier
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
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prInvoiceDetail_SUP_Create_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch

return
GO
