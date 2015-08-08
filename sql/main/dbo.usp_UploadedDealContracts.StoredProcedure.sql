USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UploadedDealContracts]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UploadedDealContracts]
-- Add the parameters for the stored procedure here
@PersonID varchar(20),
@SupplierID varchar(20),
@DealNo varchar(50),
@DocumentName Varchar(50)

AS
BEGIN
declare @sqlQuery varchar(2000)

set @sqlQuery = 'Select ID,[PersonId], Suppliers.SupplierId, DealContracts.DealNumber, [FileName] From [DealContracts]
				inner join suppliers on suppliers.SupplierID=DealContracts.SupplierID
				where 1=1  '
				
	if(@SupplierID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and DealContracts.SupplierID=' + @SupplierID

	if(@DealNo<>'All')
		set @sqlQuery = @sqlQuery +  ' and DealContracts.DealNumber=''' + @DealNo + ''''
		
	if(@DocumentName <>'')
		set @sqlQuery = @sqlQuery + ' and DealContracts.FileName like ''%' + @DocumentName  + '%''';
	
	exec (@sqlQuery)

END
GO
