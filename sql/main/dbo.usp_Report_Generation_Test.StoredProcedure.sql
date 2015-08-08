USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Generation_Test]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
--exec [usp_Report_Generation_Test] '05PM'
CREATE procedure [dbo].[usp_Report_Generation_Test] 
 @Time varchar(20)
AS
DECLARE @PersonId int,@GetEveryXDays int ,@ReportName varchar(75), @StoredProcedureName varchar(100), @AutoReportRequestID int , @EmailID varchar(150),@ReportID int,@LastXDays int,@ChainId varchar(20),@Banner varchar(50),@SupplierID varchar(20),@StoreID varchar(20),@ProductUPC varchar(20),@FileType varchar(5),@LastDateSent datetime,@LastProcessDate datetime, @RecordCount bigint;
declare @FileLocation varchar(1000)
 if @Time = '05PM' 
  begin  
   DECLARE report_cursor CURSOR FOR 
   SELECT   AutoReportRequestID,automatedreportslist.ReportName  ,automatedreportslist.StoredProcedureName, PersonId,Logins.Login as EmailID, AutomatedReportsRequests.ReportID,LastXDays,ChainId,Banner,SupplierID,StoreID,ProductUPC,FileType,LastDateSent, LastProcessDate, RecordCount,GetEveryXDays
   FROM AutomatedReportsRequests 
   inner join logins on logins.OwnerEntityId = AutomatedReportsRequests.PersonId 
   inner join AutomatedReportsList on automatedreportslist.reportid = AutomatedReportsRequests.ReportID 
   WHERE ((Days='' and (DATEADD(day,GetEveryXDays,LastProcessDate) <= getdate() or LastProcessDate  is null))
		 or (Days like + '%' + CAST( datepart (dw, GETDATE()) as varchar) + '%' and GetEveryXDays=1))
		and (by5PMEST = 'true' )
		and PersonID=41682
		
   set @Time = '05:00 PM'
  end 
 else 
  begin
   DECLARE report_cursor CURSOR FOR 
   SELECT  AutoReportRequestID,automatedreportslist.ReportName  ,automatedreportslist.StoredProcedureName, PersonId,Logins.Login as EmailID, AutomatedReportsRequests.ReportID,LastXDays,ChainId,Banner,SupplierID,StoreID,ProductUPC,FileType,LastDateSent,LastProcessDate, RecordCount,GetEveryXDays
   FROM AutomatedReportsRequests inner join logins on logins.OwnerEntityId = AutomatedReportsRequests.PersonId inner join AutomatedReportsList on automatedreportslist.reportid = AutomatedReportsRequests.ReportID 
   WHERE ((Days='' and DATEADD(day,GetEveryXDays,LastProcessDate) <= getdate())
		 or (Days like + '%' + CAST( datepart (dw, GETDATE()) as varchar) + '%' and GetEveryXDays=1))
		and by12PMEST = 'true' or LastProcessDate  is null 
   set @Time = '12:00 PM'
  end 

OPEN report_cursor;

FETCH NEXT FROM report_cursor 
INTO @AutoReportRequestID,@ReportName,@StoredProcedureName, @PersonId ,@EmailID,@ReportID  ,@LastXDays,@ChainId,@Banner,@SupplierID ,@StoreID ,@ProductUPC ,@FileType ,@LastDateSent,@LastProcessDate, @RecordCount, @getEveryXDays ;

while @@FETCH_STATUS =0 
begin 
 
declare @sql varchar(8000)
declare @FileName varchar(1500)
declare @FilePath varchar(2000)
set @FileLocation = 'http://www.icontrolusa.com:8020/SubscriptionReports/'
set @FileName =  replace(@ReportName , ' ','_') + '_' + CAST( @PersonId as varchar) + '_' + CAST( MONTH(GETDATE()) as varchar) +  cast(DAY(getdate()) as varchar) +  cast(YEAR(getdate()) as varchar) + '_' + convert( varchar(40),NEWID())   + '.csv'
set @FilePath  = 'C:\DataTrueWeb\stagging\SubscriptionReports\'  

 print @StoredProcedureName
 
declare @varTmp varchar(2000)
  set nocount on
select @sql = 'bcp "exec DataTrue_main.dbo.' + @StoredProcedureName + ' ' + @ChainId + ',' + CAST( @PersonId  as varchar)+ ',''' + @Banner + ''',' + @ProductUPC + ',' + @SupplierID + ',' + @StoreID + ',' + cast(@LastXDays as varchar) + '" queryout ' + @FilePath + @FileName + ' -c  -t, -T -S' + @@servername
set @varTmp = 'exec ' + @StoredProcedureName + ' ' + @ChainId + ',' + CAST( @PersonId  as varchar)+ ',''' + @Banner + ''',' + @ProductUPC + ',' + @SupplierID + ',' + @StoreID + ',' + cast(@LastXDays as varchar) + ''

-- CLOSE report_cursor;
-- DEALLOCATE report_cursor;
declare @Err int
set @err = 0

IF @@ERROR <>0
BEGIN
  set  @err = @err + 1
  PRINT 'Error Occured'
  return @@error
END

declare @NumRecords int
set @NumRecords = 0

exec (@varTmp )
set @NumRecords = @@ROWCOUNT 
print 'Rows : ' + cast(@numRecords as varchar)

-- Generate files only if the stored procedure has some records.
if @NumRecords > 1
Begin
 exec master..xp_cmdshell @sql

 set @FileLocation = @FileLocation + REPLACE( @FileName ,'.csv','.zip')

 --Zipping the file
 declare @Source varchar(2000), @Destination varchar(2000)
 set @Source = @FilePath + '' + @filename
 set @Destination = @FilePath + '' + REPLACE( @FileName , '.csv', '.zip')

 exec dbo.usp_zipfiles @source ,@Destination
end

--Generating Email Text
declare @tableHTML varchar(5000)
SET @tableHTML =
    N'<img src="http://www.icontroldsd.com/images/logo.png" alt="iControl"><br><font size="-2">Your Proven Partner for Supply Chain Visibility and Collaboration</font><br><br>' 

If @Time = '12:00 PM'
 SET @tableHTML =@tableHTML + N'<font size="-1">Good Morning!<br><br>'

If @Time <> '12:00 PM'
 SET @tableHTML =@tableHTML + N'<font size="-1">Good Afternoon!<br><br>'
 
 if @ChainId='-1'
  set @ChainId='All'
 
 if @SupplierID='-1'
  set @SupplierID='All'
 
    set @tableHTML = @tableHTML +  
    N'The DataTrue® by iControl Report you subscribed to has been processed! <br><br>'
    
    set @tableHTML = @tableHTML + 
    N'The criteria you have selected for the report are:<br>' +
 N'<font size="-2">Chain: ' + @ChainId + ',   Banner: ' + @Banner + ',    Supplier:' + @SupplierID  + ',   Frequency: Every ' + CAST( @GetEveryXDays as varchar)  + ' Day(s),   Range: Last ' + CAST( @LastXDays  as varchar) + ' Day(s)</font><br><br>'

    
if @NumRecords = 1 
 Begin
  set @tableHTML = @tableHTML + 'No records matched the criteria above.'
  set @ReportName= @ReportName + ' - No matching records.'
 end 
else 
 Begin
  set @tableHTML = @tableHTML + 'The DataTrue® by iControl Report is ready for you to pick up, view, and save at your convenience. <br>' + 
  N'Because many reports are large in size, we do not email them as attachments in order not to overload your inbox. You can access your report by <a href="' + @FileLocation  + '">clicking here</a><br><br>' 
 end

set @tableHTML = @tableHTML + 
N'Would you like to change your reporting frequency or the criteria of any report? If so, <a href="http://www.icontroldsd.com/" >click here</a><br><br>' +

N'If you need further assistance on how to create, save, or use reports, or if you’d like some ideas on which reports to use depending on your objectives, we are here to help. Contact iControl <a href="mailto:judy.farniok@icontroldsd.com">customer support here.</a><br><br>' +

N'Thank you for your business!</font>'
 
if @NumRecords > 1
 Begin 
  --Sending Email
  EXEC msdb.dbo.sp_send_dbmail
   @profile_name='DataTrue System',
   @recipients='vishal@amebasoftwares.com', --@EmailID  ,
   @subject = @ReportName   ,
   @body = @tableHTML , 
   @body_format = 'HTML';
   set @LastDateSent = GETDATE();
  IF @@ERROR <>0
   BEGIN
   set  @err = @err + 1
    PRINT 'Error Occured'
    return @@error
   END
 end 

set nocount off

--Update LastSentDate value in table
--update AutomatedReportsRequests set LastProcessDate = GETDATE(), LastDateSent = @LastDateSent, Recordcount=@NumRecords  where AutoReportRequestID =@AutoReportRequestID
 
-- Get the next vendor.
FETCH NEXT FROM report_cursor 
INTO @AutoReportRequestID,@ReportName,@StoredProcedureName, @PersonId ,@EmailID,@ReportID  ,@LastXDays,@ChainId,@Banner,@SupplierID ,@StoreID ,@ProductUPC ,@FileType ,@LastDateSent,@LastProcessDate, @RecordCount, @getEveryxDays ;

END


 CLOSE report_cursor;
    DEALLOCATE report_cursor;
GO
