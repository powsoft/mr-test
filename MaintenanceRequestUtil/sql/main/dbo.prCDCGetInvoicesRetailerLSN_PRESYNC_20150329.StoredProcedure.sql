USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInvoicesRetailerLSN_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInvoicesRetailerLSN_PRESYNC_20150329]
	@from_lsn binary(10),
	@to_lsn binary(10)
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
--declare @from_lsn binary(10)
--declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_InvoicesRetailer');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_InvoicesRetailer_CT 
select * from cdc.dbo_InvoicesRetailer_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/


	delete cdc.dbo_InvoicesRetailer_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		--print @errormessage;
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 
		@errorlocation
		,@errormessage
		,'DataTrue System'
		, 0
		,'mandeep@amebasoftwares.com'
		
end catch
	

return
GO
