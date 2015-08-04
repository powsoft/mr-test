USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInWarehouseTransactions_Working_SUP]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInWarehouseTransactions_Working_SUP]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try

select distinct WarehouseTransactionID, WarehouseID, ProductID
into #tempWarehouseTransaction
--select *
from [dbo].[WarehouseTransactions_Working]
where WorkingStatus = 2
and WorkingSource in ('WHS-DB', 'WHS-CR')

begin transaction

set @loadstatus = 3

update t set t.SupplierID = 
case when ediname = 'GOP' then 40558 --GOP
	when EDIName = 'PEP' then 40562
	when EDIName = 'SHM' then 40561
	when EDIName = 'BIM' then 40557
	when EDIName = 'LWS' then 41464
	when EDIName = 'SAR' then 41465
	when EDIName = 'NST' then 40559
	else null
end
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID

update t set WorkingStatus = -3
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where SupplierID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'UNKNOWN Supplier Identifiers Found'
		set @errorlocation = 'prValidateSuppliersInWarehouseTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateSuppliersInWarehouseTransactions_Working_SUP'
		
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
where SupplierID is not null
	
return
GO
