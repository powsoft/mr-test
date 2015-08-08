USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UnsettleShrink]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[dbo].[usp_UnsettleShrink] '50721','62348', 'Walmart', '10/6/2013','9/23/2013','1440',''

-- EXEC [usp_UnsettleShrink] '40557','40393','Albertsons - SCAL','03/16/2015','12/29/2014','6102',''


CREATE Procedure [dbo].[usp_UnsettleShrink]
     @SupplierId varchar(20),
     @ChainId varchar(20),
     @Banner varchar(50),
     @PhysicalInventoryDate varchar(10),
     @BIDate varchar(10),
     @StoreNumber nvarchar(50) ,
     @UPC varchar(50)
as
begin
    Declare @strSQL varchar(4000)
    																					
    set @strSQL= 'Delete I 
									from InventorySettlementRequests I
									inner join InventorySettlementRequests I1 on I1.retailerId=I.retailerId and I1.supplierId=I.supplierId and I1.StoreID=I.StoreID 
									and I1.Banner=I.Banner and I1.PriorInventoryCountDate=I.PriorInventoryCountDate 
									where I.Settle=''Pending'' and I1.Settle <>''Pending'' and I.PhysicalInventoryDate > I1.PhysicalInventoryDate'
    
    if(@SupplierId<>'-1')
        set @strSQL = @strSQL + ' and I.SupplierID=' + @SupplierId + ''
                
    if(@ChainId<>'-1')
        set @strSQL = @strSQL + ' and I.RetailerId=' + @ChainId + ''
       
    if(@Banner<>'''')
        set @strSQL = @strSQL + ' and I.Banner=''' + @Banner + ''''                
		
		if (convert(varchar(10),@BIDate,101) <> '1900/01/01')
				set @strSQL = @strSQL + ' and cast(I.PriorInventoryCountDate as date) =  '''  + @BIDate + ''''                   
                        
    if (@StoreNumber<>'')
				set @strSQL = @strSQL + ' and I.StoreNumber='''  + @StoreNumber + ''''
     
    if(@UPC<>'')
				set @strSQL = @strSQL + ' and I.UPC=''' + @UPC + ''''

		print(@strSQL)
    exec (@strSQL)
        
end
GO
