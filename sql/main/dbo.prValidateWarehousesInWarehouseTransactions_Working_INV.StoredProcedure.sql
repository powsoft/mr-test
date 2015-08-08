USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateWarehousesInWarehouseTransactions_Working_INV]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateWarehousesInWarehouseTransactions_Working_INV]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus int
declare @MyID int
set @MyID = 7594

begin try

select distinct WarehouseTransactionID, ChainIdentifier, WarehouseIdentifier
into #tempWarehouseTransaction
from [dbo].[WarehouseTransactions_Working] w
where WorkingStatus = 0
and WorkingSource in ('INV')

begin transaction

set @loadstatus = 1

update Warehousetransactions_working 
set EDIBanner =
case when ltrim(rtrim(ediname)) = 'GOP' then 'SV'
else null
end
where 1 = 1
and workingstatus = 0
and workingsource in ('INV')
and EDIName = 'GOP'
	
update Warehousetransactions_working 
set EDIBanner =
case when ltrim(rtrim(corporateidentifier)) = '0032326880002' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '0242503670000' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '1939636180000' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '0069271877700' then 'ABS'
	when ltrim(rtrim(corporateidentifier)) = '0069271807700' then 'ABS'
	when ltrim(rtrim(corporateidentifier)) = '8008812780000' then 'SS'
else null
end
where 1 = 1
and workingstatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'

update t set t.ChainID = c.ChainID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier
where t.WorkingStatus = 0

update t set t.WorkingStatus = -1
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and ChainID is null

if @@ROWCOUNT > 0
	begin
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Unknown Chain Identifiers Found.  Records in the WarehouseTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateWarehousesInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_INV'
		
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
--and WarehouseID is null
and ISNUMERIC(t.WarehouseIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Warehouse Identifiers Found.  Records in the WarehouseTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateWarehousesInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.WarehouseID = s.WarehouseID
from [dbo].[WarehouseTransactions_Working] t
inner join [dbo].[Warehouses] s
on t.ChainID = s.ChainID 
and cast(t.WarehouseIdentifier as int) = cast(s.WarehouseIdentifier as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'
and t.WarehouseID is null

update t set t.WarehouseID = s.WarehouseID
from [dbo].[WarehouseTransactions_Working] t
inner join [dbo].[Warehouses] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.WarehouseIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'
and t.WarehouseID is null	
	
	

update t set t.WarehouseID = c.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] c
on t.ChainID = c.ChainID
and CAST(t.WarehouseIdentifier as int) = CAST(c.WarehouseIdentifier as int)
and ltrim(rtrim(c.Custom1)) = 'Cub Foods'
and t.EDIName in ('GOP')
where t.WorkingStatus = 0

update t set t.WarehouseID = c.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] c
on t.ChainID = c.ChainID
and CAST(t.WarehouseIdentifier as int) = CAST(c.WarehouseIdentifier as int)
and ltrim(rtrim(c.Custom1)) = 'Shoppers Food and Pharmacy'
and t.EDIName in ('SHM')
where t.WorkingStatus = 0



update t set t.WarehouseID = s.WarehouseID
--select s.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] s
on t.ChainID = s.ChainID 
and cast(t.WarehouseIdentifier as int) = cast(s.WarehouseIdentifier as int)
--and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
where 1 = 1
and EDIName in ('BIM')
and WorkingStatus = 0
and workingsource in ('INV')
and t.WarehouseID is null

update t set t.WarehouseID = s.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.WarehouseIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
--and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'BIM'
and t.WarehouseID is null



update t set t.WarehouseID = c.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] c
on t.ChainID = c.ChainID
and CAST(t.WarehouseIdentifier as int) = CAST(c.WarehouseIdentifier as int)
and c.Custom3 = 'SS'
and t.EDIName in ('LWS')
where t.WorkingStatus = 0

update t set t.WarehouseID = c.WarehouseID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Warehouses] c
on t.ChainID = c.ChainID
and CAST(t.WarehouseIdentifier as int) = CAST(c.WarehouseIdentifier as int)
and ltrim(rtrim(c.Custom1)) in ('Shop N Save Warehouse Foods Inc')
and t.EDIName in ('SAR')
where t.WorkingStatus = 0


update t set t.WorkingStatus = -1
from [dbo].[WarehouseTransactions_Working] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where WorkingStatus = 0
and WarehouseID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Warehouse Identifiers Found.  Records in the WarehouseTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateWarehousesInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateWarehousesInWarehouseTransactions_Working_INV'
		
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
		
		set @loadstatus = -9997

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

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
	
--print 'got here'
--print @loadstatus
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.WorkingStatus = 0

return
GO
