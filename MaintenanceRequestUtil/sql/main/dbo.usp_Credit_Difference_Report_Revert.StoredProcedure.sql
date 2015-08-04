USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Credit_Difference_Report_Revert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Credit_Difference_Report_Revert] 
 
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Banner varchar(50),
 @StoreNumber varchar(20),
 @UPC varchar(20),
 @SaleFromDate varchar(50),
 @SaleToDate varchar(50),
 @Status varchar(20)
as
--exec usp_Credit_Difference_Report_Revert '40557',40393,'-1','','','1900-01-01','1900-01-01',null
Begin
	 Declare @sqlQuery varchar(4000)
	 set @sqlQuery = 'Select S.RecordID,S.RetailerId, C.ChainName as [Retailer Name], S.SupplierId, 
					SP.SupplierName as [Supplier Name], S.Banner, S.StoreNumber as [Store Number],
					convert(varchar(10),S.SaleDate,101) as [Sale Date], S.UPC, S.ProductName as [Product Name], S.SourceName as [Source Name], 
					S.QuantityRetailer as [Quantity Retailer], s.QuantitySupplier as [Quantity Supplier], 
					S.CostRetailer as [Cost Retailer],  S.CostSupplier as [Cost Supplier],
					S.DifferenceUnits as [Difference Units], 
					S.DifferenceCost as [Difference Cost],
					case when S.RevertStatus is NULL then ''Pending'' 
							 when  S.RevertStatus =0 then ''Reverse Suppliers Credit'' 
							 when  S.RevertStatus =1 then ''Reverse Retailer Credit'' 
							 when  S.RevertStatus =2 then ''Posted for Reversal'' 
					end as [Revert Status]
					from Credit_Difference_Report S
					Inner Join Chains C on C.ChainID=S.RetailerID
					Inner Join Suppliers SP on SP.SupplierID=S.SupplierId
					 '
	
	if(@ChainId<>'-1' and @ChainId <> '')
		set @sqlQuery = @sqlQuery + ' and C.ChainID=' + @ChainId

	if(@SupplierId<>'-1' and @SupplierId <> '')
		set @sqlQuery = @sqlQuery + ' and SP.SupplierId=' + @SupplierId

	if(@Banner<>'-1' and @Banner <> '')
	    set @sqlQuery = @sqlQuery + ' and S.Banner=''' + @Banner + ''''
	
	if(@StoreNumber<>'')
		set @sqlQuery = @sqlQuery + ' and S.StoreNumber=''' + @StoreNumber + ''''
		
	if(@UPC<>'')
	    set @sqlQuery = @sqlQuery + ' and S.UPC=''' + @UPC + ''''

	if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDate >= ''' + @SaleFromDate + '''';

	if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDate <= ''' + @SaleToDate + '''';
	
	if(@Status<>'')
		set @sqlQuery = @sqlQuery + ' and S.RevertStatus ='''+ @Status + '''';
	Else
		set @sqlQuery = @sqlQuery + ' and S.RevertStatus is NULL'
		
  print  @sqlQuery
	exec(@sqlQuery); 

End
GO
