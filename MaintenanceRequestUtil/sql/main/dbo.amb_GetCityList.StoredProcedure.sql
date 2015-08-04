USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetCityList]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_GetCityList] '-1','-1','BN','42493','-1','2','-1','-1'

CREATE PROCEDURE [dbo].[amb_GetCityList]
	@WholeSalerIdentifier NVARCHAR(100),
	@WholeSalerId NVARCHAR(100),
	@ChainIdentifier NVARCHAR(100),
	@ChainId NVARCHAR(100),
	@StateName NVARCHAR(100),
	@ChainMigrated VARCHAR(1), --0 for Old DB, 1 for  New DB, 2 for Both
	@PublisherIdentifier nvarchar(100),
	@PublisherID nvarchar(100)
AS 
    BEGIN
    DECLARE @strSQLOld VARCHAR(1000)
		DECLARE @strSQLNew VARCHAR(1000)
		Declare @ChainIdNew varchar(50)
		
    SET @strSQLOld = ' SELECT DISTINCT S.City 
											FROM [IC-HQSQL2].iControl.dbo.StoresList S
											INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder B ON B.StoreID=S.StoreID'
		IF(@PublisherIdentifier<>'-1')
					SET @strSQLOld = @strSQLOld + ' INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON P.Bipad = B.Bipad '
		
		SET @strSQLOld = @strSQLOld + ' WHERE S.Active=1'
			
    IF ( @ChainIdentifier <> '-1' ) 
        SET @strSQLOld = @strSQLOld + ' and  S.ChainId=''' + @ChainIdentifier	+ ''''
    
    IF ( @WholeSalerIdentifier <> '-1' ) 
        SET @strSQLOld = @strSQLOld + ' and  B.WholesalerID=''' + @WholeSalerIdentifier	+ ''''

		IF ( @StateName <> '-1' ) 
			SET @strSQLOld = @strSQLOld + ' and  S.State=''' + @StateName + ''''
    
    IF(@PublisherIdentifier<>'-1')
					SET @strSQLOld = @strSQLOld + ' and P.PublisherID=''' + @PublisherIdentifier + ''''
					      
		SET @strSQLNew = ' SELECT DISTINCT City 
						FROM dbo.Addresses A
						INNER JOIN dbo.StoreSetup SS ON SS.StoreID=A.OwnerEntityID'
				
		if(@PublisherID<>'-1')
			SET @strSQLNew = @strSQLNew + ' INNER JOIN dbo.Brands B ON SS.BrandID=B.BrandID
																				INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID '
		
		IF(@WholeSalerId='-1' and @WholeSalerIdentifier<>'-1') --In case of publisher
					SET @strSQLNew = @strSQLNew + ' INNER JOIN dbo.Suppliers Sup ON SS.Supplierid=Sup.Supplierid ' 
					
		SET @strSQLNew = @strSQLNew + ' WHERE ISNULL(A.City,'''') <> '''''
						
		IF ( @ChainId <> '-1' ) 
			SET @strSQLNew = @strSQLNew + ' and  SS.ChainId=' + @ChainId	
    else if (@ChainIdentifier<>'-1')
			begin
				select @ChainIdNew= ChainID from dbo.Chains where ChainIdentifier=@ChainIdentifier;
				SET @strSQLNew = @strSQLNew + ' and  SS.ChainId=' + @ChainIdNew 
			end	
		 
    IF ( @WholeSalerId <> '-1' ) 
        SET @strSQLNew = @strSQLNew + ' and  SS.SupplierId=' + @WholeSalerId
    else IF(@WholeSalerIdentifier<>'-1') --In case of publisher
						SET @strSQLNew = @strSQLNew + ' and Sup.SupplierIdentifier=''' + @WholeSalerIdentifier + ''''
		
		IF(@PublisherID<>'-1')
					SET @strSQLNew = @strSQLNew + ' and M.ManufacturerID=' + @PublisherID 
									    
    IF ( @StateName <> '-1' ) 
        SET @strSQLNew = @strSQLNew + ' and  A.State=''' + @StateName + ''''
        				            
		IF(@ChainMigrated=0)	            				            
			Exec (@strSQLOld)
			
		ELSE IF(@ChainMigrated=1)
			Exec (@strSQLNew)	
		
		ELSE IF(@ChainMigrated=2)
			Exec (@strSQLOld + ' Union ' + @strSQLNew)



    END
GO
