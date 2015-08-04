USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundRetailerDeliveries_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundRetailerDeliveries_PRESYNC_20150415]
As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7593

begin try
	
	

begin transaction

set @loadstatus = 1

select RecordID into #tempRetailerDeliveries
     from DataTrue_EDI..Inbound846Inventory_RetailerDeliveries rd with (nolock)
     join DataTrue_EDI.dbo.EDI_LoadStatus_Receiving r with (nolock) on ltrim(rtrim(rd.FileName))=LTRIM(rtrim(r.FileName))
    where RecordStatus=0 
    and PurposeCode in ('DB','CR') and r.LoadStatus = 1
    
  --ADDED BY WILL SINCE IT IS STILL NOT HERE... 3/16/15
 UPDATE rd
 SET rd.ProductIdentifier = 'DEFAULT'
 FROM DataTrue_EDI..Inbound846Inventory_RetailerDeliveries rd
 WHERE ISNULL(rd.ProductIdentifier, '') = '' AND ISNULL(rd.ItemNumber, '') = ''
 AND RecordStatus = 0

INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
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
           --,[CorporateIdentifier]
           ,[EDIName]
           ,[RecordID_EDI_852]
           ,[RawProductIdentifier]
           ,[Banner]
         --  ,[CaseUPC]
          ,[DateTimeSourceReceived]
          ,PONo
          ,RefIDToOriginalInvNo
          ,RecordType
          ,RetailerItemNo
          ,ItemSKUReported
          ,UOM
          ,InvoiceDueDate
          ,Route
          )
     select distinct
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,SupplierIdentifier
           ,Qty
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           ,ReferenceIDentification
           ,Cost
           ,Retail
           ,Case PurposeCode when 'DB' then 'R-DB' else 'R-CR' end
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           --,StoreDuns
           ,EDIName
           ,s.RecordID
           ,RawProductIdentifier--ItemNumber
           ,ReportingLocation
           --,[CaseUPC]
           ,TimeStamp
           ,PurchaseOrderNo
           ,RefIDToOriginalInvNo
           ,RecordType
           ,RetailerItemNumber
           ,ItemNumber
           ,UnitMeasure
           ,InvoiceDueDate
           ,RouteNo
           --select * 
     from DataTrue_EDI..Inbound846Inventory_RetailerDeliveries s with (nolock)
     join #tempRetailerDeliveries t on s.RecordID=t.RecordID
    --where RecordStatus=0 and (ProductIdentifier is not null or ItemNumber is not null)
    --and PurposeCode='DB'
--     and Qty is not null

    
    --where RecordStatus=0 and ProductIdentifier is not null    and PurposeCode='DB'
	
	commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997
		

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
		--@job_name = 'LoadInventoryStoreReceipts'
		
		
		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Store Receipts Stopped'
		--		,'Inventory receipts load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
		--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'		

end catch
	
	update s set s.RecordStatus=@loadstatus
    from DataTrue_EDI..Inbound846Inventory_RetailerDeliveries s join #tempRetailerDeliveries t
    on s.RecordID=t.RecordID
    
    update r set r.LoadStatus=2,UpdatedTimeStamp=GETDATE()
    from #tempRetailerDeliveries t join
    DataTrue_EDI..Inbound846Inventory_RetailerDeliveries rd with (nolock)
    on t.RecordID=rd.RecordID
    join DataTrue_EDI.dbo.EDI_LoadStatus_Receiving r with (nolock) on ltrim(rtrim(rd.FileName))=LTRIM(rtrim(r.FileName))
GO
