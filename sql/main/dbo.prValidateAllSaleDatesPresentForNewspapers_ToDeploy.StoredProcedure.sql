USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAllSaleDatesPresentForNewspapers_ToDeploy]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/29/2014
-- Description:	Validates that all sale dates are present for newspaper billing
-- =============================================
CREATE PROCEDURE [dbo].[prValidateAllSaleDatesPresentForNewspapers_ToDeploy] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
Declare @BillingChains int

Select @BillingChains =  COUNT(Distinct B.ChainID) 
						--Select Distinct B.Chainid
						From BillingControl_Expanded_POS B
							inner join systementities s
							on B.EntityIDToInvoice = s.EntityId					


If @BillingChains <1

	Begin
	
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_New'
			
		exec dbo.prSendEmailNotification_PassEmailAddresses 'New Daily Billing'
		,'Billing has been stopped due to no chains to bill.'
		,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'
	
	End
	
	
If OBJECT_ID('[datatrue_main].[dbo].[GetChainsToBill]') Is Not Null Drop Table [datatrue_main].[dbo].[GetChainsToBill]
If OBJECT_ID('[datatrue_main].[dbo].[ChainsToBill]') Is Not Null Drop Table [datatrue_main].[dbo].[ChainsToBill]
If OBJECT_ID('[datatrue_main].[dbo].[ChainsMissingDates]') Is Not Null Drop Table [datatrue_main].[dbo].[ChainsMissingDates]


Select Distinct T.SaleDate, B.ChainID, B.ChainIdentifier, MIn(StartDate) min_date, Max(EndDate) max_date Into GetChainsToBill
from DataTrue_EDI..Inbound852Sales T 
inner join BillingControl_Expanded_POS B 
on B.ChainIdentifier = T.ChainIdentifier
Inner Join BillingControl C on
B.BillingControlID = C.BillingControlID
where SaleDate between StartDate and EndDate
and cast(T.StoreIdentifier as int) in (Select StoreIdentifier from Stores where ChainID = B.ChainID and StoreID = B.StoreID)
and T.SupplierID = B.SupplierID
and B.EntityTypeID In (2, 6)
and B.BusinessTypeID in (1, 4)
and C.BillingControlFrequency = 'weekly'
and CONVERT(smalldatetime, NextBillingPeriodRunDateTime) < CONVERT(smalldatetime, GETDATE())
Group by T.SaleDate, B.ChainID, B.ChainIdentifier

Select COUNT(distinct SaleDate) Saledate, ChainID, ChainIdentifier Into ChainsToBill
from GetChainsToBill
Group by ChainID, ChainIdentifier
Having COUNT(Distinct SaleDate) = 7

Create clustered index IDX_ChainID on DataTRue_Main..ChainsToBill(ChainID) With(MaxDop = 0)

;with ranges(chainid,date,lastdate)
as 
   (
    select distinct chainid,convert(smalldatetime, min_date) min_date,convert(smalldatetime, max_date) max_date
      from GetChainsToBill
    /*querying itself recursively*/
              union all 
    select chainid,date+1,lastdate
      from ranges
       where date+1 <= lastdate
    )
--insert into ChainsMissingDates(chainid,saledate)
select ranges.chainid,date missing Into ChainsMissingDates
from ranges
left join GetChainsToBill 
on ranges.chainid=GetChainsToBill.ChainID
and ranges.date=Convert(date, GetChainsToBill.SaleDate)
where GetChainsToBill.SaleDate is null    
option (maxrecursion 0)

--Select *
--from ChainsToBill

--Select *
--from ChainsMissingDates

Declare @ChainsToBill int
Select @ChainsToBill = Count(*) From ChainsToBill

If @ChainsToBill > 0

	Begin

		Insert Into DataTrue_EDI..ProcessStatus
		(ChainName
		,AllFilesReceived
		,Date
		,BillingIsRunning
		,RecordTypeID
		)
		Select C.ChainIdentifier
		,1
		,CAST(getdate() as Date)
		,1
		,2
		From ChainsToBill B Inner Join Chains C on C.ChainID = B.ChainID
		WHere C.ChainIdentifier not in (Select ChainName from DataTrue_EDI..ProcessStatus Where Date = CAST(getdate() as Date) and recordtypeid = 2)
		and B.ChainId not in (Select distinct ChainID From BillingControl Where BillingControlFrequency = 'Daily' and BusinessTypeID in (1, 4) and ChainID <> 40393 and IsActive = 1 and ChainID = EntityIDToInvoice)

	End

	Select * 
	from ChainsMissingDates
	
	If @@ROWCOUNT > 0
	
		Begin

			Declare @ChainidMissingDates table (chainid int, chainname varchar(50), Mdate varchar(50) )
			Insert Into @ChainidMissingDates (chainid, chainname, Mdate)

				Select distinct C.ChainID, C.ChainName, G.missing
				from ChainsMissingDates G 
				Inner Join CHains C On G.ChainID = C.ChainID 
				
				UPDATE @ChainidMissingDates
				SET Mdate =  Convert(date, Mdate)
				
				DECLARE @ProcessedRecords VARCHAR(MAX)
				SET @ProcessedRecords = 'SALE DATE' + CHAR(9) + CHAR(9) 
										+ 'CHAIN NAME' + CHAR(13) + CHAR(10) 
			    
				SELECT @ProcessedRecords += Mdate+ CHAR(9) + CHAR(9) 
										+chainname + CHAR(13) + CHAR(10)
				FROM @ChainidMissingDates x 

					
			DECLARE @ProcessedEmailBody VARCHAR(MAX)
			SET @ProcessedEmailBody = 'The Following chains are missing sale dates' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
																	   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +  @ProcessedRecords + CHAR(13) + CHAR(10) 
				            
							--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
			DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
			SET @Processedemailaddresses = 'josh.kiracofe@icucsolutions.com'

			EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Missing Sale Dates for Newspaper Chains'
				  ,@ProcessedEmailBody
				  ,'DataTrue System', 0, @Processedemailaddresses
		End


END
GO
