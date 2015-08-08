USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SettlementItemsPending]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SettlementItemsPending]
    @ChainId varchar(10),
    @SupplierId varchar(10),
    @BannerId varchar(200),
    @StoreNo varchar(20),
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
		begin try
				DROP TABLE [@tmpShrinkSettlementUPC]
		end try
		begin catch
		end catch
		set @sqlQuery = 'SELECT  I.SupplierId, I.ChainId,I.StoreID, S.StoreIdentifier as StoreNumber, S.Custom1 as Banner, I.SaleDate, I.FinalInvoiceTotalCost,
						SUM(TotalQty) as [UnitCount], sum(I.TotalCost ) AS InvoiceAmount,
						P.IdentifierValue as UPC, P.ProductId 
					    
					    into [@tmpShrinkSettlementUPC]
					    
						FROM  dbo.InvoiceDetails AS I
						Inner Join dbo.Stores S on S.StoreId = I.StoreId
						Inner Join dbo.ProductIdentifiers P on P.ProductId = I.ProductId

						WHERE I.InvoiceDetailTypeID IN (3, 5, 9, 10)
						AND I.InventorySettlementId IS NULL
						AND I.SupplierID = ' + @SupplierId + '
						AND I.ChainID=' + @ChainId + '
						AND P.ProductIdentifierTypeId=' + cast(@ProductIdentifierType as varchar)
	 
		if(@BannerId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and S.Custom1=''' + @BannerId + ''''
	       
		if(@StoreNo <>'')
			set @sqlQuery = @sqlQuery +  ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''
	   
		if(@UPC <>'')
			set @sqlQuery = @sqlQuery +  ' and P.IdentifierValue like ''%' + @UPC + '%''';                   
	      
		if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
			set @sqlQuery = @sqlQuery + ' and I.SaleDate  <= ''' + @SaleDate  + '''';
		
		set @sqlQuery = @sqlQuery + ' group by I.SupplierId, I.ChainId,I.StoreID, S.StoreIdentifier, S.Custom1, P.IdentifierValue, P.ProductId, I.SaleDate, I.FinalInvoiceTotalCost '
		set @sqlQuery = @sqlQuery + ' order by S.Custom1, S.StoreIdentifier, P.ProductId,I.SaleDate DESC'
		
		exec (@sqlquery)
		
		set @sqlQuery = 'SELECT  i.StoreID, i.StoreNumber, i.Banner, I.SaleDate, I.FinalInvoiceTotalCost, I.UPC, I.ProductId,
						i.UnitCount , 
						(SELECT SUM(UnitCount) FROM [@tmpShrinkSettlementUPC] ID
										 where ID.SaleDate <= I.SaleDate 
										 AND ID.StoreID = I.StoreID
										 AND ID.ProductId = I.ProductId
										 AND ID.SupplierID = I.SupplierID
										 AND Id.ChainId=i.ChainID 
						) AS AggregateUnit ,
					    
						i.InvoiceAmount,
						
						(SELECT SUM(InvoiceAmount) FROM [@tmpShrinkSettlementUPC] ID
										 where ID.SaleDate <= I.SaleDate 
										 AND ID.StoreID = I.StoreID
										 AND ID.ProductId = I.ProductId
										 AND ID.SupplierID = I.SupplierID
										 AND Id.ChainId=i.ChainID 
						) AS Aggregate
 
						FROM  [@tmpShrinkSettlementUPC] AS I
						order by  i.Banner, i.StoreNumber,I.UPC ASC, I.SaleDate DESC'
		
		exec (@sqlquery)
                   
		begin try
			DROP TABLE [@tmpShrinkSettlementUPC]
		end try
		begin catch
		end catch
   end
else

   begin
		begin try
				DROP TABLE [@tmpShrinkSettlementByStore]
		end try
		begin catch
		end catch
		set @sqlQuery = 'SELECT I.SupplierId, I.ChainId, I.StoreID, S.StoreIdentifier as StoreNumber, S.Custom1 as Banner, I.SaleDate, I.FinalInvoiceTotalCost,
						SUM(TotalQty) as [UnitCount], sum(I.TotalCost ) AS InvoiceAmount
						
					    into [@tmpShrinkSettlementByStore]
					    
						FROM  dbo.InvoiceDetails AS I
						Inner Join dbo.Stores S on S.StoreId = I.StoreId

						WHERE I.InvoiceDetailTypeID IN (3, 5, 9, 10)
						AND I.InventorySettlementId IS NULL
						AND I.SupplierID = ' + @SupplierId + '
						AND I.ChainID=' + @ChainId 
	 
		if(@BannerId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and S.Custom1=''' + @BannerId + ''''
	       
		if(@StoreNo <>'')
			set @sqlQuery = @sqlQuery +  ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''
	   
		if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
			set @sqlQuery = @sqlQuery + ' and I.SaleDate  <= ''' + @SaleDate  + '''';
		
		set @sqlQuery = @sqlQuery + ' group by I.SupplierId, I.ChainId, I.StoreID, S.StoreIdentifier, S.Custom1, I.SaleDate, I.FinalInvoiceTotalCost '
		set @sqlQuery = @sqlQuery + ' order by S.Custom1, S.StoreIdentifier DESC'
		
		exec (@sqlquery)
		
		set @sqlQuery = 'SELECT  i.StoreID, i.StoreNumber, i.Banner, I.SaleDate, I.FinalInvoiceTotalCost,
						i.UnitCount , 
						(SELECT SUM(UnitCount) FROM [@tmpShrinkSettlementByStore] ID
										 where ID.SaleDate <= I.SaleDate 
										 AND ID.StoreID = I.StoreID
										 AND ID.SupplierID = I.SupplierID
										 AND Id.ChainId=i.ChainID 
						) AS AggregateUnit ,
					    
						i.InvoiceAmount,
						
						(SELECT SUM(InvoiceAmount) FROM [@tmpShrinkSettlementByStore] ID
										 where ID.SaleDate <= I.SaleDate 
										 AND ID.StoreID = I.StoreID
										 AND ID.SupplierID = I.SupplierID
										 AND Id.ChainId=i.ChainID 
						) AS Aggregate
 
						FROM  [@tmpShrinkSettlementByStore] AS I '
						
		if(@ShowAggregate='Y')      
		begin
			set @sqlQuery = @sqlQuery + '	Where (I.SaleDate)=(select max(saledate) from [@tmpShrinkSettlementByStore] ID
					where 	 ID.StoreID = I.StoreID
					AND ID.SupplierID = ' + @SupplierId + '
					AND ID.ChainID=' + @ChainId + ')'
		end				
		
		set @sqlQuery = @sqlQuery + ' order by  i.Banner, i.StoreNumber, I.SaleDate Desc'
		
		exec (@sqlquery)
		
		begin try
			DROP TABLE [@tmpShrinkSettlementByStore]
		end try
		begin catch
		end catch
   end             
   
End
GO
