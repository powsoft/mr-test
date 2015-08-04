USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundInventory_WEB]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundInventory_WEB]

As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7427

begin try

update t set t.ProductIdentifier = 'DEFAULT'
--select * from DataTrue_EDI.dbo.InboundInventory_WEB order by recordid desc
--select *
from DataTrue_EDI.dbo.InboundInventory_WEB t
where t.RecordStatus = 0
and LEN(isnull(t.ProductIdentifier,'')) < 1
and t.DataTrueProductID = 0

update t set t.DataTrueProductID = p.ProductID
--select *
from DataTrue_EDI.dbo.InboundInventory_WEB t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ProductIdentifier)) = ltrim(rtrim(p.IdentifierValue))
and t.RecordStatus = 0
and p.ProductIdentifierTypeID = 2 
and (t.DataTrueProductID is null or t.DataTrueProductID = 0)

select RecordID 
into #tempInboundTransactions 
--select *
--select min(effectivedate)
--update i set recordstatus = 1
--select sum(qty * cost), sum(qty)
--select distinct ProductIdentifier
from DataTrue_EDI.dbo.InboundInventory_WEB i
--INNER JOIN DataTrue_Main.dbo.ProductIdentifiers AS p 
--ON InBoundSuppliers.TitleID = p.IdentifierValue
WHERE 1 = 1
and RecordStatus = 0
and Qty <> 0
and PurposeCode in ('DB','CR')
and EffectiveDate is not null
and LEN(productidentifier) > 0
and ProductIdentifier is not null
and LEN(storenumber) > 0
and StoreNumber is not null
--and CAST(DateTimeCreated as date) = '6/28/2013'
--and ReferenceIdentification <> 'D779228'
--and CHARINDEX('Gagan', ReferenceIdentification) < 1
order by recordid


/*

*/

begin transaction

set @loadstatus = 1 --6 is LWS --5 is GOP 4 --4 is PEP delivieries/pickups --3 and 5 is schmidt deliveries/pickups --2 is big bimbo deliveries/pickups loaded 1/17/2012

--/*
INSERT INTO [dbo].[StoreTransactions_Working]
           ([Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[RecordID_EDI_852]
           ,[InvoiceDueDate]
           ,[Adjustment1]
           ,[Adjustment2]
           --,[Adjustment3]
           --,[Adjustment4]
           --,[Adjustment5]
           --,[Adjustment6]
           --,[Adjustment7]
           --,[Adjustment8]
           ,[ChainID]
           ,[StoreID]
           ,[SupplierID]
           ,[ProductID]
           ,StoreIdentifier
           ,RecordType
           ,WorkingStatus
           ,BrandID)--*/
     select
           Qty
           ,cast(effectiveDate as date)
           ,ProductIdentifier
           ,ReferenceIDentification
           ,cost
           ,retail
           ,case when Purposecode = 'DB' then 'SUP-S' 
				when Purposecode = 'CR' then 'SUP-U' 
				else 'SUP-X' 
			end
           ,0
           ,isnull(FileName, 'DEFAULT')
           ,cast(DateTimeCreated as date)
           ,s.[RecordID]
           ,[InvoiceDueDate]
           ,isnull([Adjustment1], 0)
           ,isnull([Adjustment2], 0)
           --,isnull([Adjustment3], 0)
           --,isnull([Adjustment4], 0)
           --,isnull([Adjustment5], 0)
           --,isnull([Adjustment6], 0)
           --,isnull([Adjustment7], 0)
           --,isnull([Adjustment8], 0)
           ,DataTrueChainID
           ,DataTrueStoreID
           ,DataTrueSupplierID
           ,DataTrueProductID
           ,StoreIdentifier
           ,RecordType
           ,3
           ,0
     from DataTrue_EDI.dbo.InboundInventory_Web s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId


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
		
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'DailySUPLoadWebInvoices_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'		
				--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	
update s set RecordStatus = @loadstatus
from DataTrue_EDI.dbo.InboundInventory_Web s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
/*

select *
from productidentifiers
where productid = 0
*/


return
GO
