USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateQuantites_ToDeploy]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 02/03/2015
-- Description:	Validates quantities for chains being billed
-- =============================================

CREATE Procedure [dbo].[prValidateQuantites_ToDeploy]

	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Select Distinct Sourceid, 
SourceName, 
CAST(0 as int) TotalPendingQty,
CAST(0 as int) InboundQty,
CAST(0 as int) NPPendQty,
CAST(0 as int) SBTPendQty,
CAST(0 as int) InvoiceQty,
CAST(0 as int) StoreTransQty,
CAST(0 as int) ExcludedQty,
CAST(0 as int) DupeQty, 
CAST(0 as Int) Chainid
Into #TempSource 
From Source
Where DateTimeCreated >= '2015-05-01'
and SourceTypeID = 1
 


Update S Set S.StoreTransQty = B.StoreTransQty, S.Chainid = B.ChainID
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty, ChainID
From StoreTransactions with(nolock)
where DateTimeCreated >= '2015-05-01'
and TransactionTypeID in (2, 6)
Group by SourceID, ChainID) B
On B.SourceID = S.SourceID
and S.StoreTransQty = 0

Delete
from #TempSource
where StoreTransQty = 0

Update S Set S.InboundQty = B.InboundQty
--Select *
From #TempSource S
Inner Join 
(Select FileName, SUM(qty) InboundQty
From DataTrue_EDI..Inbound852Sales with(nolock)
Group by FileName) B
On B.FileName = S.SourceName
and S.InboundQty = 0


Update S Set S.TotalPendingQty = B.StoreTransQty
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty
From StoreTransactions_Working with(nolock)
where 1=1
and WorkingSource = 'POS'
and WorkingStatus not in (5, -28)
Group by SourceID) B
On B.SourceID = S.SourceID

Update S Set S.NPPendQty = B.StoreTransQty
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty
From StoreTransactions_Working with(nolock)
where 1=1
and WorkingSource = 'POS'
and WorkingStatus not in (5, -28)
and RecordType = 2
Group by SourceID) B
On B.SourceID = S.SourceID

Update S Set S.SBTPendQty = B.StoreTransQty
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty
From StoreTransactions_Working with(nolock)
where 1=1
and WorkingSource = 'POS'
and WorkingStatus not in (5, -28)
and RecordType = 0
Group by SourceID) B
On B.SourceID = S.SourceID

Update S Set S.ExcludedQty = Isnull(B.StoreTransQty, 0)
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty
From StoreTransactions with(nolock)
where DateTimeCreated >= '2015-05-01'
and TransactionTypeID in (2, 6)
and TransactionStatus in (3, 813)
Group by SourceID) B
On B.SourceID = S.SourceID

Update S Set S.DupeQty = B.StoreTransQty
--Select B.*
From #TempSource S
Inner Join 
(Select Sourceid, SUM(qty) StoreTransQty
From StoreTransactions_Working with(nolock)
where 1=1
and WorkingSource = 'POS'
and WorkingStatus in (-6)
Group by SourceID) B
On B.SourceID = S.SourceID

Update S Set 
S.SourceEntityID = T.Chainid
from #TempSource T
Inner Join Source S
on S.SourceID = T.SourceID
and S.SourceEntityID is null

Update S Set
S.InboundQty = T.InboundQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.InboundQty <> T.InboundQty

Update S Set
S.TotalPendingQty = T.TotalPendingQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.TotalPendingQty <> T.TotalPendingQty

Update S Set
S.SBTPendQty = T.SBTPendQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.SBTPendQty <> T.SBTPendQty

Update S Set
S.NPPendQty = T.NPPendQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.NPPendQty <> T.NPPendQty

Update S Set
S.ExcludedQty = T.ExcludedQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.ExcludedQty <> T.ExcludedQty

Update S Set
S.StoreTransQty = T.StoreTransQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.StoreTransQty <> T.StoreTransQty

Update S Set
S.DupeQty = T.DupeQty
From #TempSource T
Inner Join Source S
on S.SourceEntityID = T.Chainid
and S.SourceID = T.SourceID
Where S.DupeQty <> T.DupeQty

Declare @BillingChain int

Select @BillingChain = Count(C.ChainID)
from DataTrue_EDI..ProcessStatus P
Inner Join Chains C on 
C.ChainIdentifier = P.ChainName
where 1=1
and Date = CONVERT(date, GETDATE())
and BillingComplete = 0
and BillingIsRunning = 1
and AllFilesReceived = 1
and RecordTypeID = 2

If @BillingChain > 0

	Begin
	

	Declare @Rec Cursor
	Declare @CHainid int
	Declare @TotalQty int
	Declare @InvQty int
	Declare @StQty int
	Declare @PendQty int
	Declare @InboundQty int
	Declare @ExlQty int
	Declare @GenSup int
	
	Set @Rec = CURSOR Local Fast_Forward For

	Select C.ChainID
	from DataTrue_EDI..ProcessStatus P
	Inner Join Chains C on 
	C.ChainIdentifier = P.ChainName
	where 1=1
	and Date = CONVERT(date, GETDATE())
	and BillingComplete = 0
	and BillingIsRunning = 1
	and AllFilesReceived = 1
	and RecordTypeID = 2

	Open @Rec
	Fetch From @Rec Into @ChainID

	While @@FETCH_STATUS = 0

	Begin

		Declare @MinDate Date = (Select Min(StartDate) from BillingControl_Expanded_POS where ChainId = @CHainid and EntityTypeID in (2, 6))
		Declare @MaxDate Date = (Select MAX(StartDate) from BillingControl_Expanded_POS where ChainId = @CHainid and EntityTypeID in (2, 6))

		Update S Set InvoiceDetQty = CONVERT(int, TotalQty)
		From
			(Select SUM(TotalQty) TotalQty, I.SourceID
			from InvoiceDetails I With(nolock)
				Inner Join #TempSource T 
					on T.SourceID = I.SourceID
				Inner Join Chains C
					On C.ChainID = I.ChainID
				Inner Join DataTrue_EDI..ProcessStatus P
					On P.ChainName = C.ChainIdentifier 
			Where 1=1
				and I.DateTimeCreated >= '2015-05-01'
				and InvoiceDetailTypeID in (1, 16)
				and cast(I.DateTimeLastUpdate as date) = CONVERT(date, getdate())
				and Date = CONVERT(date, getdate())
				and BillingIsRunning = 1
				and RecordTypeID = 2
				and BillingComplete = 0
				and I.ChainID = @CHainid
			Group by I.SourceID) B
		Inner Join Source S 
		on S.SourceID = B.SourceID
		
		Select distinct SourceID into #TempSourceID
		from InvoiceDetails I With(nolock)
		Where 1=1
		and InvoiceDetailTypeID in (1)
		and cast(I.DateTimeCreated as date) = CONVERT(date, getdate())
		and ChainID = @CHainid

		Select @InboundQty = SUM(Inboundqty) 
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		Select @GenSup = SUM(Qty)
		from StoreTransactions with(nolock)
		where ChainID = @CHainid
		and TransactionTypeID in (2, 6)
		and TransactionStatus in (0,2)
		and CONVERT(Date, Saledatetime) between @MinDate and @MaxDate
		
		Select @TotalQty = SUM(TotalPendingQty+ExcludedQty+InvoiceDetQty+ISNULL(@GenSup, 0))
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		Select @InvQty = SUM(InvoiceDetQty)
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		Select @PendQty = SUM(TotalPendingQty)
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		Select @ExlQty = SUM(ExcludedQty)
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		Select @StQty = SUM(StoreTransQty)
		from Source S Inner Join
		#TempSourceID I on I.SourceID = S.SourceID
		where 1=1
		and SourceEntityID =@CHainid
		
		If @TotalQty <> @InboundQty
		
			Begin 
			
				Declare @ErrorMessage as Varchar(1000)
				Declare @ChainName as Varchar(50) = (Select ChainIdentifier From Chains Where ChainID = @CHainid)
				
				Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped For Chain ' + @ChainName + ' due to an exception.  Manual review, resolution, and re-start will be required for the job to continue. EDI Inbound Quantity = ' + Cast(@InboundQty as varchar) +  ' Invoice Detail Quantity = ' + cast(@INVQty as Varchar) + ' Exclusion Qty = ' + CAST(isnull(@EXLQty, 0) as Varchar) + ' Total Pending Qty = ' + CAST(IsnUll(@PendQty, 0) as varchar) + ' Store Transactions Qty = ' + CAST(@StQty as varchar)
				
				Update P Set BillingIsRunning = 0
				from DataTrue_EDI..ProcessStatus P
				Inner Join Chains C on 
				C.ChainIdentifier = P.ChainName
				where 1=1
				and Date = CONVERT(date, GETDATE())
				and BillingComplete = 0
				and BillingIsRunning = 1
				and AllFilesReceived = 1
				and RecordTypeID = 2

				exec dbo.prSendEmailNotification_PassEmailAddresses 'Pre-Invoicing Validation Failed'
						, @ErrorMessage
						,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com'--'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
			
			End

		Fetch From @Rec Into @ChainID
	
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
			Set @ErrorMessage2 = 'Retailer and supplier invoicing has been stopped because all chains have failed pre-invoicing validation'
			
			
			exec dbo.prSendEmailNotification_PassEmailAddresses 'Pre-Invoicing Validation Failed'
					, @ErrorMessage2
					,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com; charlie.clark@icucsolutions.com'
		
		End

End
END
GO
