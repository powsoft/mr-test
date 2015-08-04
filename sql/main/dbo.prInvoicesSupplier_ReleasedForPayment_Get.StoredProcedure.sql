USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoicesSupplier_ReleasedForPayment_Get]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoicesSupplier_ReleasedForPayment_Get]
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 40387 

begin try


select s.SupplierName, s.SupplierID, SupplierInvoiceID as InvoiceNo, InvoiceDate, OriginalAmount as Amount
from InvoicesSupplier i
inner join Suppliers s
on i.SupplierID = s.SupplierID
where InvoiceStatus = 1

	
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

return
GO
