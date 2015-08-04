USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetUserEmailFromUploadedFile]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetUserEmailFromUploadedFile]
@filename nvarchar(255)
,@numbertostrip tinyint
--,@emailaddress nvarchar(255)

as
/*
prGetUserEmailFromUploadedFile '20130531_9427_000044269_000050333_PDIBEER_RegulatedInvoices_05312013.xlsx', 4
prGetUserEmailFromUploadedFile '20130717_11511_000062314_000062331_silvereagle_.xlsx.csv', 5
select * from persons where personid = 50333
select * from UploadedFiles order by uploadid desc
*/

--declare @filename nvarchar(255) = '20130717_11511_000062314_000062331_silvereagle_.xlsx.csv' declare @numbertostrip tinyint = 5
declare @rawfilename nvarchar(255)
declare @lookupfilename nvarchar(255)
declare @personid int
declare @emailaddress nvarchar(255)


select @rawfilename = Right(@filename, len(@filename) - CHARINDEX('_',@filename))
if @numbertostrip = 1
	set @lookupfilename = @rawfilename	 
select @rawfilename = Right(@rawfilename, len(@rawfilename) - CHARINDEX('_',@rawfilename))
if @numbertostrip = 2
	set @lookupfilename = @rawfilename
select @rawfilename = Right(@rawfilename, len(@rawfilename) - CHARINDEX('_',@rawfilename))
if @numbertostrip = 3
	set @lookupfilename = @rawfilename
select @rawfilename = Right(@rawfilename, len(@rawfilename) - CHARINDEX('_',@rawfilename))
if @numbertostrip = 4
	set @lookupfilename = @rawfilename
if @numbertostrip = 5
	set @lookupfilename = REPLACE(@filename, '.csv', '')
print @lookupfilename

set @personid = null

select @personid = PersonID
from datatrue_main.dbo.UploadedFiles
where LTRIM(rtrim(FileName)) = @lookupfilename

if @personid is not null
	begin
	
		select @emailaddress = login from Logins where OwnerEntityId = @personid
	end
else
	begin
		set @emailaddress = 'charlie.clark@icontroldsd.com'
	
	end
	
select @emailaddress
	
return
GO
