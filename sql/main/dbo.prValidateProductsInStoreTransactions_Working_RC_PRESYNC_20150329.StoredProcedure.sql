USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_RC_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_RC_PRESYNC_20150329]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7583

begin try

update t set t.WorkingStatus = 1
--select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.WorkingStatus = -2
and t.WorkingSource in ('RC')



update t set t.UPC=ISNULL(DataTrue_EDI.dbo.fnParseUPC(t.UPC),0)
--select DataTrue_EDI.dbo.fnParseUPC(t.UPC)
from [dbo].[StoreTransactions_Working] t
where WorkingStatus = 1
and t.WorkingSource in ('RC')
and LEN(UPC)<>12


select distinct StoreTransactionID, UPC,ProductID,WorkingStatus,BrandIdentifier,BrandID,EDIName
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working] t
where WorkingStatus = 1
and t.WorkingSource in ('RC')



begin transaction

set @loadstatus = 2


update t set t.ProductID = p.ProductID
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and (t.ProductID is null or t.ProductID = 0)


update t set t.WorkingStatus = -2
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Product Identifiers Found'
		set @errorlocation = '[prValidateProductsInStoreTransactions_Working_RC]'
		set @errorsenderstring = '[prValidateProductsInStoreTransactions_Working_RC]'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end


update t set t.BrandID = 0
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.brandidentifier is null)

update t set t.BrandID = b.BrandID
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
inner join Brands b
on t.BrandIdentifier = b.BrandIdentifier
where t.BrandID is null
and len(t.BrandIdentifier) > 0

update t set t.WorkingStatus = -2
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = '[prValidateProductsInStoreTransactions_Working_RC]'
		set @errorsenderstring = '[prValidateProductsInStoreTransactions_Working_RC]'
		
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
	

update t set WorkingStatus = @loadstatus--, LastUpdateUserID = @MyID
from #tempStoreTransaction t
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 1
and t.ProductID is not null

update t set WorkingStatus = tmp.WorkingStatus,t.BrandID=tmp.BrandID,t.ProductID=tmp.ProductID, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID




return
GO
