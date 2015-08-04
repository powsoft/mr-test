USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateQuantities]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prValidateQuantities]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare @rec cursor
Declare @ChainName varchar(50)
Declare @EXLQty int
Declare @INVQty Int
Declare @EDIQty2 Int


Set @Rec = CURSOR Local Fast_Forward For

Select ChainName
from DataTrue_EDI..ProcessStatus
where 1=1
and Date = CONVERT(date, GETDATE())
and BillingComplete = 0
and BillingIsRunning = 1
and AllFilesReceived = 1
and ChainName = 'Top'

Open @Rec
Fetch From @Rec Into @ChainName

While @@FETCH_STATUS = 0

Begin


Select @INVQty = 90 /*SUM(TotalQty) 
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
and Saledate between LastDate and BillingDate*/


Select @EDIQty2 = 91 /*SUM(Qty) 
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
option (optimize for (@ChainName='sv'),maxdop 0)*/



Select @EXLQty = Null/*SUM(qty)
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
				and S.SaleDateTime between LastDate and BillingDate*/

--Select @EDIQty2, Sum(@INVQty + Isnull(@EXLQty,0)),  @ChainName


IF Sum(@INVQty+Isnull(@EXLQty,0)) <> @EDIQty2  
	
	Begin
		
		Select @EDIQty2, Sum(@INVQty + Isnull(@EXLQty,0)),  @ChainName
		--Declare @ErrorMessage as Varchar(1000)
		--Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped For Chain ' + @ChainName + ' due to an exception.  Manual review, resolution, and re-start will be required for the job to continue. EDI Invoice Detail Quantity = ' + Cast(@EDIQty2 as varchar) +  ' Invoice Detail Quantity = ' + cast(@INVQty as Varchar) 
		
		--Update P Set BillingIsRunning = 0
		--from DataTrue_EDI..ProcessStatus P
		--where 1=1
		--and Date = CONVERT(date, GETDATE())
		--and BillingComplete = 0
		--and BillingIsRunning = 1
		--and AllFilesReceived = 1
		--and P.ChainName = @ChainName

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Pre-Invoicing Validation Failed From Test'
		--		, @ErrorMessage
		--		,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com; charlie.clark@icucsolutions.com'--'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
	
	End

Fetch From @Rec Into @ChainName
	
End

Close @Rec
Deallocate @Rec

--Declare @ChainsFailed int
--Select @ChainsFailed =  Count(distinct ChainName) 
--from DataTrue_EDI..ProcessStatus
--where Date = CONVERT(date, getdate())
--and BillingIsRunning = 0
--and BillingComplete = 0
--and AllFilesReceived = 1

--If @ChainsFailed > 0

--	Begin
	
--		exec [msdb].[dbo].[sp_stop_job] 
--		@job_name = 'DailyPOSBilling_NEW'
END
GO
