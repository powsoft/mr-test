USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_846_ACH_C2S]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundSUPTransactions_846_ACH_C2S]

As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @ExistFilesComplete bit = 0
declare @ExistFilesIncomplete bit = 0
declare @MyID int
set @MyID = 53827

begin try


UPDATE i 
SET 
	 ProductIdentifier = '999999999998'
	,RawProductIdentifier = '999999999998'
--select *
FROM 
	DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
WHERE 
	1 = 1
and RecordStatus = 0
and Qty <> 0
and PurposeCode in ('DB','CR')
and (LEN(ProductIdentifier) < 1 or ProductIdentifier is null)
and CHARINDEX('Bottle Return', ProductName) > 0
--and EdiName in ('GLWINE')
--for testing
--AND ediname = 'WSBeer'
--and [FileName] not in (select [FileName] from #partialapprovals)


SELECT 
	RecordID 
INTO 
	#tempInboundTransactions 
--select *
FROM 
	DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
WHERE 1 = 1
and RecordStatus = 0
and PurposeCode in ('DB','CR')
and ProductIdentifier is not null
and StoreNumber is not NULL
and ChainName in ('SPN')
and LEN(storenumber) > 0


BEGIN TRANSACTION

set @loadstatus = 1

--/*
INSERT INTO [dbo].[StoreTransactions_Working]
(
	 [ChainIdentifier]
	,[StoreIdentifier]
	,[SupplierIdentifier]
	
	,[Qty]
	,[SaleDateTime]
	,[UPC]
	
	,[BrandIdentifier]
	,[SupplierInvoiceNumber]
	--,[ReportedUnitPrice]
	,[ReportedCost]
	,[ReportedRetail]
	
	,[WorkingSource]
	,[LastUpdateUserID]
	,[SourceIdentifier]
	--,[DateTimeSourceReceived]
	,[Banner]
	,[CorporateIdentifier]
	,[EDIName]--)
	,[RecordID_EDI_852]
	,[RawProductIdentifier]
	,[InvoiceDueDate]
	,[Adjustment1]
	,[Adjustment2]
	,[Adjustment3]
	,[Adjustment4]
	,[Adjustment5]
	,[Adjustment6]
	,[Adjustment7]
	,[Adjustment8]
	,[ItemSKUReported]
	,[ItemDescriptionReported]
	,[RawStoreIdentifier]
	,[Route]
	,[UOM]
)
SELECT
	 ltrim(rtrim(ChainName))
	,ltrim(rtrim(StoreNumber))
	,ltrim(rtrim(SupplierIdentifier))
	--,sum(Qty)
	--/*
	,case when Purposecode = 'DB' then Qty 
		when Purposecode = 'CR' then Qty * -1
		else Qty
	end
	--*/
	,cast(effectiveDate as date)
	,ProductIdentifier
	
	,BrandIdentifier
	,ReferenceIDentification
	,cost
	,retail
	
	,case when Purposecode = 'DB' then 'SUP-S' 
		when Purposecode = 'CR' then 'SUP-U' 
		else 'SUP-X' 
	end
	,@MyID
	,isnull(FileName, 'DEFAULT')
	--,cast([TimeStamp] as date)
	,[ReportingLocation]
	,[StoreDuns]
	,[EDIName]
	,s.[RecordID]
	,[Rawproductidentifier]
	,[TermsNetDueDate]
	,isnull([AlllowanceChargeAmount1], 0)
	,isnull([AlllowanceChargeAmount2], 0)
	,isnull([AlllowanceChargeAmount3], 0)
	,isnull([AlllowanceChargeAmount4], 0)
	,isnull([AlllowanceChargeAmount5], 0)
	,isnull([AlllowanceChargeAmount6], 0)
	,isnull([AlllowanceChargeAmount7], 0)
	,isnull([AlllowanceChargeAmount8], 0)
	,ltrim(rtrim(ItemNumber))
	,LTRIM(rtrim(ProductName))
	,LTRIM(rtrim(RawStoreNo))
	,LTRIM(rtrim(RouteNo))
	,LTRIM(rtrim([UnitMeasure]))
 FROM 
	 DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
	 ----------------------
	 inner join 
	 ----------------------
	 #tempInboundTransactions t
		on s.RecordID = t.RecordId
 WHERE
	s.RecordStatus = 0	--PAUL TSYGURA fix 10/29/2013
 ORDER BY				--PAUL TSYGURA fix 10/29/2013
	s.RecordID			--PAUL TSYGURA fix 10/29/2013
		
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
		
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'			

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'An exception was encountered in prGetInboundSUPTransactions_846_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontrol.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	
UPDATE s 
	SET RecordStatus = @loadstatus
FROM 
	DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
	--------------------
	inner join 
	--------------------
	#tempInboundTransactions t
	on 
		s.RecordID = t.RecordID
WHERE		
	s.RecordStatus = 0	--PAUL TSYGURA fix 10/29/2013


return
GO
