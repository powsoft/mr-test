USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewWholesalerRegistryCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.chains where chainidentifier='BN'
--exec amb_ViewWholesalerRegistryCHN 'AK','BN',42493,1
CREATE PROCEDURE [dbo].[amb_ViewWholesalerRegistryCHN]
    (
      @State VARCHAR(30) ,
      @ChainIdentifier VARCHAR(20),
      @ChainID VARCHAR(20),
      @Dbtype INT   -- 0 for old,1 for new,2 for both
    )
AS 
  BEGIN

		
		DECLARE @sqlQueryNew VARCHAR(4000)

		SET @sqlQueryNew = ' SELECT distinct A.State,SUP.SupplierIdentifier AS WhlsID,
				SUP.SupplierName AS WholesalerName,CI.FirstName+ '' '' +CI.LastName as Contact, 
				CI.Email as Email,CI.DeskPhone as Tel
				FROM DataTrue_Report.dbo.StoreSetup SS
				INNER JOIN DataTrue_Report.dbo.Suppliers SUP ON SUP.SupplierID=SS.SupplierID
				INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=SS.SupplierID
				INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID=SS.ChainID
				INNER JOIN DataTrue_Report.dbo.ContactInfo CI on CI.OwnerEntityId=sup.SupplierID  '
					
				SET @sqlQueryNew = @sqlQueryNew + ' Where SS.Chainid=''' + @ChainID + '''
									AND SUP.SupplierName<>''1''
									And Sup.SupplierName Not IN(''test'',''fee'')'
				IF ( @State <> '-1' ) 
						SET @sqlQueryNew = @sqlQueryNew + ' AND A.State = '''+ @State + ''''
		
				SET @sqlQueryNew = @sqlQueryNew + ' ORDER BY A.State,SUP.SupplierIdentifier ';
				
				EXEC(@sqlQueryNew);
			
  END
GO
