USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prWeeklyPOSBillingCompleteUpdate]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prWeeklyPOSBillingCompleteUpdate]
as

declare @currentdate date

set @currentdate = CAST(getdate() as DATE)


--select * from [DataTrue_EDI].[dbo].[ProcessStatus] order by date

update [DataTrue_EDI].[dbo].[ProcessStatus]
set BillingComplete = 1
where upper(ltrim(rtrim(ChainName))) in ('KNG', 'DCS')
and CAST(date as date) = @currentdate
and isnull(BillingIsRunning, 0) = 1
and isnull(BillingComplete, 0) = 0

/*
INSERT INTO [DataTrue_EDI].[dbo].[ProcessStatus]
           ([ChainName]
           ,[Date]
           ,[BillingComplete])
     VALUES
           ('SV'
           ,CAST(getdate() as DATE)
           ,1)
*/
GO
