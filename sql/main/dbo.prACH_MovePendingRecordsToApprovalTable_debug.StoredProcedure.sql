USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_MovePendingRecordsToApprovalTable_debug]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from DataTrue_EDI.dbo.EDI_LoadStatus_ACH 


CREATE procedure [dbo].[prACH_MovePendingRecordsToApprovalTable_debug]
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 53826

begin try
/*		
	-- check for bad storeid
	if Exists
	(
		select distinct ia.StoreNumber 
		FROM DataTrue_EDI.dbo.EDI_LoadStatus_ACH ls
		inner join datatrue_edi.dbo.ProcessStatus_ACH ps 
					on ps.SupplierName = ls.Chain and cast(ps.Date as date) = CAST(ls.DateLoaded as date)
		inner join [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] ia
			on ltrim(rtrim(ls.[FileName])) = ltrim(rtrim(ia.[filename]))
		inner join chains  c 
			on ltrim(rtrim(c.chainidentifier)) = ltrim(rtrim(ia.chainname)) 
		left join stores s 
			on ia.storenumber = s.storeidentifier
		where s.StoreIdentifier is null
		and billingisrunning = 1
		and BillingComplete = 0
	)
	Begin

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Move to Approval Aborted'
			, N'One or more invalid StoreNumber values were detected in DataTrue_EDI.dbo.Inbound846Inventory_ACH.
			   No records were moved to the approval table.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
		return		
	End
*/
		
begin transaction
/*
select distinct filename 
into #tmpFilesToMove
from datatrue_edi.dbo.EDI_LoadStatus_ACH
where LoadStatus = 1
*/

INSERT INTO [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval]
           ([RecordID]
           ,[ChainName]
           ,[PurposeCode]
           ,[ReportingCode]
           ,[ReportingMethod]
           ,[ReportingLocation]
           ,[StoreDuns]
           ,[ReferenceIDentification]
           ,[ProductQualifier]
           ,[ProductIdentifier]
           ,[BrandIdentifier]
           ,[SupplierDuns]
           ,[SupplierIdentifier]
           ,[StoreNumber]
           ,[UnitMeasure]
           ,[QtyLevel]
           ,[Qty]
           ,[Cost]
           ,[Retail]
           ,[EffectiveDate]
           ,[EffectiveTime]
           ,[TermDays]
           ,[ItemNumber]
           ,[AllowanceChargeIndicator1]
           ,[AllowanceChargeCode1]
           ,[AlllowanceChargeAmount1]
           ,[AllowanceChargeMethod1]
           ,[AllowanceChargeIndicator2]
           ,[AllowanceChargeCode2]
           ,[AlllowanceChargeAmount2]
           ,[AllowanceChargeMethod2]
           ,[AllowanceChargeIndicator3]
           ,[AllowanceChargeCode3]
           ,[AlllowanceChargeAmount3]
           ,[AllowanceChargeMethod3]
           ,[AllowanceChargeIndicator4]
           ,[AllowanceChargeCode4]
           ,[AlllowanceChargeAmount4]
           ,[AllowanceChargeMethod4]
           ,[AllowanceChargeIndicator5]
           ,[AllowanceChargeCode5]
           ,[AlllowanceChargeAmount5]
           ,[AllowanceChargeMethod5]
           ,[AllowanceChargeIndicator6]
           ,[AllowanceChargeCode6]
           ,[AlllowanceChargeAmount6]
           ,[AllowanceChargeMethod6]
           ,[AllowanceChargeIndicator7]
           ,[AllowanceChargeCode7]
           ,[AlllowanceChargeAmount7]
           ,[AllowanceChargeMethod7]
           ,[AllowanceChargeIndicator8]
           ,[AllowanceChargeCode8]
           ,[AlllowanceChargeAmount8]
           ,[AllowanceChargeMethod8]
           ,[FileName]
           ,[TimeStamp]
           ,[EdiName]
           ,[CountType]
           ,[Issue]
           ,[ProductName]
           ,[RecordType]
           ,[RawProductIdentifier]
           ,[RawStoreNo]
           ,[InvoiceDueDate]
           ,[DataTrueSupplierID]
           ,[DataTrueChainID]
           ,[DataTrueStoreID]
           ,[DataTrueProductID]
           ,[DataTrueBrandID]
           ,[ShipAddress1]
           ,[ShipAddress2]
           ,[ShipCity]
           ,[ShipState]
           ,[ShipZip]
           ,[ShipPhoneNo]
           ,[ShipFax]
           ,[ContactName]
           ,[ContactPhoneNo]
           ,[PurchaseOrderNo]
           ,[PurchaseOrderDate]
           ,[TermsNetDueDate]
           ,[TermsNetDays]
           ,[TermsDescription]
           ,[PacksPerCase]
           ,[DivisionID]
           ,[RefInvoiceno]
           ,[RouteNo])
SELECT [RecordID]
      ,[ChainName]
      ,[PurposeCode]
      ,[ReportingCode]
      ,[ReportingMethod]
      ,[ReportingLocation]
      ,[StoreDuns]
      ,[ReferenceIDentification]
      ,[ProductQualifier]
      ,[ProductIdentifier]
      ,[BrandIdentifier]
      ,[SupplierDuns]
      ,[SupplierIdentifier]
      ,[StoreNumber]
      ,[UnitMeasure]
      ,[QtyLevel]
      ,[Qty]
      ,[Cost]
      ,[Retail]
      ,[EffectiveDate]
      ,[EffectiveTime]
      ,[TermDays]
      ,[ItemNumber]
      ,[AllowanceChargeIndicator1]
      ,[AllowanceChargeCode1]
      ,[AlllowanceChargeAmount1]
      ,[AllowanceChargeMethod1]
      ,[AllowanceChargeIndicator2]
      ,[AllowanceChargeCode2]
      ,[AlllowanceChargeAmount2]
      ,[AllowanceChargeMethod2]
      ,[AllowanceChargeIndicator3]
      ,[AllowanceChargeCode3]
      ,[AlllowanceChargeAmount3]
      ,[AllowanceChargeMethod3]
      ,[AllowanceChargeIndicator4]
      ,[AllowanceChargeCode4]
      ,[AlllowanceChargeAmount4]
      ,[AllowanceChargeMethod4]
      ,[AllowanceChargeIndicator5]
      ,[AllowanceChargeCode5]
      ,[AlllowanceChargeAmount5]
      ,[AllowanceChargeMethod5]
      ,[AllowanceChargeIndicator6]
      ,[AllowanceChargeCode6]
      ,[AlllowanceChargeAmount6]
      ,[AllowanceChargeMethod6]
      ,[AllowanceChargeIndicator7]
      ,[AllowanceChargeCode7]
      ,[AlllowanceChargeAmount7]
      ,[AllowanceChargeMethod7]
      ,[AllowanceChargeIndicator8]
      ,[AllowanceChargeCode8]
      ,[AlllowanceChargeAmount8]
      ,[AllowanceChargeMethod8]
      ,[FileName]
      ,[TimeStamp]
      ,[EdiName]
      ,[CountType]
      ,[Issue]
      ,[ProductName]
      ,[RecordType]
      ,[RawProductIdentifier]
      ,[RawStoreNo]
      ,[InvoiceDueDate]
      ,[DataTrueSupplierID]
      ,[DataTrueChainID]
      ,[DataTrueStoreID]
      ,[DataTrueProductID]
      ,[DataTrueBrandID]
      ,[ShipAddress1]
      ,[ShipAddress2]
      ,[ShipCity]
      ,[ShipState]
      ,[ShipZip]
      ,[ShipPhoneNo]
      ,[ShipFax]
      ,[ContactName]
      ,[ContactPhoneNo]
      ,[PurchaseOrderNo]
      ,[PurchaseOrderDate]
      ,[TermsNetDueDate]
      ,[TermsNetDays]
      ,[TermsDescription]
      ,[PacksPerCase]
      ,[DivisionID]
      ,[RefInvoiceno]
      ,[RouteNo]
      --select ediname, *
      --select sum(qty * cost)
      --update a set recordstatus=1
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] a
  Where RecordStatus=0
  and EdiName = 'WSBeer'
  --order by timestamp
	
	--where FileName in
	--(select FileName from #tmpFilesToMove)

if @@ROWCOUNT > 0
	begin
		DECLARE @emailaddresses VARCHAR(5000) = ''

		Select  @emailaddresses  = @emailaddresses + [login] +';'
		From dbo.TB_UploadLog 
		Inner Join logins On ownerentityid = personid
		Where filename in (Select filename From #tmpFilesToMove)
		
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices Are Pending Approval'
		,'Regulated invoices have been loaded and are pending approval.'
		,'DataTrue System', 0,@emailaddresses, '','datatrueit@icontroldsd.com;Edi@icontroldsd.com'	
	
	end
			
update a set a.recordstatus = 1
from [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] a
inner join #tmpFilesToMove f
on LTRIM(rtrim(a.FileName)) = LTRIM(rtrim(f.FileName))
	where a.[FileName] in
	(select FileName from #tmpFilesToMove)

update c set c.loadstatus = 2
from datatrue_edi.dbo.EDI_LoadStatus_ACH c
where LoadStatus = 1
and c.[FileName] in
	(select FileName from #tmpFilesToMove)
and c.loadstatus = 1

commit transaction

end try

begin catch

rollback transaction

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
			@job_name = 'Billing_Regulated_NewInvoiceData_MoveToApprovalTable'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job Billing_Regulated_NewInvoiceData_MoveToApprovalTable'
			,'An exception was encountered in prACH_MovePendingRecordsToApprovalTable'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		

end catch

return
GO
