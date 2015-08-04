USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_With_Invoice_Aggregation]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_With_Invoice_Aggregation]
as

declare @MyID int=7419
declare @rec cursor 
declare @rec2 cursor
declare @entityidtopay int
declare @newpaymentid int
declare @chainidpaying int
declare @invoiceno nvarchar(50)
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @paymentamount money
declare @paymenttypeid int
declare @InvoiceDetailsTotalsMatch bit
declare @InvoiceRetailerTotalsMatch bit
declare @invoiceaggregationtypeid int
declare @invoiceaggregationid int
/*
--check totals and exit if no match
exec dbo.prBilling_Regulated_CompareInvoiceRetailerToFile @InvoiceRetailerTotalsMatch  OUTPUT
exec prBilling_Regulated_CompareInvoiceDetailsToFile @InvoiceDetailsTotalsMatch  OUTPUT

If @InvoiceRetailerTotalsMatch = 0 Or @InvoiceDetailsTotalsMatch = 0
Begin
	-- the two compare totals procedures above implement stop job and 
	-- email functions so I think all we need to do here is return
	return
	
End
*/
select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct EntityIDToInvoice from BillingControl
	where AutoReleasePaymentWhenDue = 1
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
		set @rec2 = CURSOR local fast_forward FOR
			select distinct chainid from InvoiceDetailS 
			where SupplierID = @entityidtopay 
			and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
			and PaymentID is null
			
			open @rec2
			
			fetch next from @rec2 into @chainidpaying
			
			while @@FETCH_STATUS = 0
				begin
				
begin try

					set @invoiceaggregationtypeid = 0
					
					select @invoiceaggregationtypeid = AggregationTypeID
					from datatrue_main.dbo.billingcontrol
					where EntityIDToInvoice = @entityidtopay
					and ChainID = @chainidpaying		
					
begin transaction				
					truncate table #invoicedetailstopay
					
					insert into #invoicedetailstopay
					select InvoiceDetailID from InvoiceDetailS 
					where SupplierID = @entityidtopay 
					and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
					and PaymentID is null
					and ChainID = @chainidpaying
					--and LTRIM(rtrim(InvoiceNo)) = @invoiceno

					select @paymentamount = Round(SUM(totalcost), 2)
					from InvoiceDetails 
					where InvoiceDetailID in
					(select InvoiceDetailID from #invoicedetailstopay)

					--select @paymentamount = Round(SUM(originalamount), 2)
					--from InvoicesRetailer
					--where RetailerInvoiceID in
					--(select RetailerInvoiceID from #invoicedetailstopay)
				
										
					select @paymenttypeid = case when @paymentamount < 0 then 5 else 4 end
--select * from payments  select * from invoicesretailer where chainid = 50964
					INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID]
					   ,[AmountOriginallyBilled])
					VALUES
					   (@paymenttypeid
					   ,@chainidpaying
					   ,@entityidtopay
					   ,@MyID
					   ,@paymentamount) --<LastUpdateUserID, int,>)

					
					set @newpaymentid = SCOPE_IDENTITY()
					
					update d
					set d.paymentid = @newpaymentid
					from InvoiceDetailS d
					inner join #invoicedetailstopay p
					on d.InvoiceDetailID = p.InvoiceDetailID
					
					--update Payments
					--set Payments.AmountOriginallyBilled = (select SUM(totalcost) from InvoiceDetails where PaymentID = @newpaymentid)
					--where Payments.PaymentID = @newpaymentid
					
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
						  ,ABS([AmountOriginallyBilled])
						  ,[LastUpdateUserID]
					  FROM [DataTrue_Main].[dbo].[Payments]	
					  where paymentid = @newpaymentid
					  
/*					  
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
      ,[VIN]
      ,[RawStoreIdentifier]
      ,[Route]
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
      ,[VIN]
      ,[RawStoreIdentifier]
      ,[Route]

  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
  where PaymentID = @newpaymentid						  
--select * from payments					  
*/

if @invoiceaggregationtypeid = 1 --this is a single aggregationid assigned to all the RetailerInvoiceID's on a specific payment
	begin
	
		INSERT INTO [DataTrue_EDI].[dbo].[Aggregations]
           ([AggregationTypeID]
           ,[AggregationValue])
		VALUES
           (1 --<AggregationTypeID, int,>
           ,'') --<AggregationValue, nvarchar(50),>)
	
		set @invoiceaggregationid = SCOPE_IDENTITY()
	
		update [DataTrue_EDI].[dbo].[Aggregations]
		set AggregationValue = CAST(@invoiceaggregationid as nvarchar(50))
		where AggregationID = @invoiceaggregationid
		
		update datatrue_main.dbo.InvoicesRetailer
		set AggregationID = @invoiceaggregationid
		where RetailerInvoiceID in
		(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))

		update datatrue_edi.dbo.InvoicesRetailer
		set AggregationID = @invoiceaggregationid
		where RetailerInvoiceID in
		(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))
	end


update h set h.PaymentID = d.PaymentID
from InvoicesRetailer h
inner join InvoiceDetails d
on h.RetailerInvoiceID = d.RetailerInvoiceID
where h.chainid = 50964
and cast(h.datetimecreated as date) = cast(GETDATE() as date)
and h.PaymentID is null
and d.PaymentID is not null	

update h set h.PaymentID = d.PaymentID
from datatrue_edi.dbo.InvoicesRetailer h
inner join datatrue_edi.dbo.InvoiceDetails d
on h.RetailerInvoiceID = d.RetailerInvoiceID
where h.chainid = 50964
and cast(h.datetimecreated as date) = cast(GETDATE() as date)
and h.PaymentID is null
and d.PaymentID is not null	
					  			
commit transaction	
end try
begin catch
rollback transaction
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		
end catch				
					fetch next from @rec2 into @chainidpaying

				end


	
		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec






return
GO
