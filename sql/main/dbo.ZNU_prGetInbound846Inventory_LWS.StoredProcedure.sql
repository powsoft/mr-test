USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prGetInbound846Inventory_LWS]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ZNU_prGetInbound846Inventory_LWS]
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
--and EdiName = 'PEP'
--and EdiName = 'GOP'
and PurposeCode = 'CNT'
--and PurposeCode = '00'
--and CAST(effectivedate as date) = '1/2/2012'
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
           --,[SupplierInvoiceNumber]
           --,[ReportedUnitPrice]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[CorporateIdentifier]
           ,[EDIName]
           ,[RecordID_EDI_852])
           --,[DateTimeSourceReceived])
     select distinct
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(isnull(SupplierIdentifier, 'DEFAULT')))
           ,Qty
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           --,InvoiceNumber
           ,Cost
           ,Retail
           ,'INV'
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           ,StoreDuns
           ,EDIName
           ,s.recordid
           --,TimeStamp
     from DataTrue_EDI..Inbound846Inventory s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId

           
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
		
end catch
	

update s set RecordStatus = @loadstatus
--from DataTrue_EDI..InBoundSuppliers s
from DataTrue_EDI..Inbound846Inventory s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
and s.RecordStatus = 0


return
GO
