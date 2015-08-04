USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ManageExceptions]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_ManageExceptions '-1','-1','','','-1','-1','10/24/2012','10/26/2012','1'
CREATE procedure [dbo].[amb_ManageExceptions]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(20),
 @UPC varchar(20),
 @ExceptionType varchar(20),
 @TransactionType varchar(50),
 @StartDate varchar(50),
 @EndDate  varchar(50),
 @SettlementStatus VARCHAR(20) 

as

Begin
 Declare @sqlQuery varchar(5000)
	
		SET @sqlQuery = ' SELECT distinct SE.StoreTransactionId, min(SE.StoreTransactionExceptionID) as StoreTransactionExceptionID, S.SupplierIdentifier,
								C.ChainIdentifier, ss.LegacySystemStoreIdentifier, P.ProductName, SE.UPC,
								convert(datetime, SE.SaleDateTime, 101) as SaleDateTime, T.TransactionTypeName, 
								SE.Qty,SE.SetupCost,SE.ReportedCost,SE.SetupRetail,SE.ReportedRetail,
								SE.ExpectedSupplierIdentifier, SE.ReportedSupplierIdentifier, STT.ExceptionTypeName
							FROM StoreTransactions_Exceptions SE
								INNER JOIN StoreTransactions_Exception_Types STT on STT.StoreTransactionExceptionTypeID=SE.StoreTransactionExceptionTypeID
								INNER JOIN Suppliers S ON S.SupplierID=SE.SupplierID
								INNER JOIN Chains C ON C.ChainID=SE.ChainID
								INNER JOIN Stores ss ON ss.StoreID=SE.StoreID
								INNER JOIN Products P ON P.ProductId=SE.ProductId
								Inner Join TransactionTypes T on T.TransactionTypeId=SE.TransactionTypeId
							where 1=1 '
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and SE.SaleDateTime  >= ''' + @StartDate  + ''''
                
		if (convert(date, @EndDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and SE.SaleDateTime  <= ''' + @EndDate  + ''''
			
		if(@SupplierId <>'-1')
			set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier= ''' + @SupplierId + ''''
			
		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery + ' and C.Chainidentifier= ''' + @ChainId +''''    
		      	               
		if(@StoreNumber <>'')
		   set @sqlQuery = @sqlQuery + ' and ss.LegacySystemStoreIdentifier like ''%' + @StoreNumber +'%'''
		   
		if(@UPC <>'')
		   set @sqlQuery = @sqlQuery + ' and SE.UPC like ''%' + @UPC +'%'''
		   
		if(@ExceptionType <>'-1')
		   set @sqlQuery = @sqlQuery + ' and  STT.StoreTransactionExceptionTypeID= ''' + @ExceptionType +''''
		
		if(@TransactionType <>'-1')
		   set @sqlQuery = @sqlQuery + ' and  SE.TransactionTypeId in (' + @TransactionType + ')'
		   		   
		set @sqlQuery = @sqlQuery + ' group by SE.StoreTransactionId, S.SupplierIdentifier , C.ChainIdentifier ,ss.LegacySystemStoreIdentifier, P.ProductName,
							convert(datetime, SE.SaleDateTime, 101), T.TransactionTypeName, SE.Qty,SE.SetupCost,SE.SetupRetail,SE.ReportedRetail,SE.ReportedCost,SE.ExpectedSupplierIdentifier,
							SE.ReportedSupplierIdentifier,SE.UPC,STT.ExceptionTypeName 
							having sum(ExceptionStatus)=' + @SettlementStatus + '
							order by StoreTransactionExceptionID, convert(datetime, SE.SaleDateTime, 101)'

		exec(@sqlQuery);
				
End
GO
