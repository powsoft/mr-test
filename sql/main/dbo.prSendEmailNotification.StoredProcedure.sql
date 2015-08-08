USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailNotification]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prSendEmailNotification]
@subjectpassed nvarchar(255),
@bodypassed nvarchar(4000),
@fromstring nvarchar(255)='',
@fromid int=0
/*
prSendEmailNotification
'Test Subject 2',
'Test Body',
'DataTrue System',
0
*/
as
declare @supportrecipients varchar(1000)
declare @MyID int
set @MyID = 7612

set @supportrecipients = 'charlie@futuresights.net'

EXEC msdb..sp_send_dbmail @profile_name='DataTrue System',
@recipients=@supportrecipients,
@subject=@subjectpassed,
@body=@bodypassed



return
GO
