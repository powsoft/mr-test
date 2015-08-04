USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AuthorizedProducts]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[usp_AuthorizedProducts] 64010, -1,'Lehigh Gas','-1',2,'',1,'',1,'', 'SupplierName ASC',1,25,0
--usp_AuthorizedProducts '60624','-1','-1','-1',2,'',1,'','1','','Like','','','[Supplier Name] ASC',1,25,0

CREATE procedure [dbo].[usp_AuthorizedProducts]
 @ChainId varchar(5),
 @supplierID varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @ProductIdentifierType int,
 @ProductIdentifierContains varchar(20),
 @ProductIdentifierValue varchar(250),
 @StoreIdentifierType int,
 @StoreIdentifierContains varchar(20),
 @StoreIdentifierValue varchar(250),
 @OtherOption int,
 @OthersContains varchar(20),
 @Others varchar(50),
 @SupplierIdentifierValue varchar(50),
 @RetailerIdentifierValue varchar(50),
 @Category varchar(20),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int
 
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 SET @sqlQuery = 'SELECT [Retailer Name]
					  , [Supplier Name]
					  , [Store Number]
					  , Banner
					  , Brand
					  , Product
					  , UPC
					  , [Vendor Item Number]
					  , [Supplier Acct Number]
					  , [Driver Name]
					  , [Route Number]
					  , [Alternative Store #] 
					  , Bipad
					  , SupplierIdentifier as [Wholesaler ID #]
                
                  FROM  DataTrue_CustomResultSets.dbo.[tmpAuthorizedProductsList] 
                  WHERE 1=1  and ProductId>0' 
                
		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and ChainID=' + @ChainID

		if(@supplierID<>'-1')
			set @sqlQuery = @sqlQuery +  ' and supplierID=' + @supplierID

		if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

		if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''

		if(@custom1='')
			set @sqlQuery = @sqlQuery + ' and Banner is Null'

		else if(@custom1<>'-1')
			set @sqlQuery = @sqlQuery + ' and Banner=''' + @custom1 + ''''

		if(@BrandId<>'-1')
			set @sqlQuery = @sqlQuery + ' and BrandId= ' + @BrandId
 
IF(@ProductIdentifierValue<>'')
	BEGIN-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
		IF(@ProductIdentifierContains <> '')
			BEGIN
				IF(@ProductIdentifierContains = 'LIKE')
					BEGIN
						if (@ProductIdentifierType=2)
							set @sqlQuery = @sqlQuery + ' and UPC ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						else if (@ProductIdentifierType=3)
							set @sqlQuery = @sqlQuery + ' and Product ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						else if (@ProductIdentifierType=7)
							set @sqlQuery = @sqlQuery + ' and [Vendor Item Number] ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						else if (@ProductIdentifierType=8)
							set @sqlQuery = @sqlQuery + ' and Bipad ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
					END
				ELSE
					BEGIN
						if (@ProductIdentifierType=2)
							set @sqlQuery = @sqlQuery + ' and UPC ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						else if (@ProductIdentifierType=3)
							set @sqlQuery = @sqlQuery + ' and Product ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						else if (@ProductIdentifierType=7)
							set @sqlQuery = @sqlQuery + ' and [Vendor Item Number] ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						else if (@ProductIdentifierType=8)
							set @sqlQuery = @sqlQuery + ' and Bipad ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
					END
			END
	END

	IF(@StoreIdentifierValue<>'')
		BEGIN
		--1 = Store Number, 2 = SBT Number, 3 = Store Name
			IF (@StoreIdentifierType=1)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' and [Store Number] '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE 
						SET @sqlQuery = @sqlQuery + ' and [Store Number] '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
			ELSE IF (@StoreIdentifierType=2)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' and Custom2 '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE
						SET @sqlQuery = @sqlQuery + ' and Custom2 '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
			ELSE IF (@StoreIdentifierType=3)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' and StoreName '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE
						SET @sqlQuery = @sqlQuery + ' and StoreName '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
		END
	
 IF(@Others<>'')
    BEGIN
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
		IF(@OthersContains <> '')
			BEGIN
				IF(@OthersContains = 'LIKE')
					BEGIN
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and WarehouseName ' + @OthersContains +' ''%' + @Others + '%'''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and RegionalMgr ' + @OthersContains +' ''%' + @Others + '%'''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and SalesRep ' + @OthersContains +' ''%' + @Others + '%'''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and [Supplier Acct Number] ' + @OthersContains +' ''%' + @Others + '%'''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and [Driver Name] ' + @OthersContains +' ''%' + @Others + '%'''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and [Route Number] ' + @OthersContains +' ''%' + @Others + '%'''
					END
				ELSE
					BEGIN
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and WarehouseName ' + @OthersContains + ' ''' + @Others + ''''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and RegionalMgr ' + @OthersContains + ' ''' + @Others + ''''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and SalesRep ' + @OthersContains + ' ''' + @Others + ''''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and [Supplier Acct Number] ' + @OthersContains + ' ''' + @Others + ''''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and [Driver Name] ' + @OthersContains + ' ''' + @Others + ''''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and [Route Number] ' + @OthersContains + ' ''' + @Others + ''''
					END
			END  
    END
    
		if(@Category='1')
			set @sqlQuery = @sqlQuery +  ' and ProductIdentifierTypeId=8'
		else if(@Category='2')
			set @sqlQuery = @sqlQuery +  ' and ProductIdentifierTypeId<>8'	

 
  SET @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
  print(@sqlQuery)
  exec (@sqlQuery)
 
End
GO
