USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetChainsList_All]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_GetChainsList_All]
	@PersonId varchar(50)
 --,@AccessLevel varchar(20)
 --,@AccessValue varchar(20)
 --,@BannerName varchar(20)
as
--exec usp_GetChainsList_All 40384
Begin

	Declare @sqlQuery varchar(4000)
	Declare @AccessLevel varchar(20)
	Declare @AccessValue varchar(20)
	
	select @AccessLevel=AttributeName 
				,@AccessValue=AttributeValue
	from AttributeDefinitions d
		inner join AttributeValues v on d.AttributeID = v.AttributeID
	where OwnerEntityID = @PersonId
				and v.IsActive = 1 
				and d.AttributeID IN(9,17,23)
				
	Print( @AccessLevel)
	
	set @sqlQuery = ' select distinct C.ChainID
									, ChainName '

	if(@AccessLevel ='ChainAccess') 		
		Begin	
			Print(@AccessLevel)
			Set @sqlQuery = @sqlQuery+ ' from Chains C 
													inner join StoreSetup SS on SS.ChainID=C.ChainID  
												 where 1=1  '							
			Set @sqlQuery = @sqlQuery+'AND SS.ChainID='+@AccessValue
		End
	else if(@AccessLevel ='SupplierAccess') 	
		Begin
			Print(@AccessLevel)
			Set @sqlQuery = @sqlQuery+ ' from Chains C 
													inner join StoreSetup SS on SS.ChainID=C.ChainID  
													inner JOIN Suppliers S ON SS.SupplierID=S.SupplierID
												 where 1=1  '							
			Set @sqlQuery = @sqlQuery+ 'AND SS.SupplierID='+@AccessValue
		End
	else if(@AccessLevel ='ManufacturerAccess') 			
		Begin		
			Print(@AccessLevel)			
			Set @sqlQuery = @sqlQuery+' from Chains C
														inner join StoreSetup SS on SS.ChainID=c.ChainID
														inner JOIN Brands B ON B.BrandID=SS.BrandID
														inner JOIN Manufacturers M ON M.ManufacturerID=B.ManufacturerID
												 where 1=1  '							
			Set @sqlQuery = @sqlQuery+ 'AND M.ManufacturerID='+@AccessValue
		End

	Set @sqlQuery = @sqlQuery+ ' union ' 

	Set @sqlQuery = @sqlQuery+ 'select distinct C.ChainID
										, ChainName 
										from Chains C 
											inner join RetailerAccess RA on RA.ChainID=C.ChainID  
										where 1=1 '

	if(@PersonId <> '-1' and @PersonId <> '') 
	Set @sqlQuery = @sqlQuery+ ' and RA.PersonId= ''' + @PersonId + ''''	

	Set @sqlQuery = @sqlQuery+ ' order by C.ChainId, C.ChainName '


	print(@sqlQuery)
	exec(@sqlQuery); 

End
GO
