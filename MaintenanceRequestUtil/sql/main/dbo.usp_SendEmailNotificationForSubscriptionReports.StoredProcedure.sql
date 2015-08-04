USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SendEmailNotificationForSubscriptionReports]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_SendEmailNotificationForSubscriptionReports]
@subjectpassed nvarchar(255),
@bodypassed nvarchar(4000),
@ToReceipient nvarchar(255)=''
 as

EXEC msdb..sp_send_dbmail @profile_name='DataTrue System',
@recipients=@ToReceipient,
@subject=@subjectpassed,
@body=@bodypassed,
@body_format = 'HTML';



return
GO
