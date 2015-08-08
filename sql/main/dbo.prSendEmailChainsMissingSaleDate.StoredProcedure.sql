USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailChainsMissingSaleDate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 11/21/2014
-- Description:	This is to send an email whenever a chain is missing a sale date
-- =============================================
CREATE PROCEDURE [dbo].[prSendEmailChainsMissingSaleDate] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
If OBJECT_ID('[datatrue_main].[dbo].[GetChainsSaleDate]') Is Not Null Drop Table [datatrue_main].[dbo].[GetChainsSaleDate]
If OBJECT_ID('[datatrue_main].[dbo].[ChainsWithMissingDates]') Is Not Null Drop Table [datatrue_main].[dbo].[ChainsWithMissingDates]

Select Distinct T.SaleDateTime, T.ChainID, dateadd(day, +1, LastBillingPeriodEndDateTime) min_date, NextBillingPeriodEndDateTime max_date Into GetChainsSaleDate
from StoreTransactions T with(nolock)
inner join BillingControl B on B.ChainID = T.ChainID
inner join systementities s
on B.EntityIDToInvoice = s.EntityID
where SaleDateTime between dateadd(day, +1, LastBillingPeriodEndDateTime) and NextBillingPeriodEndDateTime
--and NextBillingPeriodRunDateTime <= convert(smalldatetime, GETDATE())
and IsActive = 1
and s.EntityTypeID = 2
--and B.BillingControlFrequency = 'weekly'
and B.BusinessTypeID = 1
and T.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 13, 14))


;with ranges(chainid,date,lastdate)
as 
   (
    select distinct chainid,min_date,max_date
      from GetChainsSaleDate
    /*querying itself recursively*/
              union all 
    select chainid,date+1,lastdate
      from ranges
       where date+1 <= lastdate
    )
--insert into ChainsMissingDates(chainid,saledate)
select ranges.chainid,date missing Into ChainsWithMissingDates
from ranges
left join GetChainsSaleDate 
on ranges.chainid=GetChainsSaleDate.ChainID
and ranges.date=GetChainsSaleDate.SaleDateTime
where GetChainsSaleDate.SaleDateTime is null    
option (maxrecursion 0)


Select *
from ChainsWithMissingDates D
Where missing <= dateadd(day, -3, getdate())
	
	If @@ROWCOUNT > 0
	
		Begin

			Declare @ChainidMissingDates table (chainid int, chainname varchar(50), Mdate varchar(50) )
			Insert Into @ChainidMissingDates (chainid, chainname, Mdate)

				Select D.chainid, C.ChainName, D.missing
				from ChainsWithMissingDates D
				Inner Join Chains C
				on C.ChainID = D.chainid 
				Where missing <= dateadd(day, -3, getdate())
				Order by chainid, missing
				
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

			EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Missing Sale Dates'
				  ,@ProcessedEmailBody
				  ,'DataTrue System', 0, @Processedemailaddresses
		End
	Else
		Begin
			DECLARE @ProcessedEmailBody2 VARCHAR(MAX)
			SET @ProcessedEmailBody2 = 'No Chains Missing Sale Dates.'
				            
							--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
			DECLARE @Processedemailaddresses2 VARCHAR(MAX) = ''
			SET @Processedemailaddresses2 = 'DATATRUEIT@icucsolutions.com; gilad.keren@icucsolutions.com; amol.sayal@icucsolutions.com; Bill.Harris@icucsolutions.com; ademola.akinola@icucsolutions.com'

			EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Missing Sale Dates'
				  ,@ProcessedEmailBody2
				  ,'DataTrue System', 0, @Processedemailaddresses2
		End
END
GO
