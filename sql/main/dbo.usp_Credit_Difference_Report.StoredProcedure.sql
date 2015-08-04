USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Credit_Difference_Report]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Credit_Difference_Report] 
 
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Banner varchar(50),
 @StoreNumber varchar(20),
 @UPC varchar(20),
 @SaleFromDate varchar(50),
 @SaleToDate varchar(50)
as
--exec usp_Credit_Difference_Report 42255,40393,-1,'','','1900-01-01','1900-01-01'
Begin
	 Declare @sqlQuery varchar(4000)
	 set @sqlQuery = 'Select C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name], 
					ST.Custom1 as Banner, ST.StoreIdentifier as [Store Number],
					convert(varchar(10),S.SaleDateTime,101) as SaleDate, S.UPC, P.ProductName, SC.SourceName, 
					S.Qty as [Quantity Retailer], isnull(S1.[Supplier Qty],0) as [Quantity Supplier], 
					S.ReportedCost as [Cost Retailer], isnull(S1.ReportedCost,0) as [Cost Supplier],
					(isnull(S1.[Supplier Qty],0) - S.Qty) as [Difference Units], 
					(isnull(S1.ReportedCost,0) - S.ReportedCost) as [Difference Cost]
					from StoreTransactions S
					Inner Join Chains C on C.ChainID=S.ChainId
					Inner Join Suppliers SP on SP.SupplierID=S.SupplierId
					Inner Join Stores ST on ST.StoreId=S.StoreId
					Inner join Products P on P.ProductId=S.ProductId
					Inner join Source SC on SC.SourceID=S.SourceId
					Left Join (select S1.SupplierId, S1.ChainId, S1.StoreId, S1.ProductId, S1.SaleDateTime, 
								sum(S1.Qty) as [Supplier Qty], S1.ReportedCost
								from StoreTransactions S1 
								inner join TransactionTypes T on T.TransactionTypeId=S1.TransactionTypeId 
								where T.TransactionTypeId in (8,9,15,20,21,37)
								group by S1.SupplierId, S1.ChainId, S1.StoreId, S1.ProductId, S1.SaleDateTime, S1.ReportedCost
							   ) as S1 on S1.SupplierId=S.SupplierId and S1.ChainId=S.ChainId and S1.StoreId=S.StoreId 
							   and S1.ProductId=S.ProductId and S1.SaleDateTime=S.SaleDateTime
					where S.TransactionTypeID = 36 '
	
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and C.ChainID=' + @ChainId

	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and SP.SupplierId=' + @SupplierId

	if(@Banner<>'-1')
	    set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @Banner + ''''
	
	if(@StoreNumber<>'')
		set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier=''' + @StoreNumber + ''''
		
	if(@UPC<>'')
	    set @sqlQuery = @sqlQuery + ' and S.UPC=''' + @UPC + ''''

	if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime >= ''' + @SaleFromDate + '''';

	else if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime <= ''' + @SaleToDate + '''';
  
  print @sqlQuery;
	exec(@sqlQuery); 

End
GO
