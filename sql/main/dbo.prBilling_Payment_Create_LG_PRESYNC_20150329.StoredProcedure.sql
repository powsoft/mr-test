USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_Create_LG_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_Create_LG_PRESYNC_20150329]
as

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
declare @pendingpaymentamount money
declare @minimumpaymentamount money=20
DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct Supplierid
	from InvoicesRetailer r
	inner join InvoiceDetailS d
	on r.RetailerInvoiceID = d.RetailerInvoiceID
	and r.ChainID=d.ChainID
	and r.ChainID in (select Distinct EntityIDtoInclude 
						from ProcessStepEntities E inner join 
						BillingControl C on E.EntityIDToInclude = C.ChainID
						where ProcessStepName in ('prBilling_Payment_Create_Newspaper',
													'prBilling_Payment_Create_Newspaper_PDI')
						and E.IsActive = 1)
	and SaleDate >= '11/18/2013'
	and d.RetailerInvoiceID is not null
	and d.RetailerInvoiceID <> -1
	and d.SupplierInvoiceID is not null
	and d.SupplierInvoiceID <> -1
	and d.SupplierID <> 0
	and d.PaymentID is null
	--and r.ChainID not in (62362, 74628)
	--and d.ProcessID = @ProcessID
	
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
			and s.ChainID in (select EntityIDtoInclude 
					from ProcessStepEntities 
					where ProcessStepName in ('prBilling_Payment_Create_Newspaper',
												'prBilling_Payment_Create_Newspaper_PDI'))
			and d.PaymentID is null
			and d.RetailerInvoiceID is not null
			and d.RetailerInvoiceID <> -1
			and d.SupplierInvoiceID is not null
			and d.SupplierInvoiceID <> -1
			and d.SupplierID <> 0
			and SaleDate >= '11/18/2013'
			--and d.ChainID not in (62362, 74628)
			--and d.ProcessID = @ProcessID			
			open @rec2
			
			fetch next from @rec2 into @chainidpaying
			
			while @@FETCH_STATUS = 0
				begin
				
					select @820releasefirststatus = c.Payment820ReleaseFirstStatus
					--select *
					from dbo.PaymentDisbursementReleaseControl c
					where PaymentDisbursementPayerEntityID = @chainidpaying
					
					set @820releasefirststatus = 3
					
					truncate table #invoicedetailstopay
					
					begin transaction
					
					set @pendingpaymentamount = 0
					
					select @pendingpaymentamount = SUM(TotalQty * UnitCost)
					from InvoiceDetailS d
					inner join InvoicesRetailer s
					on d.RetailerInvoiceID = s.RetailerInvoiceID
					and d.SupplierID = @entityidtopay
					and d.RetailerInvoiceID is not null
					and d.RetailerInvoiceID <> -1
					and d.SupplierInvoiceID is not null
					and d.SupplierInvoiceID <> -1
					and d.SupplierID <> 0
					and d.paymentid is null 
					and s.ChainID = @chainidpaying
					and SaleDate >= '11/18/2013'
					--and d.ChainID not in (62362, 74628)
					--and d.ProcessID = @ProcessID
					
					if @pendingpaymentamount is null
						begin
							set @pendingpaymentamount = 0	
						end		
if @pendingpaymentamount >= @minimumpaymentamount	
	begin				
					insert into #invoicedetailstopay
					select InvoiceDetailID 
					from InvoiceDetailS d
					inner join InvoicesRetailer s
					on d.RetailerInvoiceID = s.RetailerInvoiceID
					and d.SupplierID = @entityidtopay
					and d.RetailerInvoiceID is not null
					and d.RetailerInvoiceID <> -1
					and d.SupplierInvoiceID is not null
					and d.SupplierInvoiceID <> -1
					and d.SupplierID <> 0
					and d.paymentid is null 
					and s.ChainID = @chainidpaying
					and SaleDate >= '11/18/2013'
					--and d.ChainID not in (62362, 74628)
					--and d.ProcessID = @ProcessID
					
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
					--where d.ProcessID = @ProcessID
					
					update Payments
					set Payments.AmountOriginallyBilled = (select SUM(TotalQty * UnitCost) from InvoiceDetails where PaymentID = @newpaymentid)
					where Payments.PaymentID = @newpaymentid
					
					update ed set ed.paymentid = md.PaymentID
					from datatrue_edi.dbo.InvoiceDetails ed
					inner join datatrue_main.dbo.InvoiceDetails md
					on ed.InvoiceDetailID = md.InvoiceDetailID
					inner join #invoicedetailstopay t
					on md.InvoiceDetailID = t.InvoiceDetailID
					--and ed.ProcessID = @ProcessID
					
update 	h set h.CheckNoReceived = p.RetailerCheckNumber, 
h.DatePaymentReceived = p.DateTimePaymentReceived
from [DataTrue_Main].[dbo].[PaymentHistory] h
inner join InvoiceDetailS d
on h.PaymentID = d.paymentid
and d.PaymentID = @newpaymentid
inner join datatrue_edi.dbo.InvoicePaymentsFromRetailer p
on d.RetailerInvoiceID = p.RetailerInvoiceID
--and d.ProcessID = @ProcessID
				  
update 	h set h.AmountPaid = (select sum(TotalQty * UnitCost) from invoicedetails where paymentid = @newpaymentid) 
from [DataTrue_Main].[dbo].[PaymentHistory] h
where 1 = 1
and h.PaymentID = @newpaymentid	
and h.PaymentStatus = 0	

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


end		  
					  
					commit transaction			
					
					fetch next from @rec2 into @chainidpaying

				end

		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec
GO
