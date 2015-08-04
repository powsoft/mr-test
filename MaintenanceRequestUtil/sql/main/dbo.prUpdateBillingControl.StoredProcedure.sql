USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateBillingControl]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe w/ Charlie Clark
-- Create date: 3/17/2015
-- Description:	Updates any out of sync records on the Billing Control table for Weekly frequency, 
-- and updates the Daily Frequency records to current values
-- =============================================
CREATE PROCEDURE [dbo].[prUpdateBillingControl] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select chainid, entityidtoinvoice, BillingControlID, cast(null as datetime) CorrectNextBillingEndDateTime, 
cast(null as datetime) CorrectNextBillingRunDateTime
,BillingControlDay, BillingControlClosingDelay,
LastBillingPeriodEndDateTime, NextBillingPeriodEndDateTime,NextBillingPeriodRunDateTime
into #BillingControlSync
--select * 
from BillingControl
where BusinessTypeID in (1,4)
and BillingControlFrequency = 'weekly'
and IsActive = 1

update b set b.CorrectNextBillingEndDateTime = 
case when GETDATE() <= DATEADD(day,BillingControlClosingDelay,DATEADD(day,BillingControlDay - DATEPART(WEEKDAY,GETDATE()),GETDATE()))
	then cast(DATEADD(day,BillingControlDay - DATEPART(WEEKDAY,GETDATE()),GETDATE()) as date)
	else cast(DATEADD(day,7 - DATEPART(WEEKDAY,GETDATE()) + BillingControlDay ,GETDATE()) as date)
	end
--select *
from #BillingControlSync b

update b set b.CorrectNextBillingRunDateTime = 
DATEADD(day,BillingControlClosingDelay ,b.CorrectNextBillingEndDateTime)
--select *
from #BillingControlSync b

update b set b.CorrectNextBillingRunDateTime = 
DATEADD(hour,DtHours ,b.CorrectNextBillingRunDateTime)
--select *
from #BillingControlSync b
inner join (Select BillingControlID, SUM(MinutesFromMidnight/60) DtHours 
			From BillingControl_POS P
			Where P.MinutesFromMidnight <> 0
			Group by BillingControlID) a
on a.BillingControlID = B.BillingControlID

Declare @BCUpdate Int
Select @BCUpdate = COUNT(*)
--Select Distinct b.*
from #BillingControlSync b
inner join BillingControl c
on b.BillingControlID = c.BillingControlID
where 1=1
and (Convert(date, b.CorrectNextBillingEndDateTime) > convert(date, c.NextBillingPeriodEndDateTime) or convert(date, b.CorrectNextBillingRunDateTime) > convert(date, c.NextBillingPeriodRunDateTime))

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing Control Records Need To Be Updated'
		,'POS Billing Control records have been updated. DateTimeLastUpdate = Getdate()'
		,'DataTrue System', 0, 'josh.Kiracofe@icucsolutions.com'

--if @BCUpdate > 0
--	begin
	
--	Update C Set c.NextBillingPeriodEndDateTime = b.CorrectNextBillingEndDateTime
--	, c.NextBillingPeriodRunDateTime = b.CorrectNextBillingRunDateTime
--	, c.DateTimeLastUpdate = GETDATE()
--	, c.LastBillingPeriodEndDateTime = DATEADD(Day, -7, COrrectNextBillingEndDatetime)
--	from #BillingControlSync b
--	inner join BillingControl c
--	on b.BillingControlID = c.BillingControlID
--	where 1=1
--	and (Convert(date, b.CorrectNextBillingEndDateTime) > convert(date, c.NextBillingPeriodEndDateTime) or convert(date, b.CorrectNextBillingRunDateTime) > convert(date, c.NextBillingPeriodRunDateTime))
--	--and c.ChainID <> 42490
	
--		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing Control Records Have been Updated'
--		,'POS Billing Control records have been updated. DateTimeLastUpdate = Getdate()'
--		,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'
	
--	end

drop table #BillingControlSync

Update B Set B.LastBillingPeriodEndDateTime = dateadd(day, -2,CONVERT(date, getdate()))
,B.NextBillingPeriodEndDateTime  = DATEADD(day, -1, convert(date, getdate()))
,B.NextBillingPeriodRunDateTime = convert(date, getdate())
,B.DateTimeLastUpdate = GETDATE()
from BillingControl B
where BusinessTypeID in (1, 4)
and BillingControlFrequency = 'Daily'
--and NextBillingPeriodRunDateTime < GETDATE()
and IsActive = 1
and BillingControlID not in (Select BillingControlID from BillingControl where ChainID in (60620, 40393) and BusinessTypeID = 4)
and CONVERT(date, NextBillingPeriodRunDateTime) <> CONVERT(date, getdate())

END
GO
