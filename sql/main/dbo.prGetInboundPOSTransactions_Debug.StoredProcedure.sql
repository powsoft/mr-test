USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_Debug]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_Debug]
/*
RoleID 7415
truncate table StoreTransactions_Working
update DataTrue_EDI..Inbound852Sales set RecordStatus = 0
select * from DataTrue_EDI..Inbound852Sales where RecordStatus = 0 and banner = 'SS' SVEC.20111115121330_SPLIT7
select * from DataTrue_EDI..Inbound852Sales where RecordStatus = 0 and filename = 'SVEC.20111117133423_SPLIT86'
select distinct banner from DataTrue_EDI..Inbound852Sales where RecordStatus = 0
update DataTrue_EDI..Inbound852Sales set recordstatus = -7 where RecordStatus = 0 and Banner = 'SS'
select top 100 * from  DataTrue_EDI..Inbound852Sales
select distinct workingstatus from StoreTransactions_Working

ABS.20111123065255_SPLIT4
SVEC.20111123121147_SPLIT7
SVEC.20111123121147_SPLIT8
*/
As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7415 

begin try
--select distinct filename delete from DataTrue_EDI..Inbound852Sales  where recordstatus = 0
select RecordID 
into #tempInboundTransactions  
--select *
--update s set s.recordtype = 0
from DataTrue_EDI..Inbound852Sales s
where RecordStatus in (33)
--and SupplierIdentifier = '5188734'
--and Saledate in ('12/10/2011')
--and Saledate in ('11/30/2011','12/2/2011')
--and ChainIdentifier = 'SV'
--and Banner in ('ABS','SV')
--and banner = 'SS'
--and banner = 'SV'
--and ChainIdentifier in (select EntityIdentifier from ProcessStepEntities where ProcessStepName = 'prGetInboundPOSTransactions')
--and ChainIdentifier in ('SV', 'KR')
--and isnull(banner, '') not in ('SV_SHW','SYNC')
--and isnull(banner, '') <> 'SYNC'
and RecordType = 0
--and filename = 'SVEC.20111123121147_SPLIT8'
and Qty <> 0
--order by StoreIdentifier, productidentifier

begin transaction

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
           --,[ReportedUnitRetail]
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
           ,[UOMQty]
           ,[referenceidentification]
           ,[GLN]
           ,[GTIN]
           ,[RetailerItemNo]
           ,[SupplierItemNo]
           ,[PackSize]
           ,[RecordType])
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
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
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
           ,[referenceidentification]
           ,[GLN]
           ,[GTIN]
           ,[RetailerItemNo]
           ,[SupplierItemNo]
           ,[PackSize]  
           ,[RecordType]         
     from DataTrue_EDI..Inbound852Sales s
     inner join #tempInboundTransactions t
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

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueid@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID

/*
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
GO
