USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSourceInWarehouseTransactions_Working_INV]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSourceInWarehouseTransactions_Working_INV]

as
--select distinct supplierid from WarehouseTransactions_Working where workingstatus = 3

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try

select WarehouseTransactionID
into #tempWarehouseTransaction
from [dbo].[WarehouseTransactions_Working] t
where WorkingStatus = 3
and charindex('INV', WorkingSource) > 0
--and SupplierID = 40562

begin transaction

set @loadstatus = 4


select distinct SourceIdentifier, DateTimeSourceReceived
into #tempNewSources
from [dbo].[WarehouseTransactions_Working] t
where WorkingStatus = 3
and charindex('INV', WorkingSource) > 0
and t.SourceIdentifier not in (select SourceName from [Source])


INSERT INTO [dbo].[Source]
           ([SourceTypeID]
           ,[SourceName]
           ,[SourceLocation]
           ,[DateTimeReceived]
           ,[LastUpdateUserID])
     select distinct 1 --File Source is Type 1
           ,SourceIdentifier
           ,'UNKNOWN'
           ,DateTimeSourceReceived
           ,@MyID
           from #tempNewSources
           --where SourceIdentifier not in
			--(select SourceName from Source)
           
Update t Set t.SourceID = s.SourceID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join Source s
on t.SourceIdentifier = s.SourceName
--and cast(t.DateTimeSourceReceived as date) = cast(s.DateTimeReceived as date)

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
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.WorkingStatus = 3



return
GO
