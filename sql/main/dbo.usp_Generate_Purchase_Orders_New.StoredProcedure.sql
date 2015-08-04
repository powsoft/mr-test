USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Purchase_Orders_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Generate_Purchase_Orders_New]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50), 
@PODate varchar(20)
as 
Begin
set nocount on
	
	--exec usp_Generate_Purchase_Data_New @SupplierId,  @ChainId, @StoreNumber, @Banner, @UPC, @PODate

	Declare @strSQL varchar(2000)
	
	set @strSQL = ' select P.*, C.FillRate as PAD from PO_PurchaseOrderHistoryData P inner join PO_Criteria C on C.StoreSetupID=P.StoreSetupID where P.deleteflag=0 and P.[Upcoming Delivery Date]>=''' +  @PODate + ''''

	if(@SupplierId<>'-1')
				set @strSQL = @strSQL +  ' and P.SupplierID=' + @SupplierId 
				
	if(@ChainId<>'-1')				
			set @strSQL = @strSQL +  ' and P.ChainId=' + @ChainId 
			
	if(@StoreNumber<>'')				
			set @strSQL = @strSQL +  ' and P.StoreIdentifier like ''%' + @StoreNumber + '%'''
			
	if(@Banner<>'-1')				
			set @strSQL = @strSQL +  ' and P.Banner=''' + @Banner + ''''
			
	if(@UPC<>'')				
			set @strSQL = @strSQL +  ' and P.UPC like ''%' + @UPC + '%'''
			
	exec (@strSQL)

End
GO
