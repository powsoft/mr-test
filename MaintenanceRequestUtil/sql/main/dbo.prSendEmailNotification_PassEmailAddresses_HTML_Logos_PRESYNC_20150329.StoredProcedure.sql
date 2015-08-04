USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailNotification_PassEmailAddresses_HTML_Logos_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prSendEmailNotification_PassEmailAddresses_HTML_Logos_PRESYNC_20150329]
@subjectpassed nvarchar(255),
@bodypassed nvarchar(max),
@fromstring nvarchar(255)='',
@fromid int=0,
@toemail nvarchar(max)='',
@ccemail nvarchar(max)='',
@bccemail nvarchar(max)='',
@attachments varchar(max) = ''
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

declare @header varchar(1000)
declare @footer varchar(1000)
declare @body varchar(max)

set @header = '<html>
				<header>
				</header>
				<body>
					<div align="center" width="700">
						<div align="left">
							<img src="https://harmony.icucsolutions.com/images/harmonylogo.png" alt="iControl Header"/>
							<br/><br/>
						</div>
						<table width="100%" align="left">
							<tr>
								<td style="text-align: left;">
									<pre>'
set @footer =					   '</pre>
								</td>
							</tr>
						</table>
						<div align="left">
							<br/>
							<img src="https://harmony.icucsolutions.com/images/harmonyfooter.png" alt="iControl Footer"/>
						</div>
					</div>
				</body>
			</html>'
--set @header = '-attach C:\HarmonyEmailTemplate\header.png -attach C:\HarmonyEmailTemplate\footer.png <html><header></header><body><div align="center"><img src="cid:message-root.1" alt="iControl Header"/><div><pre>'
--set @footer = '</pre><div align="center"><img src="cid:message-root.2 alt="iControl Footer"/></div></body></html>'

set @body = @header + @bodypassed + @footer

EXEC msdb..sp_send_dbmail @profile_name='DataTrue System',
@recipients=@toemail,
@subject=@subjectpassed,
@body=@body,
@body_format = 'HTML',
@file_attachments=@attachments


return
GO
