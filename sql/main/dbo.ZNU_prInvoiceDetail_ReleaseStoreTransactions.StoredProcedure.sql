USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prInvoiceDetail_ReleaseStoreTransactions]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prInvoiceDetail_ReleaseStoreTransactions]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24134

begin try

select StoreTransactionID 
into #tempStoreTransactions  
from StoreTransactions
where TransactionStatus = 1
and TransactionTypeID not in (10,11)

begin transaction

update t
set transactionstatus = 800
from  StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
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
