USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_INV_Debug]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_INV_Debug]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7595

begin try


update t set t.WorkingStatus = 1
--select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.WorkingStatus = -2
and t.WorkingSource in ('INV')

select distinct StoreTransactionID, UPC
into #tempStoreTransaction
--drop table #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('INV')
and ChainIdentifier = 'DG'

begin transaction

set @loadstatus = 2


update t set t.ProductID = p.ProductID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and WorkingStatus = 1
and t.ProductID is null
and ltrim(rtrim(t.UPC)) not in
(
	select ltrim(rtrim(UPC)) 
	from dbo.Util_DisqualifiedUPCbySupplier
	where SupplierID in (41440)
)
update t set t.WorkingStatus = -11
--select *
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t 
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Util_DisqualifiedUPCbySupplier u
on t.UPC = u.UPC
and t.SupplierID=u.SupplierID
where t.ProductID is null
and WorkingStatus=1

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null
and WorkingStatus = 1 and WorkingStatus<>-11

if @@ROWCOUNT > 0
	begin
		
		set @errormessage = 'UNKNOWN Product Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	

update t set BrandID = b.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Brands] b
on t.BrandIdentifier = b.BrandIdentifier
where LEN(t.BrandIdentifier) > 0 
and t.BrandIdentifier is not null
and t.WorkingStatus = 1


update t set t.BrandID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where (t.BrandIdentifier is null or LEN(t.BrandIdentifier) = 0)
and t.WorkingStatus = 1


update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and WorkingStatus = 1

if @@ROWCOUNT > 0
	begin
		
		set @errormessage = 'UNKNOWN Brand Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_INV'
		
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

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped'
				,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
end catch


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.workingstatus = 1
--and t.ProductID is not null

	
return
GO
