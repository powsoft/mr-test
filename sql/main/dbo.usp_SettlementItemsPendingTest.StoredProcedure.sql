USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SettlementItemsPendingTest]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SettlementItemsPendingTest]
    @ChainId varchar(10),
    @SupplierId varchar(10),
    @BannerId varchar(200),
    @StoreId varchar(6),
    @SaleDate varchar(50),
    @ByUPC varchar(1),
    @UPC varchar(20),
    @Status varchar(6),
    @ShowAggregate varchar(1),
    @ProductIdentifierType int
as

Begin
 Declare @sqlQuery varchar(6000)
  if (@ByUPC='Y') 
   begin 
    set @sqlQuery = 'SELECT  I.StoreID, S.StoreIdentifier as StoreNumber, S.Custom1 as Banner, I.SaleDate,' 
	                   
    set @sqlQuery = @sqlQuery +  'SUM(TotalQty) as [UnitCount], sum(I.TotalCost ) AS InvoiceAmount,'
         

    set @sqlQuery = @sqlQuery +  'P.IdentifierValue as UPC, P.ProductId '
    
                    
    set @sqlQuery = @sqlQuery + ' FROM  dbo.InvoiceDetails AS I
                    Inner Join dbo.Stores S on S.StoreId = I.StoreId'

    set @sqlQuery = @sqlQuery + ' Inner Join dbo.ProductIdentifiers P on P.ProductId = I.ProductId'

    set @sqlQuery = @sqlQuery + ' WHERE I.InvoiceDetailTypeID IN (3, 5, 9, 10)
                    AND I.InventorySettlementId IS NULL
                    AND I.SupplierID = ' + @SupplierId + '
                    AND I.ChainID=' + @ChainId


    set @sqlQuery = @sqlQuery + ' and P.ProductIdentifierTypeId=' + cast(@ProductIdentifierType as varchar)
    
 
    if(@BannerId<>'-1')
        set @sqlQuery = @sqlQuery +  ' and S.Custom1=''' + @BannerId + ''''
       
    if(@StoreId <>'-1')
        set @sqlQuery = @sqlQuery +  ' and I.StoreId=' + @StoreId
   
    if(@UPC <>'')
        set @sqlQuery = @sqlQuery +  ' and P.IdentifierValue like ''%' + @UPC + '%''';                   
      
	if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and I.SaleDate  <= ''' + @SaleDate  + '''';
	
    set @sqlQuery = @sqlQuery + ' group by I.StoreID, S.StoreIdentifier, S.Custom1, '
   
   
    set @sqlQuery = @sqlQuery + ' P.IdentifierValue, P.ProductId, '
   
    set @sqlQuery = @sqlQuery + 'I.SaleDate '
   
    set @sqlQuery = @sqlQuery + ' order by I.StoreID, S.Custom1, SaleDate DESC'
   end
  else
   begin
	   set @sqlquery= 'SELECT  i.StoreID, i.StoreNumber, i.Banner, I.SaleDate,i.UnitCount , i.InvoiceAmount,i.Aggregate
 
			FROM  dbo.[tmpShrinkSettlementByStore] AS I
								Inner Join dbo.Stores S on S.StoreId = I.StoreId WHERE 
								 I.SupplierID =  ' + @SupplierId + '
			                    AND I.ChainID=' + @ChainId
		if(@BannerId<>'-1')
        set @sqlQuery = @sqlQuery +  ' and i.banner=''' + @BannerId + ''''
       
		if(@StoreId <>'-1')
        set @sqlQuery = @sqlQuery +  ' and I.StoreId=' + @StoreId
   
   if(@ShowAggregate='Y')      
		begin
			set @sqlQuery = @sqlQuery + '	AND (I.SaleDate)=(select max(saledate) from tmpShrinkSettlementByStore ID
					where 	 ID.StoreID = I.StoreID
					
					AND ID.SupplierID = ' + @SupplierId + '
					AND ID.ChainID=' + @ChainId 
	                
			if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and ID.SaleDate  <= ''' + @SaleDate  + ''''
			set @sqlQuery = @sqlQuery + ' )'
		end		
	else
	   begin
		
          
        if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
				set @sqlQuery = @sqlQuery + ' and I.SaleDate  <= ''' + @SaleDate  + '''';
			                    
	   end
	
		set @sqlQuery = @sqlQuery +	' group by i.StoreID, i.StoreNumber, i.Banner, I.SaleDate,i.UnitCount , i.InvoiceAmount,i.Aggregate
			order by I.StoreID, i.Banner , i.SaleDate DESC'
   end             
    exec (@sqlquery)
   print  (@sqlquery)
End
GO
