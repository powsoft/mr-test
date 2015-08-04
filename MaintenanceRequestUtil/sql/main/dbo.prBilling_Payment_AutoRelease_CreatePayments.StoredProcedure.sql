USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments]
as

declare @MyID int=7419
declare @rec cursor 
declare @rec2 cursor
declare @entityidtopay int
declare @newpaymentid int
declare @chainidpaying int
declare @invoiceno nvarchar(50)

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct EntityIDToInvoice from BillingControl
	where AutoReleasePaymentWhenDue = 1
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
		set @rec2 = CURSOR local fast_forward FOR
			select distinct chainid, ltrim(rtrim(InvoiceNo)) from InvoiceDetailS 
			where SupplierID = @entityidtopay 
			and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
			and PaymentID is null
			
			open @rec2
			
			fetch next from @rec2 into @chainidpaying, @invoiceno
			
			while @@FETCH_STATUS = 0
				begin
				
					truncate table #invoicedetailstopay
					
					insert into #invoicedetailstopay
					select InvoiceDetailID from InvoiceDetailS 
					where SupplierID = @entityidtopay 
					and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
					and PaymentID is null
					and ChainID = @chainidpaying
					and LTRIM(rtrim(InvoiceNo)) = @invoiceno



					INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID])
					VALUES
					   (4
					   ,@chainidpaying
					   ,@entityidtopay
					   ,@MyID) --<LastUpdateUserID, int,>)

					
					set @newpaymentid = SCOPE_IDENTITY()
					
					update d
					set d.paymentid = @newpaymentid
					from InvoiceDetailS d
					inner join #invoicedetailstopay p
					on d.InvoiceDetailID = p.InvoiceDetailID
					
					update Payments
					set Payments.AmountOriginallyBilled = (select SUM(totalcost) from InvoiceDetails where PaymentID = @newpaymentid)
					where Payments.PaymentID = @newpaymentid
					
					update ed set ed.paymentid = md.PaymentID
					from datatrue_edi.dbo.InvoiceDetails ed
					inner join datatrue_main.dbo.InvoiceDetails md
					on ed.InvoiceDetailID = md.InvoiceDetailID
					inner join #invoicedetailstopay t
					on md.InvoiceDetailID = t.InvoiceDetailID
					

					INSERT INTO [DataTrue_EDI].[dbo].[Payments]
							   ([PaymentID]
							   ,[PaymentTypeID]
							   ,[ChainID]
							   ,[SupplierID]
							   ,[AmountOriginallyBilled]
							   ,[LastUpdateUserID])
					SELECT [PaymentID]
						  ,[PaymentTypeID]
						  ,[PayerEntityID]
						  ,[PayeeEntityID]
						  ,[AmountOriginallyBilled]
						  ,[LastUpdateUserID]
					  FROM [DataTrue_Main].[dbo].[Payments]				
					
					fetch next from @rec2 into @chainidpaying, @invoiceno

				end


	
		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec






return
GO
