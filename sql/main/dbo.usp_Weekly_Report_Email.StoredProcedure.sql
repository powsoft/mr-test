USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Weekly_Report_Email]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_Weekly_Report_Email] 
 @SupplierId varchar(5),
 @FromStartDate varchar(50),
 @ToEndDate varchar(50)
AS

 
declare @sql varchar(8000)
declare @FileName varchar(1500)
declare @FilePath varchar(2000)
declare @FileLocation varchar(2000)

set @FileLocation = 'http://www.icontrolusa.com:8020/SubscriptionReports/'
set @FileName =  'Weekly_Report_' + CAST( MONTH(GETDATE()) as varchar) +  cast(DAY(getdate()) as varchar) +  cast(YEAR(getdate()) as varchar) + '_' + convert( varchar(40),NEWID())   + '.csv'
set @FilePath  = 'C:\DataTrueWeb\stagging\SubscriptionReports\'  

declare @varTmp varchar(2000)
set nocount on
set @varTmp = 'exec dbo.usp_WeeklyReport ' + @SupplierId + ',''' + cast(@FromStartDate as varchar) +  ''',''' + cast(@ToEndDate as varchar) + ''''

declare @NumRecords int
set @NumRecords = 0

exec (@varTmp )
set @NumRecords = @@ROWCOUNT 

print 'Rows : ' + cast(@numRecords as varchar)

-- Generate files only if the stored procedure has some records.
if @NumRecords > 1
Begin

	declare @col1 varchar(5000)
	select @col1=(case when @col1 is null then '' else @col1 + ',' end) + ''''+column_name+'''' from 
	INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='tmpweekly'
	
	declare @col2 varchar(5000)
	select @col2=(case when @col2 is null then '' else @col2 + ',' end) + 'cast(['+column_name+'] as varchar)' from 
	INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='tmpweekly'
	
	select @sql = 'bcp "select top 1 ' + @col1 + '  from datatrue_main.dbo.tmpweekly union all select ' + @col2 + ' from datatrue_main.dbo.tmpweekly" queryout ' + @FilePath + @FileName + ' -c  -t, -T -S ' + @@servername
	print(@sql)
	exec master..xp_cmdshell @sql

	set @FileLocation = @FileLocation + REPLACE( @FileName ,'.csv','.zip')

	--Zipping the file
	declare @Source varchar(200), @Destination varchar(200)
	set @Source = @FilePath + '' + @filename
	set @Destination = @FilePath + '' + REPLACE( @FileName , '.csv', '.zip')

	exec dbo.usp_zipfiles @source ,@Destination
end

--Generating Email Text
declare @tableHTML varchar(4000)
SET @tableHTML =
    N'<img src="http://www.icontroldsd.com/images/logo.png" alt="iControl"><br><font size="-2">Your Proven Partner for Supply Chain Visibility and Collaboration</font><br><br>' 

    set @tableHTML = @tableHTML +  
    N'The DataTrue® by iControl Weekly Report has been processed! <br><br>'
    
if @NumRecords = 1 
	Begin
		set @tableHTML = @tableHTML + 'No records found for this week.'
	end 
else 
	Begin
		set @tableHTML = @tableHTML + 'The DataTrue® by iControl Report is ready for you to pick up, view, and save at your convenience. <br>' + 
		N'Because many reports are large in size, we do not email them as attachments in order not to overload your inbox. You can access your report by <a href="' + @FileLocation  + '">clicking here</a><br><br>' 
	end

set @tableHTML = @tableHTML + 

N'If you need further assistance on how to save, or use reports, or if you’d like some ideas on which reports to use depending on your objectives, we are here to help. Contact iControl <a href="mailto:judy.farniok@icontroldsd.com">customer support here.</a><br><br>' +

N'Thank you for your business!</font>'
 
if @NumRecords > 1
	Begin 
		--Sending Email
		EXEC msdb.dbo.sp_send_dbmail
		 @profile_name='iControlUSA',
			@recipients='vishal@amebasoftwares.com' ,
			@subject = 'Weekly Report'  ,
			@body = @tableHTML , 
			@body_format = 'HTML';
	end 

set nocount off
GO
