USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateWarehouseInWarehouseTransactions_Working_SUP]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateWarehouseInWarehouseTransactions_Working_SUP]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try

select distinct WarehouseTransactionID, ChainIdentifier, WarehouseIdentifier
into #tempWarehouseTransaction
--select *
from [dbo].[WarehouseTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('WHS-DB','WHS-CR')

begin transaction

set @loadstatus = 1

update t set t.WorkingStatus = -5
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and WorkingSource in ('WHS-X')

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Supplier Transactions Types Found'
		set @errorlocation = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

		
update t set t.ChainID = c.ChainID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier

update t set t.WorkingStatus = -1
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and ChainID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Chain Identifiers Found'
		set @errorlocation = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.WorkingStatus = -1
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and WarehouseID is null
and ISNUMERIC(t.WarehouseIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Warehouse Identifiers Found'
		set @errorlocation = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end



update t set t.WarehouseID = s.WarehouseID
--select *
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] s
--on t.ChainID = s.ChainID 
--and
 on cast(t.WarehouseIdentifier as int) = cast(s.WarehouseIdentifier as int)
where 1 = 1
and WorkingStatus = 0
and workingsource in ('WHS-CR', 'WHS-DB')
and t.WarehouseID is null
	
update t set t.WorkingStatus = -1
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and WarehouseID is null
and ISNUMERIC(t.SourceOrDestinationIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Source or Destination Identifiers Found'
		set @errorlocation = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	
	
update t set t.SourceOrDestinationID = s.WarehouseID
--select *
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] s
on cast(t.SourceOrDestinationIdentifier as int) = cast(s.WarehouseIdentifier as int)
where 1 = 1
and WorkingStatus = 0
and workingsource in ('WHS-CR', 'WHS-DB')
and t.SourceOrDestinationID is null


if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Source or Destination Identifiers Found'
		set @errorlocation = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

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
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.WorkingStatus = 0

drop table #tempWarehouseTransaction
	
return
GO
