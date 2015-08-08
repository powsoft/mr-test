USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_SupplierFees_Create]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_SupplierFees_Create]
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

*/
declare @MyID int=7419
declare @rec cursor 
declare @rec2 cursor
declare @entityidtopay int
declare @newpaymentid int
declare @supplieridpaying int
declare @totalpaymentcost money
declare @totalpaymentretail money
declare @chainname nvarchar(50)
declare @suppliername nvarchar(50)
declare @820releasefirststatus smallint

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct supplierid
	--select *
	from InvoiceDetailS d
	where InvoiceDetailTypeID = 15
	and PaymentID is null
	
open @rec

fetch next from @rec into @supplieridpaying

while @@FETCH_STATUS = 0
	begin
	

					truncate table #invoicedetailstopay
					
					begin transaction
					
					insert into #invoicedetailstopay
					select InvoiceDetailID 
					from InvoiceDetailS d
					where d.paymentid is null 
					and InvoiceDetailTypeID = 15
					and SupplierID = @supplieridpaying

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
					
					--select * from paymenttypes
					--select * from payments

					INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID]
					   ,[PaymentStatus])
					VALUES
					   (7
					   ,@supplieridpaying
					   ,53479 --iControl @entityidtopay
					   ,@MyID
					   ,0) --@820releasefirststatus) --<LastUpdateUserID, int,>)

					
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
							   ,[LastUpdateUserID]
							   ,[PaymentStatus])
					SELECT [PaymentID]
						  ,[PaymentTypeID]
						  ,[PayeeEntityID]
						  ,[PayerEntityID]
						  ,[AmountOriginallyBilled]
						  ,[LastUpdateUserID]
						  ,[PaymentStatus]
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
           ,0 --@820releasefirststatus
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
           ,0 --@820releasefirststatus
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

					  
INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
           ([InvoiceDetailID]
           ,[RetailerInvoiceID]
           ,[SupplierInvoiceID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[UnitCost]
           ,[UnitRetail]
           ,[TotalCost]
           ,[TotalRetail]
           ,[SaleDate]
           ,[RecordStatus]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[BatchID]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ProductIdentifier]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[BrandIdentifier]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[Allowance]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,PromoTypeID
			,PromoAllowance
			,SBTNumber
      ,[FinalInvoiceTotalCost]
      ,[OriginalShrinkTotalQty]
      ,[PaymentDueDate]
      ,[PaymentID]
      ,[Adjustment1]
      ,[Adjustment2]
      ,[Adjustment3]
      ,[Adjustment4]
      ,[Adjustment5]
      ,[Adjustment6]
      ,[Adjustment7]
      ,[Adjustment8]
      ,[PDIParticipant]
      ,[RetailUOM]
      ,[RetailTotalQty]
)
SELECT [InvoiceDetailID]
      ,[RetailerInvoiceID]
      ,[SupplierInvoiceID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[InvoiceDetailTypeID]
      ,[TotalQty]
      ,[UnitCost]
      ,[UnitRetail]
      ,[TotalCost]
      ,[TotalRetail]
      ,[SaleDate]
      --change here wait
      ,0 --case when upper(banner) = 'SS' then 2 else 0 end
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BatchID]
                 ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ProductIdentifier]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[BrandIdentifier]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[Allowance]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,PromoTypeID
			,isnull(PromoAllowance, 0)
			,SBTNumber
      ,[FinalInvoiceTotalCost]
      ,[OriginalShrinkTotalQty]
      ,[PaymentDueDate]
      ,[PaymentID]
      ,[Adjustment1]
      ,[Adjustment2]
      ,[Adjustment3]
      ,[Adjustment4]
      ,[Adjustment5]
      ,[Adjustment6]
      ,[Adjustment7]
      ,[Adjustment8]
      ,[PDIParticipant]
      ,[RetailUOM]
      ,[RetailTotalQty]

  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
  where PaymentID = @newpaymentid						  
--select * from payments					  
			  
					  
	insert into DataTrue_EDI..InvoicesRetailer 
select * from DataTrue_Main..InvoicesRetailer
where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer)

insert into DataTrue_EDI..InvoicesSupplier 
select * from DataTrue_Main..InvoicesSupplier
where Supplierinvoiceid not in (select Supplierinvoiceid from DataTrue_EDI..InvoicesSupplier)				

		update r set r.InvoiceStatus = 3 
		from InvoicesSupplier r
		inner join InvoiceDetailS d
		on r.SupplierInvoiceID = d.SupplierInvoiceID
		--and r.InvoiceStatus = 2
		and d.supplierid = @supplieridpaying
		and d.InvoiceDetailTypeID = 15
		and r.InvoiceStatus <> 3

					commit transaction			
	
		fetch next from @rec into @supplieridpaying
	
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
