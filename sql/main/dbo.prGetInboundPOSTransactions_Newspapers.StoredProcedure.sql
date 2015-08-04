USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_Newspapers]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_Newspapers]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7415 

begin try

begin transaction

If OBJECT_ID('[datatrue_main].[dbo].[GetRecordID_NewsPaper]') Is Not Null Drop Table [datatrue_main].[dbo].[GetRecordID_NewsPaper]

Select RecordID 
Into [datatrue_main].[dbo].[GetRecordID_NewsPaper]
--Select *
From DataTrue_EDI..Inbound852Sales 
Where ChainIdentifier in ('TOP')
and RecordType = 2
and Qty <> 0
AND (RecordStatus = 0)

Create clustered index IDX_RecordedID on [datatrue_main].[dbo].[GetRecordID_NewsPaper](RecordID) With(MaxDop = 0)


set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
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
           ,[ProductCategoryDescriptionReported]
           ,[ItemDescriptionReported]
           ,[ItemSKUReported]
           ,[UOMQty])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           ,'POS'
           ,@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		   ,[ProductCategoryDescription]
           ,[ItemDescription]
           ,[ItemSKU]
           ,[UOMQty]
     from DataTrue_EDI..Inbound852Sales s
     inner join [datatrue_main].[dbo].[GetRecordID_NewsPaper] t
     on s.RecordID = t.RecordId
     order by s.RecordID
     
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
