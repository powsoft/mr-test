USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_New]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_New]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @ProcessID int
set @MyID = 7415 

begin try

INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (14) --JobRunningID 3 = DailyRegulatedBilling
SELECT @ProcessID = SCOPE_IDENTITY()
UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobRunningID = 14

begin transaction

Select RecordID into #TempRecordID
from DataTrue_EDI..Inbound852Sales S
Where Banner = 'sv_jwl'
and RecordStatus = 0
and Qty <> 0
and CONVERT(date, S.DateTimeReceived) >= dateadd(day, -3, CONVERT(date, GETDATE()))

If OBJECT_ID('[datatrue_main].[dbo].[GetRecordID_NewsPaper]') Is Not Null Drop Table [datatrue_main].[dbo].[GetRecordID_NewsPaper]

Select RecordID, S.ChainIdentifier, RecordType, RecordStatus
Into [datatrue_main].[dbo].[GetRecordID_NewsPaper]
--Select *
From DataTrue_EDI..Inbound852Sales S
Inner join Chains C on S.ChainIdentifier = C.ChainIdentifier
Where S.ChainIdentifier in (select Distinct EntityIdentifier 
								from dbo.ProcessStepEntities 
								where ProcessStepName In ('prGetInboundPOSTransactions_New')
								and IsActive = 1)
and Qty <> 0
AND (RecordStatus = 0)
and Saledate >= C.ActiveStartDate
and RecordID not in (Select RecordID from #TempRecordID)
and CONVERT(date, S.DateTimeReceived) >= dateadd(day, -3, CONVERT(date, GETDATE()))


Create clustered index IDX_RecordedID on [datatrue_main].[dbo].[GetRecordID_NewsPaper](RecordID) With(MaxDop = 0)

Delete
--Select *
From GetRecordID_NewsPaper
Where chainidentifier = 'sv'
and RecordType = 0
and RecordStatus = 0

Select *
from GetRecordID_NewsPaper


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
			 Ltrim(rTrim(S.[ChainIdentifier]))
			,Ltrim(rTrim([StoreIdentifier]))
			,Isnull(Ltrim(rTrim(Filename)), 'DEFAULT')
			,Ltrim(rTrim([SupplierIdentifier]))
			,[DateTimeReceived]
			,[Qty]
			,[Saledate]
			,Ltrim(rTrim([ProductIdentifier]))
			,Ltrim(rTrim([ProductCategoryIdentifier]))
			,Ltrim(rTrim([BrandIdentifier]))
			,[InvoiceNo]
			,Case WHen S.ChainIdentifier = 'KNG' then [SalePrice] Else Cost End
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
			,S.RecordType
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
			@job_name = 'DailyPOSBilling_New'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Record Processing'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueid@icucsolutions.com; gilad.keren@icucsolutions.com'		
		
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join [datatrue_main].[dbo].[GetRecordID_NewsPaper] t
on s.RecordID = t.RecordID


Update S Set RecordStatus = -1
--Select *
From DataTrue_EDI..Inbound852Sales S
Inner join Chains C on S.ChainIdentifier = C.ChainIdentifier
Where S.ChainIdentifier not in (select Distinct EntityIdentifier 
								from dbo.ProcessStepEntities 
								where ProcessStepName In ('prGetInboundPOSTransactions_BAS', 'prGetInboundPOSTransactions'))
and Qty <> 0
AND (RecordStatus = 0)
and Saledate < C.ActiveStartDate
and CONVERT(date, S.DateTimeReceived) >= dateadd(day, -1, CONVERT(date,GETDATE()))

Drop Table #TempRecordID
GO
