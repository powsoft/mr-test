USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_StoreList]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_StoreList '40393','-1','-1'
CREATE PROC [dbo].[usp_StoreList]
@ChainID VARCHAR(20),
@SupplierID VARCHAR(20),
@Banner VARCHAR(150)
AS
BEGIN
	DECLARE @Query VARCHAR(1000)
	
	SET @Query ='SELECT DISTINCT StoreIdentifier AS StoreNumber,S.StoreID,S.Custom1,S.Custom2 
				FROM Stores  S
					INNER JOIN StoreSetup SS ON S.StoreId=SS.StoreID and S.ChainID=SS.ChainID
				WHERE 1=1 '
				
	IF(@ChainID <> '-1')
		SET @Query += ' AND S.Chainid='+@ChainID
			
	IF(@SupplierID <> '-1')
		SET @Query += ' AND SS.SupplierID='+@SupplierID

	IF(@Banner <> '-1')
		SET @Query += ' AND S.Custom1='''+@Banner +''''

	SET @Query += ' ORDER BY StoreNumber '
	
	EXEC(@Query)
END
GO
