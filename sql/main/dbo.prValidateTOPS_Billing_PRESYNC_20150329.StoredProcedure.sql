USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTOPS_Billing_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 9/24/2014
-- Description:	Validation for TOPS billing
-- =============================================

CREATE Procedure [dbo].[prValidateTOPS_Billing_PRESYNC_20150329]

	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Declare @rec cursor
Declare @ChainName varchar(50)
Declare @EXLQty int
Declare @INVQty Int
Declare @EDIQty2 Int
Declare @PendQty Int
Declare @StQty Int
Declare @TotalQty int


Set @Rec = CURSOR Local Fast_Forward For

Select ChainName
from DataTrue_EDI..ProcessStatus
where 1=1
and Date = CONVERT(date, GETDATE())
and BillingComplete = 0
and BillingIsRunning = 1
and AllFilesReceived = 1
--and ChainName = 'Top'
and RecordTypeID = 2

Open @Rec
Fetch From @Rec Into @ChainName

While @@FETCH_STATUS = 0

Begin



Select @INVQty =  SUM(TotalQty) 
from InvoiceDetails I with(nolock)
Inner Join (Select Min(NextBillingPeriodEndDateTime) as BillingDate, dateadd(day, +1, Min(LastBillingPeriodEndDateTime)) LastDate ,C.ChainID
			From BillingControl B Inner Join Chains C on C.ChainID = EntityIDToInvoice
			where BusinessTypeID = 1
			and convert(date,NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
			and SupplierID = 0
			and IsActive = 1
			and C.ChainIdentifier = @ChainName
			Group by C.ChainID) B
On I.ChainID = B.ChainID
where 1=1 
and InvoiceDetailTypeID = 1
--and ProcessID = (Select LastProcessID from JobRunning where JobRunningID = 14)
and I.ChainID = (Select Chainid from CHains where Chainidentifier = @ChainName)
and Saledate between LastDate and BillingDate


Select @EDIQty2 =  SUM(Qty) 
from Datatrue_edi..Inbound852Sales I with(nolock)
Inner Join Chains C on C.ChainIdentifier = I.ChainIdentifier
Inner Join (Select Min(NextBillingPeriodEndDateTime) as BillingDate, dateadd(day, +1, Min(LastBillingPeriodEndDateTime)) LastDate ,C.ChainID
			From BillingControl B Inner Join Chains C on C.ChainID = EntityIDToInvoice
			where BusinessTypeID = 1
			and convert(date,NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
			and SupplierID = 0
			and IsActive = 1
			and C.ChainIdentifier = @ChainName
			Group by C.ChainID) B
On B.ChainID = C.ChainID
where 1=1  
and C.ChainIdentifier = @ChainName
and Saledate between LastDate and BillingDate
option (optimize for (@ChainName='sv'),maxdop 0)



Select @EXLQty = SUM(qty)
				From StoreTransactions S with(nolock)
				Inner Join Chains C on C.ChainId = S.ChainID
				Inner Join (Select Min(NextBillingPeriodEndDateTime) as BillingDate, dateadd(day, +1,Min(LastBillingPeriodEndDateTime)) LastDate ,C.ChainID
							From BillingControl B Inner Join Chains C on C.ChainID = EntityIDToInvoice
							where BusinessTypeID = 1
							and convert(date,NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
							and SupplierID = 0
							and IsActive = 1
							and C.ChainIdentifier = @ChainName
							Group by C.ChainID) B
				On B.ChainID = C.ChainID
				Where C.ChainIdentifier = @ChainName
				and S.SaleDateTime between LastDate and BillingDate
				and S.TransactionStatus in (3, 813)
				and S.TransactionTypeID in (2, 6)
				
Select @PendQty = SUM(qty)
				From StoreTransactions_Working S with(nolock)
				Inner Join Chains C on C.ChainId = S.ChainID
				Inner Join (Select Min(NextBillingPeriodEndDateTime) as BillingDate, dateadd(day, +1,Min(LastBillingPeriodEndDateTime)) LastDate ,C.ChainID
							From BillingControl B Inner Join Chains C on C.ChainID = EntityIDToInvoice
							where BusinessTypeID = 1
							and convert(date,NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
							and SupplierID = 0
							and IsActive = 1
							and C.ChainIdentifier = @ChainName
							Group by C.ChainID) B
				On B.ChainID = C.ChainID
				Where C.ChainIdentifier = @ChainName
				and S.SaleDateTime between LastDate and BillingDate
				and S.WorkingStatus between -28 and -1
				and S.RecordType in (0,2)
				

		Select @TotalQty = Sum(@invqty+isnull(@exlqty, 0)+isnull(@pendqty, 0))

	
Select @StQty = SUM(Qty)
				From StoreTransactions S with(nolock)
				Inner Join Chains C on C.ChainId = S.ChainID
				Inner Join (Select Min(NextBillingPeriodEndDateTime) as BillingDate, dateadd(day, +1,Min(LastBillingPeriodEndDateTime)) LastDate ,C.ChainID
							From BillingControl B Inner Join Chains C on C.ChainID = EntityIDToInvoice
							where BusinessTypeID = 1
							and convert(date,NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
							and SupplierID = 0
							and IsActive = 1
							and C.ChainIdentifier = @ChainName
							Group by C.ChainID) B
				On B.ChainID = C.ChainID
				Where C.ChainIdentifier = @ChainName
				and S.SaleDateTime between LastDate and BillingDate
				--and S.TransactionStatus in (3, 813)
				and S.TransactionTypeID in (2, 6)
				


IF @TotalQTY <> @EDIQty2    
	
	Begin
		
		Declare @ErrorMessage as Varchar(1000)
		Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped For Chain ' + @ChainName + ' due to an exception.  Manual review, resolution, and re-start will be required for the job to continue. EDI Invoice Detail Quantity = ' + Cast(@EDIQty2 as varchar) +  ' Invoice Detail Quantity = ' + cast(@INVQty as Varchar) + ' Exclusion Qty = ' + CAST(isnull(@EXLQty, 0) as Varchar) + ' Total Pending Qty = ' + CAST(@PendQty as varchar) + ' Store Transactions Qty = ' + CAST(@StQty as varchar)
		
		Update P Set BillingIsRunning = 0
		from DataTrue_EDI..ProcessStatus P
		where 1=1
		and Date = CONVERT(date, GETDATE())
		and BillingComplete = 0
		and BillingIsRunning = 1
		and AllFilesReceived = 1
		and P.ChainName = @ChainName

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Pre-Invoicing Validation Failed'
				, @ErrorMessage
				,'DataTrue System', 0, 'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
	
	End

Fetch From @Rec Into @ChainName
	
End

Close @Rec
Deallocate @Rec

Declare @ChainsFailed int
Select @ChainsFailed =  Count(distinct ChainName) 
from DataTrue_EDI..ProcessStatus
where Date = CONVERT(date, getdate())
and BillingIsRunning = 1
and BillingComplete = 0
and AllFilesReceived = 1

If @ChainsFailed = 0

	Begin
	
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'DailyPOSBilling_NEW'
		
		Declare @ErrorMessage2 as Varchar(1000)
		Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped because all chains have failed pre-invoicing validation'
		
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Pre-Invoicing Validation Failed'
				, @ErrorMessage2
				,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com; charlie.clark@icucsolutions.com'
	
	End

END
GO
