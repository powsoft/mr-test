USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_846_ACH_PDI]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundSUPTransactions_846_ACH_PDI]

As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @ExistFilesComplete bit = 0
declare @ExistFilesIncomplete bit = 0
declare @MyID int
set @MyID = 53827

begin try

/*
--get list of files with partially approved records
--so we avoid processing them until they are complete
Select [FileName] 
into #PartialApprovals
from 
(
	select distinct [filename] 
	from DataTrue_edi.dbo.Inbound846Inventory_ACH_Approval
	where isnull(RecordStatus,99999999999999999) = 0
union all
	select distinct [filename] 
	from DataTrue_edi.dbo.Inbound846Inventory_ACH_Approval
	where isnull(RecordStatus,99999999999999999) <> 0 
) a 
group by [filename]
having COUNT([filename]) > 1

Select @ExistFilesIncomplete = 1 Where Exists(Select [FileName] From #PartialApprovals)

Select @ExistFilesComplete = 1	Where Exists(Select [FileName] 
								From DataTrue_edi.dbo.Inbound846Inventory_ACH_Approval
								Where RecordStatus = 0
								And [FileName] Not In(Select [FileName] From #PartialApprovals))

If (@ExistFilesIncomplete = 1)
Begin
	declare @FileSupplierContacts table
	(
		RowID  int not null identity(1,1) primary key,
		[filename]		varchar(100),
		emailAddress	varchar(50),   
		supplier		varchar(20)
	)

	Insert Into @FileSupplierContacts
	([filename],
	 emailaddress,
	 supplier)
	Select 
	rtrim(ltrim(ul.[filename])) [filename],
	[login],
	partnerid
	From dbo.TB_UploadLog ul
	inner join DataTrue_EDI.dbo.EDI_LoadStatus_ACH ls
		on rtrim(ltrim(ul.[filename])) = RTRIM(ltrim(ls.[filename]))
	Inner Join logins l On l.ownerentityid = ul.personid
	Where ul.filename in (Select [filename] From #partialapprovals)

	declare @email varchar(100)
	declare @filename varchar(100)
	declare @supplier varchar(100)
	declare @msg varchar(4000)
	declare @SupportEmailBody varchar(4000)
	declare @i int
	select @i = min(RowID) from @FileSupplierContacts
	declare @max int

	select @max = max(RowID) from @FileSupplierContacts

	if (select COUNT([filename]) from #partialapprovals) > 0
	Begin

		Set @msg = N'Your submission of today''s regulated invoices has only been partially approved.
		' + N'Full approval is required before these invoices can be processed and paid.' + N'
		' + N'
		Please complete full approval.' 

		Set @SupportEmailBody =
		N'The system detected that these suppliers have invoices with some approved records ' + N'
		and some not yet approved. They have all been emailed requesting full approval.' + N'
		'

		While (@i <= @max) 
		Begin
			Select  @filename = [filename], 
					@email = emailaddress, 
					@supplier = supplier 
			From @FileSupplierContacts 
			Where RowID = @i 
		    
			--send supplier email
			Exec dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices have incomplete approval'
				,@msg,'DataTrue System', 0,'vince.moore@icontroldsd.com'--@email, '',''
				
			--add to icontrol support email - we'll collect all the suppliers and 
			-- send just one email to support staff with the list
			set @SupportEmailBody = @SupportEmailBody
				+ @supplier	+ '  ' + @email + '  ' + @filename + N''
			
			set @i = @i + 1
		End
		--send icontrol support email
		Exec dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices have incomplete approval'
				,@SupportEmailBody,'DataTrue System', 0,'vince.moore@icontroldsd.com'--@email, '',''
	End
End

--no point in continuing if there are no complete records to process
If @ExistFilesComplete = 0 
Begin
	Exec dbo.prSendEmailNotification_PassEmailAddresses 'prGetInboundSUPTransactions_846_ACH'
		,N'No records to process after checking for partial approvals.
		Returning from procedure' ,'DataTrue System', 0,'vince.moore@icontroldsd.com'--@email, '',''
	return
End

*/

update i set ProductIdentifier = '999999999998', RawProductIdentifier = '999999999998'
--select *
from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
WHERE 1 = 1
and RecordStatus = 0
and Qty <> 0
--and EdiName in ('GLWINE')
and PurposeCode in ('DB','CR')
and (LEN(ProductIdentifier) < 1 or ProductIdentifier is null)
and CHARINDEX('Bottle Return', ProductName) > 0
--and [FileName] not in (select [FileName] from #partialapprovals)


select RecordID 
into #tempInboundTransactions 
--select *
from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i --order by RecordID desc
WHERE 1 = 1
and RecordStatus = 2
and ChainName in ('CTM', 'CST')
and PurposeCode in ('DB','CR')
--and ProductIdentifier is not null
and LEN(storenumber) > 0
and StoreNumber is not null
--and [FileName] not in (select [FileName] from #partialapprovals)


--return from procedure - no point in continuing if no records are present
/*
If (Select COUNT(RecordID) From #tempInboundTransactions) < 1
Begin
	--not sure if we want to log this condition somewhere or not
	Exec dbo.prSendEmailNotification_PassEmailAddresses 'prGetInboundSUPTransactions_846_ACH'
				,N'No records in temptable.
				Returning from procedure','DataTrue System', 0,'vince.moore@icontroldsd.com'--@email, '',''
	return;
End
*/

begin transaction

set @loadstatus = 1

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
           ,[Adjustment1]
           ,[Adjustment2]
           ,[Adjustment3]
           ,[Adjustment4]
           ,[Adjustment5]
           ,[Adjustment6]
           ,[Adjustment7]
           ,[Adjustment8]
           ,[ItemSKUReported]
           ,[ItemDescriptionReported]
           ,[RawStoreIdentifier]
           ,[Route])--*/
     select
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(SupplierIdentifier))
           --,sum(Qty)
           --/*
           ,case when Purposecode = 'DB' then Qty 
				when Purposecode = 'CR' then Qty * -1
				else Qty
			end
			--*/
           ,cast(effectiveDate as date)
           ,isnull(ProductIdentifier, '')
           ,BrandIdentifier
           ,ReferenceIDentification
           ,cost
           ,retail
           ,case when Purposecode = 'DB' then 'SUP-S' 
				when Purposecode = 'CR' then 'SUP-U' 
				else 'SUP-X' 
			end
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           --,cast([TimeStamp] as date)
           ,[ReportingLocation]
           ,[StoreDuns]
           ,[EDIName]
           ,s.[RecordID]
           ,isnull([Rawproductidentifier], '')
           ,[TermsNetDueDate]
           ,isnull([AlllowanceChargeAmount1], 0)
           ,isnull([AlllowanceChargeAmount2], 0)
           ,isnull([AlllowanceChargeAmount3], 0)
           ,isnull([AlllowanceChargeAmount4], 0)
           ,isnull([AlllowanceChargeAmount5], 0)
           ,isnull([AlllowanceChargeAmount6], 0)
           ,isnull([AlllowanceChargeAmount7], 0)
           ,isnull([AlllowanceChargeAmount8], 0)
           ,ltrim(rtrim(ItemNumber))
           ,LTRIM(rtrim(ProductName))
           ,LTRIM(rtrim(RawStoreNo))
           ,LTRIM(rtrim(RouteNo))
     from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
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
		
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'			

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'An exception was encountered in prGetInboundSUPTransactions_846_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'vince.moore@icontrol.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	
update s set RecordStatus = @loadstatus
from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID



return

/*
select *
from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval
where chainname in ('cst', 'ctm')

select *
from DataTrue_EDI.dbo.Inbound846Inventory_ACH
where chainname in ('cst', 'ctm')
*/
GO
