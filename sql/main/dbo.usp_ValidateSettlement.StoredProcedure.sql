USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ValidateSettlement]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[dbo].[usp_ValidateSettlement] '50721','62348', 'Walmart', '10/6/2013','9/23/2013','1440',''
--EXEC usp_ValidateSettlement '40557','40393','Albertsons - SCAL','03/16/2015','12/29/2014','',''

CREATE Procedure [dbo].[usp_ValidateSettlement]
     @SupplierId varchar(20),
     @ChainId varchar(20),
     @Banner varchar(50),
     @PhysicalInventoryDate varchar(10) ,
     @BIDate varchar(10) ,
     @StoreNumber nvarchar(50) ,
     @UPC varchar(50)
as
begin
    Declare @strSQL varchar(4000)
    																					
    set @strSQL= 'Select distinct IR.PhysicalInventoryDate 
									from InventorySettlementRequests IR 
									where Settle = ''Pending'''
    
    if(@SupplierId<>'-1')
        set @strSQL = @strSQL + ' and IR.SupplierID=' + @SupplierId + ''
                
    if(@ChainId<>'-1')
        set @strSQL = @strSQL + ' and IR.RetailerId=' + @ChainId + ''
       
    if(@Banner<>'''')
        set @strSQL = @strSQL + ' and IR.Banner=''' + @Banner + ''''
    
    if (convert(varchar(10),@PhysicalInventoryDate,101)<>'1900/01/01')
			set @strSQL = @strSQL + ' and cast(IR.PhysicalInventoryDate AS DATE) > '''  + @PhysicalInventoryDate + ''''  
		
		if (convert(varchar(10),@BIDate,101) <> '1900/01/01')
			set @strSQL = @strSQL + ' and cast(IR.PriorInventoryCountDate as date) =  ''' +  @BIDate + ''''
                        
    if (@StoreNumber<>'')
			set @strSQL = @strSQL + ' and IR.StoreNumber ='''  + @StoreNumber + ''''
     
    if(@UPC<>'')
            set @strSQL = @strSQL + ' and IR.UPC=''' + @UPC + ''''

		print(@strSQL)
    exec (@strSQL)
        
end
GO
