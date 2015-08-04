USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateInventorySaledate]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_UpdateInventorySaledate]
@ChainID VARCHAR(20),
@SupplierID VARCHAR(20),
@StoreID VARCHAR(20),
@Banner VARCHAR(250),
@Qty VARCHAR(20),
@OldSaleDate VARCHAR(20),
@NewSaleDate VARCHAR(20),
@Comments VARCHAR(250)
AS

BEGIN	
	/*** Start Updating SaleDateTime in StoreTransactions Table ***/

	UPDATE ST SET ST.SaleDateTime=@NewSaleDate,
				  ST.Comments=@Comments	
    --SELECT * 
	FROM StoreTransactions ST
		INNER JOIN STORES S ON S.StoreID=ST.StoreID AND S.ChainID=ST.ChainID
	WHERE ST.TransactionTypeID=11
		AND ST.ChainId=@ChainID
		AND ST.SupplierID=@SupplierID
		AND S.StoreID=@StoreID
		AND S.Custom1=@Banner
		AND ST.Qty=@Qty
		AND CAST(ST.SaleDateTime AS DATE) = CAST(@OldSaleDate AS DATE);
	
	/*** End Updating SaleDateTime in StoreTransactions Table ***/	
END
GO
