USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSBillingCompleteUpdate]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSBillingCompleteUpdate]
as

declare @currentdate date

set @currentdate = CAST(getdate() as DATE)


--select * from [DataTrue_EDI].[dbo].[ProcessStatus]

update [DataTrue_EDI].[dbo].[ProcessStatus]
set BillingComplete = 1
where upper(ltrim(rtrim(ChainName))) = 'SV'
and CAST(date as date) = @currentdate
and RecordTypeID = 0

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
