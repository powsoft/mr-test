USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UploadedFiles]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UploadedFiles]
-- Add the parameters for the stored procedure here
@PersonID varchar(20),
@ChainID varchar(20),
@SupplierID varchar(20),
@DocumentName Varchar(50),
@FileType varchar(20),
@StartDate varchar(50),
@EndDate varchar(50),
@UploadSource varchar(20)

AS --exec usp_UploadedFiles '42115','40393','-1','','opF','1900-01-01','05-09-2012','FCT'

BEGIN
declare @sqlQuery varchar(2000)

set @sqlQuery = 'Select UploadID,[PersonId],Chains.ChainName,Suppliers.SupplierId,Suppliers.SupplierName, [FileName], 
		[FileType],FileLocation,FileSize,FileStatus, [TimeStamp] From [UploadedFiles] 
		inner join Chains on chains.ChainID=UploadedFiles.ChainID 
		inner join suppliers on suppliers.SupplierID=UploadedFiles.SupplierID 
		where 1=1  ' 

if(@SupplierID<>'-1')
	set @sqlQuery = @sqlQuery +  ' and UploadedFiles.SupplierID=' + @SupplierID

if(@DocumentName <>'')
	set @sqlQuery = @sqlQuery + ' and UploadedFiles.FileName like ''%' + @DocumentName  + '%''';

if(@FileType  <>'')
	set @sqlQuery = @sqlQuery + ' and UploadedFiles.filetype like ''%' + @FileType  + '%''';

if(@UploadSource = 'FCT')
	set @sqlQuery = @sqlQuery + ' and UploadedFiles.UploadSource =''' + @UploadSource  + '''';
else
	set @sqlQuery = @sqlQuery + ' and (UploadedFiles.UploadSource <>''FCT'' or UploadedFiles.UploadSource is null)';

if (convert(date, @StartDate  ) > convert(date,'1900-01-01')) 
	set @sqlQuery = @sqlQuery + ' and Convert(date,UploadedFiles.TimeStamp) >= ''' + @StartDate + ''''  ;

if (convert(date, @EndDate  ) > convert(date,'1900-01-01'))
	set @sqlQuery = @sqlQuery + ' and Convert(date,UploadedFiles.TimeStamp) <= ''' + @EndDate  + '''';

exec (@sqlQuery)

END
GO
