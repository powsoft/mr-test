USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_Separate_FuelStores_WithAggregation_Custom4Test]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_Separate_FuelStores_WithAggregation_Custom4Test]
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
declare @invoiceaggregationtypeid int --
declare @invoiceaggregationid int --
declare @accounttypeid int
declare @custom4 varchar(200)

DECLARE @ProcessID INT
SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @jobLastRan DATETIME
SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')


--INSERT INTO DataTrue_EDI.dbo.RetailerPaymentAccountTypes for missing account type 1s
DELETE FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes WHERE TypeID = 1
INSERT INTO DataTrue_EDI.dbo.RetailerPaymentAccountTypes (ChainID, TypeID, TypeDescription, Custom4)
SELECT DISTINCT t.ChainID, 1, 'Default account type', ISNULL(s.Custom4, '')
FROM BillingControl AS t WITH (NOLOCK)
LEFT OUTER JOIN Stores AS s WITH (NOLOCK)
ON t.ChainID = s.ChainID
WHERE 1 = 1
AND t.ChainID > 0
AND t.ISACH = 1
AND t.IsActive = 1
AND t.BillingControlFrequency = 'Daily'
AND CONVERT(VARCHAR(10),t.ChainID) + ISNULL(Custom4, '') NOT IN (SELECT DISTINCT CONVERT(VARCHAR(10),t2.ChainID) + ISNULL(Custom4, '') FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes t2)

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct EntityIDToInvoice from BillingControl
	where AutoReleasePaymentWhenDue = 1
	AND ISACH = 1
	AND IsActive = 1
	AND EntityIDToInvoice = SupplierID
	AND BillingControlFrequency = 'Daily'
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
			SET @rec2 = CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT a.ChainID, t.TypeID, CASE WHEN t.TypeID = 1 THEN '' ELSE t.Custom4 END
			FROM InvoiceDetails AS a WITH (NOLOCK)
			INNER JOIN Stores AS s WITH (NOLOCK)
			ON a.StoreID = s.StoreID
			INNER JOIN DataTrue_EDI.dbo.RetailerPaymentAccountTypes AS t WITH (NOLOCK)
			ON ISNULL(s.Custom4, '') = t.Custom4
			WHERE 1 = 1
			AND a.ProcessID = @ProcessID
			AND a.InvoiceDetailTypeID = 2
			AND CAST(PaymentDueDate AS DATE) <= CAST(GETDATE() AS DATE)
			AND PaymentID IS NULL

			open @rec2

			fetch next from @rec2 into @chainidpaying, @accounttypeid, @custom4

			
			while @@FETCH_STATUS = 0
				begin
				
begin try
--added by charlie 20130910
					set @invoiceaggregationtypeid = 0
					
					select @invoiceaggregationtypeid = AggregationTypeID
					from datatrue_main.dbo.billingcontrol nolock
					where EntityIDToInvoice = @entityidtopay
					and ChainID = @chainidpaying
					and BillingControlFrequency = 'Daily'
--added by charlie 20130910
begin transaction				
					truncate table #invoicedetailstopay
					
					IF @accounttypeid > 1  
						BEGIN
						
						insert into #invoicedetailstopay
						select InvoiceDetailID 
						from InvoiceDetails as ivd with (nolock)
						where ivd.ChainID = @chainidpaying
						and SupplierID = @entityidtopay 
						and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
						and PaymentID is null			
						and ivd.StoreID in
							(
								select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') = @custom4
							) 
						and RecordType not in (3)
						and ProcessID = @ProcessID
						
						END
						
					ELSE IF @accounttypeid = 1
						BEGIN
						
							insert into #invoicedetailstopay
							select InvoiceDetailID 
							from InvoiceDetails as ivd with (nolock)
							where ivd.ChainID = @chainidpaying
							and SupplierID = @entityidtopay 
							and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
							and PaymentID is null			
							and ivd.StoreID in
								(
									select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') <> (SELECT Custom4 FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes WHERE ChainID = @chainidpaying AND TypeID <> 1)
								) 
							and RecordType not in (3)
							and ProcessID = @ProcessID
							
							IF @@ROWCOUNT = 0 --RETAILER DOES NOT HAVE ANY CUSTOM 4'S THAT ARE NOT DEFAULT BANK ACCNT
								BEGIN
									insert into #invoicedetailstopay
									select InvoiceDetailID 
									from InvoiceDetails as ivd with (nolock)
									where ivd.ChainID = @chainidpaying
									and SupplierID = @entityidtopay 
									and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
									and PaymentID is null			
									and ivd.StoreID in
										(
											select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') = @custom4
										) 
									and RecordType not in (3)
									and ProcessID = @ProcessID
								END
							
						END
						
					
					
					
If @@ROWCOUNT > 0
	begin
					select @paymentamount = Round(SUM(totalcost), 2)
					from InvoiceDetails as ivd with (nolock)
					where InvoiceDetailID in
					(select InvoiceDetailID from #invoicedetailstopay)
										
					select @paymenttypeid = case when @paymentamount < 0 then 5 else 4 end

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
							   ,[ACHAccountTypeID])
					SELECT [PaymentID]
						  ,[PaymentTypeID]
						  ,[PayerEntityID]
						  ,[PayeeEntityID]
						  ,ABS([AmountOriginallyBilled])
						  ,[LastUpdateUserID]
						  ,@accounttypeid
					  FROM [DataTrue_Main].[dbo].[Payments]	nolock
					  where paymentid = @newpaymentid
					  
--added by charlie 20130910
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
where d.ProcessID = @ProcessID
and cast(h.datetimecreated as date) >= cast(GETDATE() as date)
and h.PaymentID is null
and d.PaymentID is not null	

end	

--INSERT INTO DataTrue_Report.dbo.payments
--(
--[PaymentID]
--,[PaymentTypeID]
--,[PayerEntityID]
--,[PayeeEntityID]
--,[AmountOriginallyBilled]
--,[PaymentStatus]
--,[DateTimePaid]
--,[DateTimeCreated]
--,[LastUpdateUserID]
--,[DateTimeLastUpdate]
--,[Comments]
--,[ACHAccountTypeID]
--)
--SELECT
--[PaymentID]
--,[PaymentTypeID]
--,[PayerEntityID]
--,[PayeeEntityID]
--,[AmountOriginallyBilled]
--,[PaymentStatus]
--,[DateTimePaid]
--,[DateTimeCreated]
--,[LastUpdateUserID]
--,[DateTimeLastUpdate]
--,[Comments]
--,[ACHAccountTypeID]
--FROM DataTrue_Main.dbo.Payments nolock
--WHERE PaymentTypeID IN (4,5)
--AND PaymentID NOT IN (SELECT PaymentID FROM DataTrue_Report.dbo.Payments nolock)	
					  			
commit transaction	
end try
begin catch
rollback transaction
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		IF EXISTS(     
			select 1 
			from msdb.dbo.sysjobs_view job  
			inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
			where  
				activity.run_Requested_date is not null  
			and activity.stop_execution_date is null  
			and job.name = 'Billing_Regulated' 
		) 
		Begin
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
		End
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		
end catch				
					fetch next from @rec2 into @chainidpaying, @accounttypeid, @custom4

				end


	
		fetch next from @rec into @entityidtopay
	
	end
	
close @rec
deallocate @rec






return
GO
