USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailNotification_WithAttachments_PassEmailAddresses]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prSendEmailNotification_WithAttachments_PassEmailAddresses]
@subjectpassed nvarchar(255),
@bodypassed nvarchar(4000),
@fromstring nvarchar(255)='',
@fromid int=0,
@toemail nvarchar(500)='',
@ccemail nvarchar(500)='',
@bccemail nvarchar(500)='',
@fileattachments nvarchar(1000)=''
/*
prSendEmailNotification_PassEmailAddresses
'Test Subject 1',
'Test Body',
'DataTrue System',
0,
'charlie.clark@icontroldsd.com',
'',
'',
<fileattachment>
*/
as
declare @supportrecipients varchar(1000)
declare @MyID int
set @MyID = 7612

set @supportrecipients = 'charlie@futuresights.net'

EXEC msdb..sp_send_dbmail @profile_name='DataTrue System',
@recipients=@toemail,
@subject=@subjectpassed,
@body=@bodypassed,
@file_attachments=@fileattachments



return
GO
