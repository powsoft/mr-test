USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_StoreTransactionsWorking_ValidateNewsPaperUPCs]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPOS_StoreTransactionsWorking_ValidateNewsPaperUPCs]
as



declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7417

begin try

select distinct StoreTransactionID, UPC, 
ProductCategoryIdentifier, BrandIdentifier, ChainID, StoreID, SupplierIdentifier
into #tempStoreTransaction
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('POS')
--and ChainID = 40393
--drop table #tempStoreTransaction
begin transaction

set @loadstatus = 2

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.ProductID = p.ProductID, t.WorkingStatus = 2, t.BrandID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 8 --Multi_UPC is type 8
and ltrim(rtrim(t.UPC)) not in
(
	select ltrim(rtrim(UPC)) 
	from dbo.Util_DisqualifiedUPCbySupplier
	where SupplierID in (41440)
)

		commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999

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
GO
