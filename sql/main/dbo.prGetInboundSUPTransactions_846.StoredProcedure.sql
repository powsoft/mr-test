USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_846]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundSUPTransactions_846]

As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
DECLARE @ProcessID INT
declare @MyID int
set @MyID = 7427

begin try
 
 SET XACT_ABORT ON

--SET PROCESS ID
	INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (16) --JobRunningID 3 = DailyRegulatedBilling
	SELECT @ProcessID = SCOPE_IDENTITY()
	UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID,JobLastRunDateTime=GETDATE() WHERE JobName = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE_5AM'

select RecordID 
into #tempInboundTransactions 
--select *
--select min(effectivedate)
--select distinct filename, timestamp, recordstatus
--select distinct filename, recordstatus
--select distinct ediname
--select purposecode, qty as q, timestamp, *
--update i set qty = qty * -1
from DataTrue_EDI.dbo.Inbound846Inventory i with (nolock)
--INNER JOIN DataTrue_Main.dbo.ProductIdentifiers AS p 
--ON InBoundSuppliers.TitleID = p.IdentifierValue
WHERE 1 = 1
--and FileName = '71376.MSG'
and RecordStatus = 0
and Qty <> 0
--and EdiName not in ('NST')
--AND CAST(timestamp as date) = '2/24/2012'
--and Qty > 0
and ediname not in ('ACK')
--and FileName = 'ExcelEmailed20120326'
and EdiName in (select UniqueEDIName from Suppliers where InventoryIsActive = 1)
--and ediname in ('NST','PEP','SHM', 'GOP', 'BIM', 'LWS', 'SAR', 'SOUR', 'FLOW')
--and ediname in ('SHM', 'GOP', 'BIM', 'LWS', 'SAR')
--and PurposeCode in ('DB','CR')
and PurposeCode in ('DB','CR', 'O')
--and PurposeCode in ('CR')
and EffectiveDate > '11/30/2011'
and EffectiveDate is not null
and LEN(productidentifier) > 0
and ProductIdentifier is not null
and LEN(storenumber) > 0
and StoreNumber is not null
--and StoreNumber = '06004'
--and CAST(effectivedate as date) = '1/16/2012'
--and  CAST(TimeStamp as date) = '3/12/2012'
--and PurposeCode in ('CR')
--and EffectiveDate is not null
--and ltrim(rtrim(reportinglocation)) <> 'SHOP N SAVE WAREHOUSE'
order by recordid
--order by timestamp
--and p.ProductIdentifierTypeID = 2 --UPC
--and isnumeric(StoreIdentifier) > 0

/*
select *
from DataTrue_EDI.dbo.Inbound846Inventory i
WHERE 1 = 1
and RecordStatus = 0
and EffectiveDate > '11/30/2011'
and Qty <> 0
--and Qty > 0
and ediname in ('PEP')
--and ediname in ('PEP','SHM', 'GOP', 'BIM', 'LWS')
and PurposeCode in ('DB','CR')
--and PurposeCode in ('DB')
--and PurposeCode in ('CR')
and EdiName not in ('NST')
and LEN(productidentifier) > 0
and ProductIdentifier is not null
and LEN(storenumber) > 0
and StoreNumber is not null

select timestamp, count(recordid)
from DataTrue_EDI.dbo.Inbound846Inventory i
WHERE 1 = 1
and ltrim(rtrim(filename)) = 'FARMFRESH-INV-VAF0125_Split1.txt'
group by timestamp

select distinct recordstatus
from DataTrue_EDI.dbo.Inbound846Inventory

select *
--update i set recordstatus = 94
from DataTrue_EDI.dbo.Inbound846Inventory i
WHERE 1 = 1
and filename = '66080.MSG' --71376.MSG'
and recordstatus = 0
--and timestamp in ('2012-02-02 09:51:45.987','2012-02-02 09:51:46.003')
and timestamp in ('2012-02-02 09:56:55.360','2012-02-02 09:56:55.390')

select *
from DataTrue_EDI.dbo.Inbound846Inventory
WHERE RecordStatus = 0
and ediname = 'BIM'
and purposecode in ('DB','CR')
--and purposecode = 'CNT'
and EffectiveDate >= '12/1/2011'

select distinct purposecode
from DataTrue_EDI.dbo.Inbound846Inventory
WHERE RecordStatus = 0
and ediname = 'SHM'

select distinct ediname
from DataTrue_EDI.dbo.Inbound846Inventory
WHERE 1 = 1
and RecordStatus = 0
and Qty <> 0
and PurposeCode in ('DB','CR')
and EffectiveDate > '11/30/2011'

select *
from DataTrue_EDI.dbo.Inbound846Inventory
WHERE RecordStatus = 0
and ediname = 'SHM'
and purposecode = 'CNT'
*/

begin transaction

set @loadstatus = 1 --6 is LWS --5 is GOP 4 --4 is PEP delivieries/pickups --3 and 5 is schmidt deliveries/pickups --2 is big bimbo deliveries/pickups loaded 1/17/2012

--/*
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
           --,[DateTimeSourceReceived]
           ,[Banner]
           ,[CorporateIdentifier]
           ,[EDIName]--)
           ,[RecordID_EDI_852]
           ,[RawProductIdentifier]
           ,[InvoiceDueDate]
           ,[ItemDescriptionReported]
           ,[ItemSKUReported]
           ,[Route]
           ,ProcessID)--*/
     select
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(SupplierIdentifier))
           --,sum(Qty)
           --/*
           ,case when Purposecode = 'DB' then Qty 
				when Purposecode = 'CR' then Qty * -1
				when Purposecode = 'O' then Qty
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
				when Purposecode = 'O' then 'SUP-O'
				when Purposecode = 'CR' then 'SUP-U' 
				else 'SUP-X' 
			end
           ,7427 --@MyID
           ,isnull(FileName, 'DEFAULT')
           --,cast([TimeStamp] as date)
           ,[ReportingLocation]
           ,[StoreDuns]
           ,[EDIName]
           ,s.[RecordID]
           ,[Rawproductidentifier]
           ,[InvoiceDueDate]
           ,[ProductName]
           ,[ItemNumber]
           ,[Route]
           ,@ProcessID
     from DataTrue_EDI.dbo.Inbound846Inventory s with (nolock)
     /*
     WHERE RecordStatus = 0
		and Qty <> 0
		and ediname = 'LWS'
		and PurposeCode in ('DB','CR')
	*/
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId


/*
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
           --,[DateTimeSourceReceived]
           ,[Banner]
           ,[CorporateIdentifier]
           ,[EDIName])
     select
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(SupplierIdentifier))
           --,sum(Qty)
           --/*
           ,case when Purposecode = 'DB' then sum(Qty) 
				when Purposecode = 'CR' then Sum(Qty) * -1
				else sum(Qty)
			end
			--*/
           ,cast(effectiveDate as date)
           ,ProductIdentifier
           ,BrandIdentifier
           ,ReferenceIDentification
           ,max(cost)
           ,max(retail)
           ,case when Purposecode = 'DB' then 'SUP-S' 
				when Purposecode = 'CR' then 'SUP-U' 
				else 'SUP-X' 
			end
           ,7427 --@MyID
           ,isnull(FileName, 'DEFAULT')
           --,cast([TimeStamp] as date)
           ,[ReportingLocation]
           ,[StoreDuns]
           ,[EDIName]
     from DataTrue_EDI.dbo.Inbound846Inventory s
     /*
     WHERE RecordStatus = 0
		and Qty <> 0
		and ediname = 'LWS'
		and PurposeCode in ('DB','CR')
	*/
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId
	group by            ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(SupplierIdentifier))
           ,cast(effectiveDate as date)
           ,ProductIdentifier
           ,BrandIdentifier
           ,ReferenceIDentification
           ,Purposecode
           ,isnull(FileName, 'DEFAULT')
           --,cast([TimeStamp] as date)
           ,[ReportingLocation]
           ,[StoreDuns]
           ,[EDIName]
*/

commit transaction
	
end try
	
begin catch
		--rollback transaction
		IF XACT_STATE() <>0 ROLLBACK TRAN
		
		set @loadstatus = -9998

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		print @errormessage;
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		UPDATE 	DataTrue_Main.dbo.JobRunning
		SET JobIsRunningNow = 0
		WHERE JobName = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE_5AM'	
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	
update s set RecordStatus = @loadstatus
from DataTrue_EDI.dbo.Inbound846Inventory s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
/*
select distinct TransactionType from DataTrue_EDI..InBoundSuppliers
select StoreTransactionID into #tmpInboundPOS
from StoreTransactions_Working t
where t.WorkingStatus = 0
and WorkingSource = 'POS'

--Retailer's reported cost is iControl's ReportedSalePrice

update t
set t.ReportedUnitPrice = Case when t.ReportedUnitPrice < 0.0001 then t.ReportedUnitCost else t.ReportedUnitPrice end
from #tmpInboundPOS tmp
inner join StoreTransactions_Working t
on tmp.StoreTransactionID = t.StoreTransactionID

*/
/*
RoleID 7415
select * from StoreTransactions_Working
update EDI..Inbound852Sales set RecordStatus = 0
select purposecode, count(recordid)
from DataTrue_EDI.dbo.Inbound846Inventory
where ediname = 'GOP'
group by purposecode

select * from StoreTransactions_Working where workingsource in ('SUP-S','SUP-U') and (ediname = 'GOP' or supplierid = 40558)

select *
from DataTrue_EDI.dbo.Inbound846Inventory
where purposecode = '00'
--where supplieridentifier = '0070055640000'
and ediname = 'GOP'
and recordstatus = 0

select distinct recordstatus
from DataTrue_EDI.dbo.Inbound846Inventory

select * --into import.dbo.Inbound846Inventory_CreditsWithNegativeQtyBeforeReverse_20120126
--update i set qty = qty * -1
from DataTrue_EDI.dbo.Inbound846Inventory i
where ediname = 'GOP'
and purposecode = 'CR'
and qty < 0
and recordstatus = 0
--and EffectiveDate is not null

*/


return
GO
