USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewWholesalerByStoreCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_ViewWholesalerByStoreCHN] 'BN','','','','','','0'
CREATE PROCEDURE [dbo].[amb_ViewWholesalerByStoreCHN]
    (
      @ChainID VARCHAR(20) ,
      @StoreNumber VARCHAR(30),
      @WholeSalerName VARCHAR(30),
      @City VARCHAR(30),
      @State  VARCHAR(30),
      @Zipcode  VARCHAR(30),
      @Dbtype INT   -- 0 for old,1 for new,2 for both
    )
AS 
BEGIN
	
	DECLARE @sqlQueryNew VARCHAR(4000)
	SET @sqlQueryNew = 'SELECT distinct S.LegacySystemStoreIdentifier as StoreId,
				S.StoreName,SUP.SupplierIdentifier AS WholesalerID, SUP.SupplierName AS WholesalerName,
				A.Address1 AS ADDRESS, A.City, A.State, A.PostalCode  AS ZipCode,
				CI.FirstName+ '' '' + CI.LastName as Contact, CI.Email as Email, CI.DeskPhone as Tel					
				FROM DataTrue_Report.dbo.Stores S
				Inner join DataTrue_Report.dbo.Chains C ON C.ChainID=S.ChainId
				INNER JOIN DataTrue_Report.dbo.StoreSetup SS ON S.StoreID=SS.StoreID
				INNER JOIN DataTrue_Report.dbo.Suppliers SUP ON SUP.SupplierID=SS.SupplierID
				INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=SS.SupplierID 
				INNER JOIN DataTrue_Report.dbo.ContactInfo CI on CI.OwnerEntityId=sup.SupplierID  
				Where 1 = 1 and C.ChainIdentifier=''' + @ChainID + ''''

			if(@StoreNumber<>'')
				SET @sqlQueryNew = @sqlQueryNew +' and S.LegacySystemStoreIdentifier LIke''%'+@StoreNumber +'%'''
			
			if(@WholeSalerName<>'')
				SET @sqlQueryNew = @sqlQueryNew +' and Sup.SupplierName  LIke''%'+@WholeSalerName +'%'''
			
			if(@City<>'')
				SET @sqlQueryNew = @sqlQueryNew +'and A.City LIke ''%'+@City+'%'''
			
			if(@State<>'')
				SET @sqlQueryNew = @sqlQueryNew +'and A.State LIke ''%'+@State+'%'''
			
			if(@Zipcode<>'')
				SET @sqlQueryNew = @sqlQueryNew +' and A.PostalCode LIke ''%'+@Zipcode+'%'''

			SET @sqlQueryNew = @sqlQueryNew + ' ORDER  BY S.LegacySystemStoreIdentifier,SUP.SupplierIdentifier, SUP.SupplierName'
			
			EXEC(@sqlQueryNew); 
 
END
GO
