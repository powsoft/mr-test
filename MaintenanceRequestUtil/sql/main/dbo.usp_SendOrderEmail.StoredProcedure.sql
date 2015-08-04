USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SendOrderEmail]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SendOrderEmail]
(
@EmailSubject varchar(200),
@BodyText varchar(2000),
@SQLQuery varchar(5000),
@FileName varchar(200)
)
as
begin
	DECLARE @tab VARCHAR(1)
	SET @tab = CHAR(9)
	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'DataTrue System',
	@recipients = 'edi@icontroldsd.com',
	@copy_recipients = 'bill.harris@icontroldsd.com;vishal.gupta@icontroldsd.com',
	@blind_copy_recipients = null,
	@subject = @EmailSubject,
	@body_format = 'HTML',
	@body = @BodyText,
	@importance = 'Normal',
	@sensitivity = 'Normal',
	@file_attachments = null,
	@query = @SQLQuery, 
	@attach_query_result_as_file = 1,
	@query_attachment_filename = @FileName,
	@query_result_header = 1,
	@query_result_width = 32767, -- can go to 32767 for query width
	@query_result_separator = @tab,
	@exclude_query_output = 0,
	@append_query_error = 1,
	@query_result_no_padding =1 -- turn off padding of fields with spaces
	
end
GO
