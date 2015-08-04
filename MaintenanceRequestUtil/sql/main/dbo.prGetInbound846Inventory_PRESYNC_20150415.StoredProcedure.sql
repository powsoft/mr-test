USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInbound846Inventory_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInbound846Inventory_PRESYNC_20150415]
As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7593

begin try
	
	
	
select RecordID 
into #tempInboundTransactions  
--select *
from DataTrue_EDI..Inbound846Inventory
--INNER JOIN dbo.ProductIdentifiers AS p 
--ON Inbound846Inventory.ProductIdentifier = p.IdentifierValue
WHERE 1 = 1
and RecordStatus = 0
--and EdiName in ('SHM', 'PEP', 'GOP', 'BIM', 'LWS')
and PurposeCode = 'CNT'
--and EdiName = 'SHM'
and EdiName in (select UniqueEDIName from Suppliers where InventoryIsActive = 1)
and ProductIdentifier is not null
--and FileName='NestleInventoryPizza.xls'
--and EdiName = 'GOP'
--and PurposeCode = '00'
--and CAST(effectivedate as date) = '12/5/2011'
--and CAST(effectivedate as date) = '2012-03-12'
--and CHARINDEX('Albert', Reportinglocation) > 0
--and p.ProductIdentifierTypeID = 2 --UPC
--and isnumeric(StoreNumber) > 0
--and cast(EffectiveDate as date) in ('2012-02-27','2012-03-05')
--and EffectiveDate >= '2011-12-05 00:00:00.000'
--and EffectiveDate > '2011-12-02 00:00:00.000'

order by EffectiveDate
begin transaction

set @loadstatus = 1


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
           ,[CorporateIdentifier]
           ,[EDIName]
           ,[RecordID_EDI_852]
           ,[RawProductIdentifier]
           ,[Banner]
           ,[CaseUPC])
           --,[DateTimeSourceReceived])
     select distinct
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(isnull(SupplierIdentifier, 'DEFAULT')))
           ,Qty
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           ,ReferenceIDentification
           ,Cost
           ,Retail
           ,'INV'
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           ,StoreDuns
           ,EDIName
           ,s.recordid
           ,[RawProductIdentifier]
           ,[ReportingLocation]
           ,[CaseUPC]
           --,TimeStamp
     from DataTrue_EDI..Inbound846Inventory s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId
--     and Qty is not null

           
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
		
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'LoadInventoryCount'
		
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped'
				,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'		

end catch
	
update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound846Inventory s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
GO
