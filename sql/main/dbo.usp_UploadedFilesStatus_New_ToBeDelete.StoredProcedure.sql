USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UploadedFilesStatus_New_ToBeDelete]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UploadedFilesStatus_New_ToBeDelete]
-- Add the parameters for the stored procedure here
@FileName varchar(200),
@FileStatus varchar(50),
@SupplierId varchar(10),
@ChainId varchar(10)

AS 

--exec [usp_UploadedFilesStatus_New] '-1','0',62342,'-1'

BEGIN
declare @sqlQuery varchar(2000)
declare @fileNameNew varchar(500)	
	
	set @sqlQuery = 'select FileName, C.ChainName, StoreNumber, convert(varchar(10), EffectiveDate, 101) as [SaleDate], sum(Qty) as TotalUnits, sum(Qty*Cost) as TotalAmount
				 from [DataTrue_EDI].dbo.Inbound846Inventory_ACH_Approval A
				 left join Suppliers S on S.Supplieridentifier=A.SupplierIdentifier
				 left join Chains C on C.ChainIdentifier=A.ChainName
				 where 1=1 '

	if(@FileName<>'-1')
		set @sqlQuery=@sqlQuery+' and FileName like ''%' + @FileName + '%'''
	
	if(@SupplierId<>'-1')
		set @sqlQuery=@sqlQuery+' and S.SupplierId = ' + @SupplierId + ''
		
	if(@ChainId<>'-1')
		set @sqlQuery=@sqlQuery+' and C.ChainId = ' + @ChainId + ''
 
	if(@FileStatus='0')
		set @sqlQuery = @sqlQuery + ' and RecordStatus < 2' 
		
	else if(@FileStatus<>'')
		set @sqlQuery = @sqlQuery + ' and RecordStatus = ''' + @FileStatus+'''' 
		
	set @sqlQuery=@sqlQuery+' group by FileName, C.ChainName, StoreNumber, EffectiveDate ' 
	
	exec (@sqlQuery)

END
GO
