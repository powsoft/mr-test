USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetTitleList]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_GetTitleList] '-1','-1','BN','42493','MD','-1','',1,'DOWJ','35321'
--exec [amb_GetTitleList] 'CLL','24164','BN','-1','-1','-1','','0','-1','-1'
CREATE PROCEDURE [dbo].[amb_GetTitleList]
    @WholeSalerIdentifier NVARCHAR(100) ,
    @WholeSalerId NVARCHAR(100) ,
    @ChainIdentifier NVARCHAR(100) ,
    @ChainId NVARCHAR(100) ,
    @StateName NVARCHAR(100) ,
    @CityName NVARCHAR(100) ,
    @StoreIdentifier NVARCHAR(100) ,
    @ChainMigrated VARCHAR(2),--0 for Old DB, 1 for New, 2 for Both
    @PublisherIdentifier NVARCHAR(100) ,
    @PublisherId NVARCHAR(100) 
AS 
    BEGIN
        DECLARE @strSQLOld VARCHAR(4000)
        DECLARE @strSQLNew VARCHAR(4000)
        DECLARE @strSQLFinal VARCHAR(8000)
		DECLARE @ChainIdNew varchar(50)
		
        SET @strSQLOld = 'SELECT distinct P.TitleName AS Title 
						FROM [IC-HQSQL2].iControl.dbo.Products P
						INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder B ON B.Bipad=P.Bipad
						INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList S ON S.StoreID=B.StoreID'

				SET @strSQLOld = @strSQLOld + '	WHERE P.Active=1'
					
        IF(@PublisherIdentifier<>'-1')
					SET @strSQLOld = @strSQLOld + ' and P.PublisherID=''' + @PublisherIdentifier + ''''
					
        IF ( @ChainIdentifier <> '-1' ) 
            SET @strSQLOld = @strSQLOld + ' and  B.ChainId=''' + @ChainIdentifier + ''''
        
        IF ( @WholeSalerIdentifier <> '-1' ) 
            SET @strSQLOld = @strSQLOld + ' and  B.WholesalerID=''' + @WholeSalerIdentifier + ''''
		
        IF ( @StateName <> '-1' ) 
            SET @strSQLOld = @strSQLOld + ' and  S.State=''' + @StateName + ''''
            
        IF ( @CityName <> '-1' ) 
            SET @strSQLOld = @strSQLOld + ' and  S.City=''' + @CityName + ''''
        
        IF ( @StoreIdentifier <> '' ) 
            SET @strSQLOld = @strSQLOld + ' and  S.StoreId=''%' + @StoreIdentifier + '%'''
           
            
        SET @strSQLNew = ' SELECT DISTINCT P.ProductName AS Title
							FROM dbo.Products P
							INNER JOIN dbo.ProductIdentifiers PI ON pi.ProductID=p.ProductID
							INNER JOIN  dbo.StoreSetup SS ON SS.ProductID=P.ProductID
							INNER JOIN  dbo.Addresses A ON A.OwnerEntityID=SS.StoreID
							inner join  dbo.Stores S ON S.StoreId=SS.StoreID '
				if(@PublisherID<>'-1')
					SET @strSQLNew = @strSQLNew + ' INNER JOIN dbo.Brands B ON SS.BrandID=B.BrandID
													INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID '
		
				IF(@WholeSalerId='-1' and @WholeSalerIdentifier<>'-1') --In case of publisher
					SET @strSQLNew = @strSQLNew + ' INNER JOIN dbo.Suppliers Sup ON SS.Supplierid=Sup.Supplierid ' 
				
				SET @strSQLNew = @strSQLNew + ' WHERE P.ActiveLastDate>=GETDATE() and ISNULL(Bipad,'''')<>'''''						
        
        IF ( @ChainId <> '-1' ) 
					Begin 
							SET @strSQLNew = @strSQLNew + ' and  SS.ChainId=' + @ChainId	
					END
        else IF ( @ChainIdentifier <> '-1' )
					Begin 
						select @ChainIdNew=ChainID from dbo.Chains where ChainIdentifier=@ChainIdentifier;
					SET @strSQLNew = @strSQLNew + ' and  SS.ChainId=' + @ChainIdNew
				ENd
        
        IF ( @WholeSalerId <> '-1' ) 
            SET @strSQLNew = @strSQLNew + ' and  SS.SupplierId=' + @WholeSalerId
        Else IF(@WholeSalerIdentifier<>'-1') --In case of publisher
						SET @strSQLNew = @strSQLNew + ' and Sup.SupplierIdentifier=''' + @WholeSalerIdentifier + ''''
						    
        IF ( @StateName <> '-1' ) 
            SET @strSQLNew = @strSQLNew + ' and  A.State=''' + @StateName + ''''

				IF ( @CityName <> '-1' ) 
            SET @strSQLNew = @strSQLNew + ' and  A.City=''' + @CityName + ''''
        
        IF ( @StoreIdentifier <> '' ) 
            SET @strSQLNew = @strSQLNew + ' and  S.LegacySystemStoreIdentifier=''%' + @StoreIdentifier + '%'''
              
                          				            
        IF ( @ChainMigrated = 0 ) 
           SET @strSQLFinal=@strSQLOld
		
	    ELSE IF ( @ChainMigrated = 1 ) 
            SET @strSQLFinal=@strSQLNew
            
        ELSE IF ( @ChainMigrated = 2 ) 
            SET @strSQLFinal=@strSQLOld + ' Union ' + @strSQLNew	
         
        SET @strSQLFinal=@strSQLFinal+' order by 1'
      
      print @strSQLFinal
      EXEC(@strSQLFinal)
    END
GO
