USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_INV_X12]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInStoreTransactions_Working_INV_X12]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7485

begin try

select distinct StoreTransactionID, StoreID, ProductID
into #tempStoreTransaction
--select *
--update w set supplieridentifier = 'BIMBO'
from [dbo].[StoreTransactions_Working] --w
--where supplieridentifier = 'Bimbo Foods Inc.'
where WorkingStatus = 2
and WorkingSource in ('INV')

begin transaction

set @loadstatus = 3

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.SupplierID = s.SupplierID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Suppliers] s
on ltrim(rtrim(t.SupplierIdentifier)) = ltrim(rtrim(s.SupplierDeliveryIdentifier))

update t set WorkingStatus = -3
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'UNKNOWN Supplier Identifiers Found'
		set @errorlocation = 'prValidateSuppliersInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateSuppliersInStoreTransactions_Working_SUP'
		
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
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is not null
	
return
GO
