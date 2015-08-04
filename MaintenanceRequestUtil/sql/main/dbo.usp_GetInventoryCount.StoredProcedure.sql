USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetInventoryCount]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC usp_GetInventoryCount '40393','35205','Cub Foods','-1','01/01/1900'

--EXEC usp_GetInventoryCount '40393','40562','Farm Fresh Markets','-1','01/01/1900'
CREATE PROC [dbo].[usp_GetInventoryCount]
@ChainID AS VARCHAR(20),
@SupplierID AS VARCHAR(20),
@Banner AS VARCHAR(100),
@StoreID AS VARCHAR(20),
@SaleDate AS VARCHAR(20)
AS
BEGIN
	DECLARE @strQuery VARCHAR(4000)
	
	SET @strQuery = 'SELECT DISTINCT C.ChainName,SUP.SupplierName,S.Custom1 AS Banner,S.StoreName,S.StoreIdentifier AS StoreNumber, Convert(VARCHAR(20), ST.SaleDateTime,101) AS SaleDate ,Qty,C.ChainId,SUP.SupplierId,S.StoreID
					
					FROM Chains C
						INNER JOIN StoreTransactions ST ON C.ChainID= ST.ChainID
						INNER JOIN Suppliers SUP ON SUP.SupplierID=ST.SupplierID
						INNER JOIN Stores S ON S.StoreID=ST.StoreID AND S.ChainID= C.ChainID
						INNER JOIN StoreSetup SS ON SS.StoreID = S.StoreID AND SS.ChainID =C.ChainID AND SS.SupplierID=SUP.SupplierID AND SS.ProductID=ST.ProductID 
						INNER JOIN (
										SELECT RetailerID,SupplierID,StoreID,max(PhysicalInventoryDate ) AS CountDate
										FROM InventorySettlementRequests where 1=1 '
										IF(@ChainID <> '-1')
												SET @strQuery +=' AND RetailerID = ' + @ChainID

											IF(@SupplierID <> '-1')
												SET @strQuery +=' AND SupplierID = ' + @SupplierID
											
											IF(@StoreID <> '-1')
												SET @strQuery +=' AND StoreID = ' + @StoreID
												
									SET @strQuery +='	GROUP BY RetailerID,SupplierID,StoreID
									) AS A ON A.retailerId=ST.ChainID AND A.supplierId=ST.SupplierID AND A.StoreID=ST.StoreID AND CAST( ST.SaleDateTime AS Date) > CAST( CountDate AS Date)
					WHERE 1=1 AND TransactionTypeID=11 '
					
	IF(@ChainID <> '-1')
		SET @strQuery +=' AND C.ChainID = ' + @ChainID

	IF(@SupplierID <> '-1')
		SET @strQuery +=' AND SUP.SupplierID = ' + @SupplierID
	
	IF(@Banner <> '-1' AND @Banner <> 'All')
		SET @strQuery +=' AND S.Custom1 = ''' + @Banner + ''''
	
	IF(@StoreID <> '-1')
		SET @strQuery +=' AND S.StoreID = ' + @StoreID
		
	IF(@SaleDate <> '' AND CAST(@SaleDate  AS DATE) <> CAST('01/01/1900' AS DATE))
		SET @strQuery +=' AND SaleDatetime = ''' + @SaleDate + ''''					
	
	EXEC(@strQuery)
	
END
GO
