USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_SBT_New]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_SBT_New]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @ProcessID int
set @MyID = 7415 

begin try

INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (9) --JobRunningID 3 = DailyRegulatedBilling
SELECT @ProcessID = SCOPE_IDENTITY()
UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobRunningID = 9

begin transaction

If OBJECT_ID('[datatrue_main].[dbo].[GetRecordID_NewsPaper]') Is Not Null Drop Table [datatrue_main].[dbo].[GetRecordID_NewsPaper]

Select RecordID 
Into [datatrue_main].[dbo].[GetRecordID_NewsPaper]
--Select *
From DataTrue_EDI..Inbound852Sales 
Where ChainIdentifier in (select Distinct EntityIdentifier 
								from dbo.ProcessStepEntities 
								where ProcessStepName Not In ('prGetInboundPOSTransactions_PDI'))
and Qty <> 0
AND (RecordStatus = 0)

Create clustered index IDX_RecordedID on [datatrue_main].[dbo].[GetRecordID_NewsPaper](RecordID) With(MaxDop = 0)


set @loadstatus = 1



		INSERT INTO [dbo].[StoreTransactions_Working]
			(
				[ChainIdentifier]
				,[StoreIdentifier]
				,[SourceIdentifier]
				,[SupplierIdentifier]
				,[DateTimeSourceReceived]
				,[Qty]
				,[SaleDateTime]
				,[UPC]
				,[ProductCategoryIdentifier]
				,[BrandIdentifier]
				,[SupplierInvoiceNumber]
				,[ReportedCost]
				,[ReportedRetail]
				,[ReportedPromotionPrice]
				,[ReportedAllowance]
				,[DateTimeCreated]
				,[LastUpdateUserID]
				,[DateTimeLastUpdate]
				,[WorkingSource]
				,[RecordID_EDI_852]
				,[StoreName]
				,[ProductQualifier]
				,[RawProductIdentifier]
				,[SupplierName]
				,[DivisionIdentifier]
				,[UOM]
				,[SalePrice]
				,[InvoiceNo]
				,[PONo]
				,[CorporateName]
				,[CorporateIdentifier]
				,[EDIBanner]
				,[RecordType]
				,[ProductCategoryDescriptionReported]
				,[ItemDescriptionReported]
				,[ItemSKUReported]
				,[UOMQty]
				,[ReferenceIdentification]
				,[GLN]
				,[GTIN]
				,[RetailerItemNo]
				,[SupplierItemNo]
				,[ProcessID] 
			)
		select 
			 Ltrim(rTrim([ChainIdentifier]))
			,Ltrim(rTrim([StoreIdentifier]))
			,Case when Chainidentifier = 'TOP' Then Isnull(Ltrim(rTrim(left(Filename, 100))), 'DEFAULT') else Isnull(Ltrim(rTrim(Filename)), 'DEFAULT') end
			,Ltrim(rTrim([SupplierIdentifier]))
			,[DateTimeReceived]
			,[Qty]
			,[Saledate]
			,Ltrim(rTrim([ProductIdentifier]))
			,Ltrim(rTrim([ProductCategoryIdentifier]))
			,Ltrim(rTrim([BrandIdentifier]))
			,[InvoiceNo]
			,Case WHen ChainIdentifier = 'KNG' then [SalePrice] Else Cost End
			,[Retail]
			,[PromotionPrice]
			,[Allowance]
			,Getdate()
			,@myId
			,Getdate()
			,'POS'
			,s.[RecordID] 
			,isnull([StoreName], ' ')
			,isnull([ProductQualifier], ' ')
			,isnull([RawProductIdentifier], ' ')
			,isnull([SupplierName], ' ')
			,isnull([DivisionIdentifier], ' ')
			,isnull([UnitMeasure], ' ')
			,isnull([SalePrice], 0.0)
			,isnull([InvoiceNo], ' ')
			,isnull([PONo], ' ')
			,isnull([CorporateName], ' ')
			,isnull([CorporateIdentifier], ' ')
			,isnull([Banner], ' ')
			,[RecordType]
			,isnull([ProductCategoryDescription], ' ')
			,isnull([ItemDescription], ' ')
			,[ItemSKU]
			,[UOMQty]
			,[ReferenceIdentification]
			,[GLN]
			,[GTIN]
			,[RetailerItemNo]
			,[SupplierItemNo]
			,@ProcessID
		from DataTrue_EDI..Inbound852Sales s
		inner join [datatrue_main].[dbo].[GetRecordID_NewsPaper] t
		on s.RecordID = t.RecordId
     
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
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped -Test'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com'		
		
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join [datatrue_main].[dbo].[GetRecordID_NewsPaper] t
on s.RecordID = t.RecordID
GO
