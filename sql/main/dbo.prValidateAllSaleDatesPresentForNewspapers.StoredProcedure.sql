USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAllSaleDatesPresentForNewspapers]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/29/2014
-- Description:	Validates that all sale dates are present for newspaper billing
-- =============================================
CREATE PROCEDURE [dbo].[prValidateAllSaleDatesPresentForNewspapers] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
Declare @BillingChains int

Select @BillingChains =  COUNT(*) From BillingControl B
							inner join systementities s
							on B.EntityIDToInvoice = s.EntityID
						where CONVERT(Date,NextBillingPeriodRunDateTime) <= convert(smalldatetime, GETDATE())
						and BusinessTypeID = 1
						and IsActive = 1
						and s.EntityTypeID = 2
						and B.ChainID not in (select Distinct EntityIDToInclude
												from dbo.ProcessStepEntities 
												where ProcessStepName In ('prGetInboundPOSTransactions_BAS', 'prGetInboundPOSTransactions'))

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


Select Distinct T.SaleDate, C.ChainID, C.ChainIdentifier, dateadd(day, +1, LastBillingPeriodEndDateTime) min_date, NextBillingPeriodEndDateTime max_date Into GetChainsToBill
from DataTrue_EDI..TotalPOSSalesPerChain T 
inner join Chains C on C.ChainIdentifier = T.PartnerName
inner join BillingControl B on B.ChainID = C.ChainID
inner join systementities s
on B.EntityIDToInvoice = s.EntityID
where SaleDate between dateadd(day, +1, LastBillingPeriodEndDateTime) and NextBillingPeriodEndDateTime
and NextBillingPeriodRunDateTime <= convert(smalldatetime, GETDATE())
and IsActive = 1
and s.EntityTypeID = 2
and B.BillingControlFrequency = 'weekly'
and B.BusinessTypeID = 1

Select COUNT(distinct SaleDate) Saledate, ChainID, ChainIdentifier Into ChainsToBill
from GetChainsToBill
Group by ChainID, ChainIdentifier
Having COUNT(Distinct Saledate) = 7

Create clustered index IDX_ChainID on DataTRue_Main..ChainsToBill(ChainID) With(MaxDop = 0)

;with ranges(chainid,date,lastdate)
as 
   (
    select distinct chainid,min_date,max_date
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
and ranges.date=GetChainsToBill.SaleDate
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
		Select ChainIdentifier
		,1
		,CAST(getdate() as Date)
		,1
		,2
		From ChainsToBill
		WHere ChainIdentifier not in (Select ChainName from DataTrue_EDI..ProcessStatus Where Date = CAST(getdate() as Date) and recordtypeid = 2)
		--and ChainID <> 42490

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
			SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com; amol.sayal@icucsolutions.com; Bill.Harris@icucsolutions.com; ademola.akinola@icucsolutions.com'

			EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Missing Sale Dates for Newspaper Chains'
				  ,@ProcessedEmailBody
				  ,'DataTrue System', 0, @Processedemailaddresses
		End
	--Else
	--	Begin
	--		DECLARE @ProcessedEmailBody2 VARCHAR(MAX)
	--		SET @ProcessedEmailBody2 = 'No Chains Missing Sale Dates.'
				            
	--						--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
	--		DECLARE @Processedemailaddresses2 VARCHAR(MAX) = ''
	--		SET @Processedemailaddresses2 = 'DATATRUEIT@icucsolutions.com; gilad.keren@icucsolutions.com; amol.sayal@icucsolutions.com; Bill.Harris@icucsolutions.com; ademola.akinola@icucsolutions.com'

	--		EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Missing Sale Dates for Newspaper Chains'
	--			  ,@ProcessedEmailBody2
	--			  ,'DataTrue System', 0, @Processedemailaddresses2
	--	End

END
GO
