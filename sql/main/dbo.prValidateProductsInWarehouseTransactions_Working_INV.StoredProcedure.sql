USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInWarehouseTransactions_Working_INV]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prValidateProductsInWarehouseTransactions_Working_INV]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try

select distinct WarehouseTransactionID, UPC
into #tempWarehouseTransaction
--select *
from [dbo].[WarehouseTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('INV')

begin transaction

set @loadstatus = 2


update t set t.ProductID = p.ProductID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and WorkingStatus = 1
and t.ProductID is null

update t set t.WorkingStatus = -2
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.ProductID is null
and WorkingStatus = 1

if @@ROWCOUNT > 0
	begin
		
		set @errormessage = 'UNKNOWN Product Identifiers Found.  Records in the WarehouseTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInWarehouseTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	

update t set BrandID = b.BrandID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
inner join [dbo].[Brands] b
on t.BrandIdentifier = b.BrandIdentifier
where LEN(t.BrandIdentifier) > 0 
and t.BrandIdentifier is not null
and t.WorkingStatus = 1


update t set t.BrandID = 0
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where (t.BrandIdentifier is null or LEN(t.BrandIdentifier) = 0)
and t.WorkingStatus = 1


update t set t.WorkingStatus = -2
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.BrandID is null
and WorkingStatus = 1

if @@ROWCOUNT > 0
	begin
		
		set @errormessage = 'UNKNOWN Brand Identifiers Found.  Records in the WarehouseTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInWarehouseTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInWarehouseTransactions_Working_INV'
		
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
		
end catch
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions_Working] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where t.workingstatus = 1
--and t.ProductID is not null


	
return
GO
