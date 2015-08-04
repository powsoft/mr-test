USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_Create_Debug]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_Create_Debug]
as
/*
Need to pend (not at 3 or 4 paymentstatus payment records that violate the billingexclusion
Below taken from disbursement procedure

	select distinct PayeeEntityID
	from Payments p
	inner join PaymentDisbursementReleaseControl c
	on p.PayeeEntityID = c.PaymentDisbursementPayeeEntityID
	and p.PaymentStatus in (3,4)
	and CAST(getdate() as date) >= CAST(NextDisbursementDateTime as date)


select * from suppliers where suppliername = 'Clarion-Ledger'

select * 
--update r set Invoicestatus = 2
from invoicesretailer r
where chainid = 62362 and invoicestatus = 3

select * from invoicedetails where supplierid = 24164
*/
declare @MyID int=7419
declare @rec cursor 
declare @rec2 cursor
declare @entityidtopay int
declare @newpaymentid int
declare @chainidpaying int
declare @totalpaymentcost money
declare @totalpaymentretail money
declare @chainname nvarchar(50)
declare @suppliername nvarchar(50)
declare @820releasefirststatus smallint

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct Supplierid
	from InvoicesRetailer r
	inner join InvoiceDetailS d
	on r.RetailerInvoiceID = d.RetailerInvoiceID
	and r.InvoiceStatus = 2
	and r.ChainID in (select EntityIDtoInclude from ProcessStepEntities where ProcessStepName = 'prBilling_Payment_Create')
	and d.SaleDate <= '8/18/2013'
	and d.SupplierID <> 0
	and d.PaymentID is null
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
		set @rec2 = CURSOR local fast_forward FOR
			select distinct s.chainid 
			from InvoicesRetailer s
			inner join InvoiceDetailS d
			on s.RetailerInvoiceID = d.RetailerInvoiceID
			and d.SupplierID = @entityidtopay 
			and d.ChainID in (select EntityIDtoInclude from ProcessStepEntities where ProcessStepName = 'prBilling_Payment_Create')
			--and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
			and d.PaymentID is null
			and d.RetailerInvoiceID is not null
			and d.SaleDate <= '8/18/2013'
			
			open @rec2
			
			fetch next from @rec2 into @chainidpaying
			
			while @@FETCH_STATUS = 0
				begin
				
					select @820releasefirststatus = c.Payment820ReleaseFirstStatus
					--select *
					from dbo.PaymentDisbursementReleaseControl c
					where PaymentDisbursementPayerEntityID = @chainidpaying
					
					truncate table #invoicedetailstopay
					
					begin transaction
					
					insert into #invoicedetailstopay
					select InvoiceDetailID 
					from InvoiceDetailS d
					inner join InvoicesRetailer s
					on d.RetailerInvoiceID = s.RetailerInvoiceID
					and d.SupplierID = @entityidtopay
					and d.paymentid is null 
					--and CAST(d.datetimecreated as date) = '11/13/2012'
					--and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
					and s.ChainID = @chainidpaying
					and d.SaleDate <= '8/18/2013'
					--and d.SupplierId <> 0

					--select *
					--from InvoiceDetailS d
					--inner join InvoicesSupplier s
					--on d.SupplierInvoiceID = s.SupplierInvoiceID
					--and s.SupplierID = 41440
					----and d.paymentid is null 
					----and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
					--and ChainID = 42491
					--and CAST(d.datetimecreated as date) = '11/7/2012'
					--order by invoicedetailid

					INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID]
					   ,[PaymentStatus])
					VALUES
					   (1 --paymentreleasefrom820
					   ,@chainidpaying
					   ,@entityidtopay
					   ,@MyID
					   ,@820releasefirststatus) --<LastUpdateUserID, int,>)

					
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
					  where PaymentID = @newpaymentid
					  
INSERT INTO [DataTrue_Main].[dbo].[PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid])
     VALUES
           (@newpaymentid
           ,@MyID
           ,@820releasefirststatus
           ,GETDATE()
           ,0)
 --select * from  datatrue_edi.dbo.InvoicePaymentsFromRetailer         
           
INSERT INTO [DataTrue_edi].[dbo].[PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid])
     VALUES
           (@newpaymentid
           ,@MyID
           ,@820releasefirststatus
           ,GETDATE()
           ,0)

update 	h set h.CheckNoReceived = p.RetailerCheckNumber, 
--h.AmountPaid = p.RetailerPaymentAmount, 
h.DatePaymentReceived = p.DateTimePaymentReceived
from [DataTrue_Main].[dbo].[PaymentHistory] h
inner join InvoiceDetailS d
on h.PaymentID = d.paymentid
and d.PaymentID = @newpaymentid
inner join datatrue_edi.dbo.InvoicePaymentsFromRetailer p
on d.RetailerInvoiceID = p.RetailerInvoiceID
				  
update 	h set h.AmountPaid = (select sum(totalCost) from invoicedetails where paymentid = @newpaymentid) 
from [DataTrue_Main].[dbo].[PaymentHistory] h
where 1 = 1
and h.PaymentID = @newpaymentid	
and h.PaymentStatus = 0	

--select top 100 * from invoicedetails where chainid = 42491

select @totalpaymentcost = SUM(TotalCost) from InvoiceDetailS where paymentid = @newpaymentid
select @totalpaymentretail = SUM(TotalRetail) from InvoiceDetailS where paymentid = @newpaymentid
select @chainname = chainname from ChainS where ChainID = @chainidpaying
select @suppliername = suppliername from Suppliers where SupplierID = @entityidtopay

declare @emailbody nvarchar(4000)=''
set @emailbody = 'A pending payment has been created from ' + @chainname + ' to ' + @suppliername + ' to pay the Retailer Cost of ' + CAST(@totalpaymentcost as nvarchar) + '.  The Retailer Retail value associated with this payment is ' + CAST(@totalpaymentretail as nvarchar) + ' and the paymentid is ' + CAST(@newpaymentid as nvarchar) + '.'

exec dbo.prSendEmailNotification_PassEmailAddresses 'New Pending Payment Created'
,@emailbody
,'DataTrue System', 0, 'mindy.yu@icontroldsd.com;Ruby.Singh@icontroldsd.com;ap@icontroldsd.com;datatrueit@icontroldsd.com'
		  
					  
					commit transaction			
					
					fetch next from @rec2 into @chainidpaying

				end

		--update r set r.InvoiceStatus = 3 
		--from InvoicesRetailer r
		--inner join InvoiceDetailS d
		--on r.RetailerInvoiceID = d.RetailerInvoiceID
		--and r.InvoiceStatus = 2
		--and d.Supplierid = @entityidtopay
		--and d.invoicedetailid in (select Invoicedetailid from #invoicedetailstopay)

	
		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec

/*
select *
from Payments
select *
from PaymentHistory

select distinct RetailerInvoiceID, paymentid
--select *
from InvoiceDetails
where paymentid is not null

select sum(TotalCost)
--select *
from InvoiceDetails
where paymentid is not null

select *
from datatrue_edi.dbo.Payments
select *
from datatrue_edi.dbo.PaymentHistory

select sum(totalcost), sum(TotalRetail)
from invoicedetails
where chainid = 42491
and cast(datetimecreated as date) = '11/13/2012'
*/
GO
