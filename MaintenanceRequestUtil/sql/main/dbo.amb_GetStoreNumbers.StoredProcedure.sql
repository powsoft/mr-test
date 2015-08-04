USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetStoreNumbers]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_GetStoreNumbers 'WR1832','CA','ANTELOPE VALLEY PRESS','SV'
CREATE PROCEDURE [dbo].[amb_GetStoreNumbers]
    (
      @WholesalerId VARCHAR(20) ,
      @State VARCHAR(30) ,
      @Title VARCHAR(20),
      @ChainId VARCHAR(20)
    )
AS 
BEGIN

DECLARE @sqlQuery VARCHAR(4000)
DECLARE @chain_migrated VARCHAR(20)

SELECT  @chain_migrated = chainid
FROM    dbo.chains_migration
WHERE   chainid = @ChainID;

IF ( @chain_migrated IS NULL ) 
    BEGIN
        SET @sqlQuery = ' SELECT 
                             SL.StoreNumber
						 FROM 
						  ( [IC-HQSQL2].iControl.dbo.BaseOrder   BO 
						   INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL   
							     ON (BO.StoreID = SL.StoreID) 
							     AND (BO.ChainID = SL.ChainID)) 
						  INNER JOIN [IC-HQSQL2].iControl.dbo.Products P
							     ON BO.Bipad = P.Bipad ' 

        SET @sqlQuery = @sqlQuery + ' WHERE (((SL.State)='''+ @State + ''') 
										AND ((BO.WholesalerID)='''+ @WholesalerId+ ''') 
										AND ((BO.Stopped)=0)  
										AND ((SL.Active)=1) 
										AND ((P.AbbrvName) = ''' + @Title + '''))  '

        SET @sqlQuery = @sqlQuery + 'GROUP BY SL.StoreNumber '
        print @sqlQuery
        EXEC(@sqlQuery);
    END
ELSE 
    BEGIN
		SET @sqlQuery = ' SELECT  
							S.StoreIdentifier AS StoreNumber 
							
						FROM 
							dbo.StoreSetup SS 
								INNER JOIN dbo.Stores S 
									ON S.StoreID=SS.StoreID AND S.ChainID=SS.ChainID
								INNER JOIN dbo.Products P 
									ON P.ProductID=SS.ProductID
								INNER JOIN dbo.Suppliers SUP 
									ON SUP.SupplierID=SS.SupplierID
								INNER JOIN dbo.Addresses A 
									ON A.OwnerEntityID=SS.SupplierID '
							
			SET @sqlQuery = @sqlQuery + ' WHERE (((A.State)='''+ @State + ''') 
												AND ((SUP.SupplierIdentifier)='''+ @WholesalerId+ ''') 
												AND ((P.ProductName) = '''+ @Title + '''))'
			SET @sqlQuery = @sqlQuery + 'GROUP BY S.StoreIdentifier '
	print @sqlQuery
			EXEC(@sqlQuery);
    END
END
GO
