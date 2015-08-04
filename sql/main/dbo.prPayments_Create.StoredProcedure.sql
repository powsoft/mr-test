USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPayments_Create]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPayments_Create]
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

declare @rec cursor

begin try
/*
select * from statustypes
select * from statuses where statustypeid = 12
select * from InvoicesSupplier
*/

select SupplierID, SupplierInvoiceId, OriginalAmount, CAST(null as int) as PaymentID
into #tempInvoicesToPay
from InvoicesSupplier
where InvoiceStatus = 1

set @rec = CURSOR local fast_forward FOR
	select Supplierid, SUM(OriginalAmount) As PaymentAmount
	from #tempInvoicesToPay
	group by SupplierId




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
