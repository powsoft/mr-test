USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Billing_Payment_AutoRelease_CreatePennyTest_ACH_ByChain]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_Billing_Payment_AutoRelease_CreatePennyTest_ACH_ByChain]
@chainid int,
@supplierid int,
@amount money

as

--declare @chainid int
--declare @supplierid int
--declare @supplierid int = 62413 declare @chainid int = 50964 declare @amount money = .01
declare @MyID int = 7419
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
declare @invoicedetailid int
declare @retailerinvoiceid int


INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetails]
           ([ChainID]
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
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[InventorySettlementID]
           ,[SBTNumber]
           ,[FinalInvoiceUnitCost]
           ,[FinalInvoiceUnitPromo]
           ,[FinalInvoiceTotalCost]
           ,[FinalInvoiceQty]
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
           ,[SourceID])
     SELECT top 1 @chainid --[ChainID] 
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,@SupplierID --[SupplierID] 
      ,[InvoiceDetailTypeID]
      ,1 --[TotalQty]
      ,@amount --[UnitCost] 
      ,[UnitRetail]
      ,@amount --[TotalCost] 
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
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[InventorySettlementID]
      ,[SBTNumber]
      ,[FinalInvoiceUnitCost]
      ,[FinalInvoiceUnitPromo]
      ,[FinalInvoiceTotalCost]
      ,[FinalInvoiceQty]
      ,[OriginalShrinkTotalQty]
      ,[PaymentDueDate]
      ,null --[PaymentID]
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
      ,[SourceID]
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
where TotalCost = .01
and ChainID = 50964

set @invoicedetailid = SCOPE_IDENTITY()

INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
           ([ChainID]
           ,[InvoiceDate]
           ,[InvoicePeriodStart]
           ,[InvoicePeriodEnd]
           ,[OriginalAmount]
           ,[InvoiceTypeID]
           ,[OpenAmount]
           ,[LastUpdateUserID]
           ,[PaymentDueDate])
     VALUES
           (@chainid --<ChainID, int,>
           ,GETDATE() --<InvoiceDate, datetime,>
           ,DateAdd(DAY, -1, GETDATE()) --<InvoicePeriodStart, datetime,>
           ,DateAdd(DAY, -1, GETDATE()) --<InvoicePeriodEnd, datetime,>
           ,@amount --<OriginalAmount, money,>
           ,0 --<InvoiceTypeID, int,>
           ,@amount --<OpenAmount, money,>
           ,0 --<LastUpdateUserID, int,>
           ,DATEADD(day, -1, getdate())) --<PaymentDueDate, datetime,>

set @retailerinvoiceid = SCOPE_IDENTITY()

update InvoiceDetailS
set RetailerInvoiceID = @retailerinvoiceid
where InvoiceDetailID = @invoicedetailid

/*
--declare @supplierid int = 62413 declare @chainid int = 50964 declare @amount money = .01
declare @MyID int = 7419
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
declare @invoicedetailid int
declare @retailerinvoiceid int

*/	

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select @supplierid
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
		set @rec2 = CURSOR local fast_forward FOR
			select @chainid
			
			open @rec2
			
			fetch next from @rec2 into @chainidpaying
			
			while @@FETCH_STATUS = 0
				begin
				
begin try
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

update invoicedetails set paymentid = null where invoicedetailid = 57583289				  
*/

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
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		
end catch				
					fetch next from @rec2 into @chainidpaying

				end


	
		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec






return
GO
