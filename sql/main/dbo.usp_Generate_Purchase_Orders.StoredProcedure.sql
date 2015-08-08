USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Purchase_Orders]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Generate_Purchase_Orders]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50), 
@PODate varchar(20)
as -- exec usp_Generate_Purchase_Orders '40557','40393','','-1','','04/29/2013'
Begin
set nocount on
	
	exec usp_Generate_Purchase_Data @SupplierId,  @ChainId, @StoreNumber, @Banner, @UPC, @PODate

	Declare @strSQL varchar(2000)
	
	set @strSQL = ' select * from PO_PurchaseOrderData where (dateadd(d, LeadTime, ''' + @PODate + ''')) = [Upcoming Delivery Date]'

	if(@SupplierId<>'-1')
				set @strSQL = @strSQL +  ' and SupplierID=' + @SupplierId 
				
	if(@ChainId<>'-1')				
			set @strSQL = @strSQL +  ' and ChainId=' + @ChainId 
			
	if(@StoreNumber<>'')				
			set @strSQL = @strSQL +  ' and StoreIdentifier like ''%' + @StoreNumber + '%'''
			
	if(@Banner<>'-1')				
			set @strSQL = @strSQL +  ' and Banner=''' + @Banner + ''''
			
	if(@UPC<>'')				
			set @strSQL = @strSQL +  ' and UPC like ''%' + @UPC + '%'''
	
	print @strSQL		
	exec (@strSQL)

End
GO
