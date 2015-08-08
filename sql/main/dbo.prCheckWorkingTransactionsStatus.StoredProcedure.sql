USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCheckWorkingTransactionsStatus]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCheckWorkingTransactionsStatus]

as
Begin
	
	select
	WorkingSource,WorkingStatus,
	COUNT(StoreTransactionID) as "Count"
	into #tempTableCounts
	from
	StoreTransactions_Working 
	where
	DATEDIFF(hour,DateTimeCreated,Getdate()) > 12 
	and
	DATEDIFF(hour,DateTimeCreated,Getdate()) < 48 
	and
	WorkingStatus not in (5, 11, 12) 
	group
	by WorkingSource,WorkingStatus
--drop table #tempTableCounts
--select * from #tempTableCounts


declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)


if (@@ROWCOUNT>0) --or (1 = 0)
begin

	declare @body varchar(max)='Below is the summary for the records in working transactions table';
	set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
	set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">WorkingSource</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">WorkingStatus</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Count</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Comments</th></tr>'
	
	select 
		@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ WorkingSource +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+CAST( WorkingStatus as nvarchar) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+CAST(Count as nvarchar) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ 
		Case WorkingStatus 
		when 0 then 'New records status didnt get process yet'
		when 1 then 'Processed till step 1(Store Validate)'
		when 2 then 'Processed till step 2(Product Validate)'
		when 3 then 'Processed till step 3(Supplier Validate)'
		when 4 then 'Processed till step 4(Source Validate)'
		when -1 then 'Store Identifier is not matching'
		when -2 then 'Product Identifier is not matching'
		when -6 then 'Duplicate record in working table'
		when -10 then 'Duplicate record in transactions table'
		else
			'Manually parked records'
	End  +'</td></tr>'
	from #tempTableCounts 
	
	set @body=@body+'</table>';
		
		set @errormessage = @body;
		set @errorlocation = 'Notification for working transactions record status'
		set @errorsenderstring = 'prCheckWorkingTransactionsStatus'
		
		
		exec [dbo].[prSendEmailNotification_PassEmailAddresses_HTML]
			@errorlocation
			,@errormessage
			,@errorsenderstring
			,0
			,'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com;edi@icontroldsd.com'
			,''
			,''
	end
	
else
	Begin
		set @errormessage = 'Didn''t find any pending record'
			set @errorlocation = 'Notification for working transactions record status'
			set @errorsenderstring = 'prCheckWorkingTransactionsStatus'
			
			exec dbo.prLogExceptionAndNotifySupport
			2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
			,@errorlocation
			,@errormessage
			,@errorsenderstring
			,0
	End
		
End
GO
