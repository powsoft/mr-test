USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UploadedFiles_beta_Fix]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_UploadedFiles_beta '51108','-1','50729','','opF','1900-01-01','05-09-2012','FCT'
CREATE PROCEDURE [dbo].[usp_UploadedFiles_beta_Fix]
-- Add the parameters for the stored procedure here
@PersonID varchar(20),
@ChainID varchar(20),
@SupplierID varchar(20),
@DocumentName Varchar(50),
@FileType varchar(20),
@StartDate varchar(50),
@EndDate varchar(50),
@UploadSource varchar(20)

AS 
-- exec usp_UploadedFiles_beta_fix '75098','-1','75097','','RegulatedInvoices','1900-01-01','1900-01-01','FU'

BEGIN
declare @sqlQuery varchar(4000)

set @sqlQuery = '
select A.FileName, 
						(select sum(B.Qty) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval B  WITH (NOLOCK) 
							where A.FileName=B.FileName AND B.RecordStatus=2) as PendingUnits,
						(select sum(C.Qty*C.Cost) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval C  WITH (NOLOCK) 
							where A.FileName=C.FileName AND C.RecordStatus=2) as PendingAmount,
						(select sum(B.Qty) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval B  WITH (NOLOCK) 
							where A.FileName=B.FileName AND B.RecordStatus<2) as ApprovedUnits,
						(select sum(C.Qty*C.Cost) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval C  WITH (NOLOCK) 
							where A.FileName=C.FileName AND C.RecordStatus<2) as ApprovedAmount,
						(select sum(B.Qty) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval B  WITH (NOLOCK) 
							where A.FileName=B.FileName AND B.RecordStatus=3) as RejectedUnits,
						(select sum(C.Qty*C.Cost) from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval C  WITH (NOLOCK) 
							where A.FileName=C.FileName AND C.RecordStatus=3) as RejectedAmount into #SumOfQty
						from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval A  WITH (NOLOCK) 
						group BY A.FileName;
						

Select  UploadID,[PersonId], UploadedFiles.OriginalFileName as FileName, 
		REPLACE(UploadedFiles.OriginalFileName,''fixed_'','''')  AS FileNameNew,
		REPLACE(FileType,''SupplierInvoices'',''iControlTemplateSupplierInvoice'') AS [FileType],FileLocation,FileSize, [TimeStamp],
		ApprovedUnits as [Approved Units],
		ApprovedAmount as [Approved $ Amount],
		PendingUnits as [Pending Units],
		PendingAmount as [Pending $ Amount],
		RejectedUnits as [Rejected Units],
		RejectedAmount as [Rejected $ Amount]
		From [UploadedFiles]  WITH (NOLOCK) 
		left join #sumOfQty T on T.FileName= CASE WHEN charindex(''\'',reverse(FileLocation),1)<=0
					  then '''' else reverse(left(reverse(FileLocation),charindex(''\'',reverse(FileLocation),1) - 1)) end
		where 1=1  ' --T.FileName=reverse(left(reverse(FileLocation),charindex(''\'',reverse(FileLocation),1) - 1))

if(@ChainId<>'-1')
	set @sqlQuery = @sqlQuery +  ' and UploadedFiles.ChainId=' + @ChainId

if(@SupplierID<>'-1')
	set @sqlQuery = @sqlQuery +  ' and UploadedFiles.SupplierID=' + @SupplierID

if(@DocumentName <>'')
	set @sqlQuery = @sqlQuery + ' and UploadedFiles.OriginalFileName like ''%' + @DocumentName  + '%''';

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
print @sqlQuery

END
GO
