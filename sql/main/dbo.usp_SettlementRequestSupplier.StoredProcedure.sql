USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SettlementRequestSupplier]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_SettlementRequestSupplier]
	@AttributeValue varchar(10),
	@ChainId varchar(6),
	@BannerId varchar(6),
	@StoreId varchar(6),
	@SaleDate varchar(50)
as

Begin
 Declare @sqlQuery varchar(4000)
 	set @sqlQuery = 'SELECT     PhysicalInventoryDate, InvoiceAmount, Settle, StoreNumber, StoreID AS Expr1, RequestingPersonID, UnsettledShrink, RequestDate, ApprovingPersonID, 
                      ApprovedDate, DenialReason, supplierId
FROM         dbo.InventorySettlementRequests
WHERE     supplierId = ''' + @AttributeValue + ''''
					  
					 if(@ChainId <>'-1') 
						set @sqlQuery = @sqlQuery +  ' and S.ChainID=' + @ChainId 
						
					 if(@BannerId<>'-1') 
						set @sqlQuery = @sqlQuery +  ' and S.Custom3=''' + @BannerId + ''''
						
					 if(@StoreId <>'-1') 
						set @sqlQuery = @sqlQuery +  ' and S.StoreId=' + @StoreId 
					
					 if (convert(date, @SaleDate) > convert(date,'1900-01-01'))
						set @sqlQuery = @sqlQuery + ' and I.SaleDate  <= ''' + @SaleDate  + '''';

				 set @sqlQuery = @sqlQuery + ' ORDER BY I.StoreID, SaleDate DESC '
				 exec (@sqlquery)

End
GO
