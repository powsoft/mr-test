USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreTransactions_WorkingLSN_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreTransactions_WorkingLSN_PRESYNC_20150415]
	@from_lsn binary(10),
	@to_lsn binary(10)
as

declare @MyID int
declare @count int
--declare @from_lsn binary(10)
--declare @to_lsn binary(10)

set @MyID = 0

begin try

	
print '@from_lsn:' 
print @from_lsn;
print '@from_lsn:' 
print @to_lsn;

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_StoreTransactions_Working_CT 
	select * from DataTrue_Main.cdc.dbo_StoreTransactions_Working_CT with (nolock)
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

	
delete DataTrue_Main.cdc.dbo_StoreTransactions_Working_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
end try
	
begin catch

		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		print @errormessage
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
