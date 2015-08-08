USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_INV_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInStoreTransactions_Working_INV_PRESYNC_20150415]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7596

begin try

select distinct StoreTransactionID, StoreID, ProductID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 2
and WorkingSource in ('INV')
--order by datetimecreated

begin transaction

set @loadstatus = 3

--/*

update t set t.SupplierID = (select SupplierID from Suppliers where UniqueEDIName=t.EDIName)
/*
select * from suppliers where uniqueediname = 'bim'
case when ediname = 'GOP' then 40558 --GOP
	when EDIName = 'PEP' then 40562
	when EDIName = 'SHM' then 40561
	when EDIName = 'BIM' then 40557
	when EDIName = 'LWS' then 41464
	when EDIName = 'SAR' then 41465
	when EDIName = 'NST' then 40559
	when EDIName = 'SOUR' then 41440
	else null
end*/
--update t set t.SupplierID = 40562 --PEP
--update t set t.SupplierID = 40561 --SHM
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
--*/

/*
update t set t.SupplierID = s.SupplierID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID and t.ProductID = s.ProductID
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
*/

/* replaced with block just above since data comes from chain
--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.SupplierID = s.SupplierID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Suppliers] s
on t.SupplierIdentifier = s.SupplierName
*/
update t set WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Supplier Identifiers Found - Status on StoreTransactions_Working set to -2'
		set @errorlocation = 'prValidateSuppliersInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateSuppliersInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
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
		@job_name = 'LoadInventoryCount'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped at [prValidateSuppliersInStoreTransactions_Working_INV]'
				,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
end catch
	
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 2


return
GO
