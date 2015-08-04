USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailNotification_PassEmailAddresses]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prSendEmailNotification_PassEmailAddresses]
@subjectpassed nvarchar(255),
@bodypassed nvarchar(4000),
@fromstring nvarchar(255)='',
@fromid int=0,
@toemail nvarchar(100)='',
@ccemail nvarchar(100)='',
@bccemail nvarchar(100)=''
/*
prSendEmailNotification_PassEmailAddresses
'Test Subject 1',
'Test Body',
'DataTrue System',
0,
'charlie.clark@icontroldsd.com',
'',
''
*/
as
declare @supportrecipients varchar(1000)
declare @MyID int
set @MyID = 7612

set @supportrecipients = 'charlie@futuresights.net'

EXEC msdb..sp_send_dbmail @profile_name='DataTrue System',
@recipients=@toemail,
@copy_recipients=@ccemail,
@blind_copy_recipients=@bccemail,
@subject=@subjectpassed,
@body=@bodypassed



return
GO
