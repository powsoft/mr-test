USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_Supplier_ReleaseForPayment]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[prInvoices_Supplier_ReleaseForPayment]
as


declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @dummycount int
declare @MyID int
set @MyID = 40386 

begin try



begin transaction

select RetailerInvoiceID 
into #paidretailerinvoices
from InvoicesRetailer
where InvoiceStatus = 2

update InvoiceDetails
set RecordStatus = 2
where RetailerInvoiceID in
(
	select RetailerInvoiceID
	from #paidretailerinvoices
)

update DataTrue_EDI..InvoiceDetails
set RecordStatus = 2
where RetailerInvoiceID in
(
	select RetailerInvoiceID
	from #paidretailerinvoices
)


declare @rec cursor
declare @supplierinvoiceid int
set @rec = cursor local fast_forward for
	select distinct supplierinvoiceid
	from invoicedetails
	where recordstatus = 2
	
open @rec

fetch next from @rec into @supplierinvoiceid

while @@fetch_status = 0
	begin
		select distinct recordstatus
		from invoicedetails
		where supplierinvoiceid = @supplierinvoiceid
		
		if @@rowcount = 1
			begin
				update InvoicesSupplier set invoicestatus = 1 where supplierinvoiceid = @supplierinvoiceid
				update Invoicedetails set recordstatus = 3 where supplierinvoiceid = @supplierinvoiceid
				update DataTrue_EDI..InvoicesSupplier set invoicestatus = 1 where supplierinvoiceid = @supplierinvoiceid
				update DataTrue_EDI..Invoicedetails set recordstatus = 3 where supplierinvoiceid = @supplierinvoiceid
			end
		
		fetch next from @rec into @supplierinvoiceid	
	end
	
close @rec
deallocate @rec


update r set r.InvoiceStatus = 3
from InvoicesRetailer r
inner join #paidretailerinvoices tmp
on r.RetailerInvoiceID = tmp.RetailerInvoiceID

update r set r.InvoiceStatus = 3
from DataTrue_EDI..InvoicesRetailer r
inner join #paidretailerinvoices tmp
on r.RetailerInvoiceID = tmp.RetailerInvoiceID

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




return
GO
